#!/bin/sh
set -euo pipefail

export VAULT_ADDR="unix:///vault/vault.sock"
AGENT_CERT_DIR="/certs/agent"
VAULT_CERT_DIR="/certs/vault"
KEYS_FILE="/vault/data/keys"
ROOT_TOKEN_FILE="/vault/data/root_token"

echo "Checking if Vault is already initialized..."
if [ -f /vault/data/.initialized ]; then
    echo "Vault already initialized, exiting"
    exit 0
fi

init_vault() {
    echo "Initializing Vault..."
    vault operator init -key-shares=1 -key-threshold=1 > "$KEYS_FILE"
    
    ROOT_TOKEN=$(grep 'Initial Root Token:' "$KEYS_FILE" | awk '{print $NF}')
    echo "Root token extracted: $ROOT_TOKEN"
    echo "$ROOT_TOKEN" > "$ROOT_TOKEN_FILE"
    export VAULT_TOKEN="$ROOT_TOKEN"
    echo "✅ Vault initialized"
}

unseal_vault() {
    echo "Unsealing Vault..."
    UNSEAL_KEY=$(grep 'Unseal Key 1:' "$KEYS_FILE" | awk '{print $NF}')
    vault operator unseal "$UNSEAL_KEY"
    echo "✅ Vault unsealed"
}

wait_for_vault() {
    local socket="/vault/vault.sock"
    local max_attempts=30
    local attempt=0
    
    echo "Waiting for Vault socket..."
    while [ ! -S "$socket" ] && [ $attempt -lt $max_attempts ]; do
        attempt=$((attempt + 1))
        echo "Socket check $attempt/$max_attempts"
        sleep 2
    done
    
    if [ ! -S "$socket" ]; then
        echo "❌ Vault socket not found after $max_attempts attempts"
        exit 1
    fi
    echo "✅ Vault socket found"
}


# Main execution
echo "🔐 Setting up Vault PKI with proper hierarchy..."
wait_for_vault
init_vault
unseal_vault

if [ -f /vault/data/.initialized ]; then
    echo "Vault already initialized, exiting"
    exit 0
fi

vault audit enable file file_path=/vault/logs/audit.log
# ============================================
# STEP 1: ROOT CA
# ============================================
echo ""
echo "📋 Step 1: Creating Root CA..."

vault secrets enable -path=pki_root pki 2>/dev/null || echo "pki_root already enabled"
vault secrets tune -max-lease-ttl=87600h pki_root

if vault read pki_root/cert/ca > /dev/null 2>&1; then
    echo "✅ Root CA already exists"
else
    vault write -field=certificate pki_root/root/generate/internal \
        common_name="Trading Stack Root CA" \
        issuer_name="root-2024" \
        ttl=87600h \
        key_bits=4096 \
        exclude_cn_from_sans=true \
        organization="Trading Stack" \
        ou="Security" \
        country="US" \
        > /tmp/root_ca.crt
    echo "✅ Root CA generated"
fi

vault write pki_root/config/urls \
    issuing_certificates="$VAULT_ADDR/v1/pki_root/ca" \
    crl_distribution_points="$VAULT_ADDR/v1/pki_root/crl"

# ============================================
# STEP 2: INTERMEDIATE CA
# ============================================
echo ""
echo "📋 Step 2: Creating Intermediate CA..."

vault secrets enable -path=pki_int pki 2>/dev/null || echo "pki_int already enabled"
vault secrets tune -max-lease-ttl=43800h pki_int

vault write -field=csr pki_int/intermediate/generate/internal \
    common_name="Trading Stack Intermediate CA" \
    key_bits=4096 \
    exclude_cn_from_sans=true \
    organization="Trading Stack" \
    ou="Security" \
    country="US" \
    > /tmp/pki_intermediate.csr
echo "✅ Intermediate CSR generated"

vault write -field=certificate pki_root/root/sign-intermediate \
    issuer_ref="root-2024" \
    csr=@/tmp/pki_intermediate.csr \
    format=pem_bundle \
    ttl=43800h \
    > /tmp/intermediate.cert.pem
echo "✅ Intermediate certificate signed by Root CA"

vault write pki_int/intermediate/set-signed \
    certificate=@/tmp/intermediate.cert.pem
echo "✅ Intermediate CA configured"

DEFAULT_ISSUER=$(vault read -field=default pki_int/config/issuers)
vault write pki_int/issuer/$DEFAULT_ISSUER issuer_name="intermediate-2024"
echo "✅ Issuer named 'intermediate-2024'"

vault write pki_int/config/urls \
    issuing_certificates="$VAULT_ADDR/v1/pki_int/ca" \
    crl_distribution_points="$VAULT_ADDR/v1/pki_int/crl"

# ============================================
# STEP 3: CREATE CA CHAIN
# ============================================
echo ""
echo "📋 Step 3: Creating CA chain..."

vault read -field=certificate pki_int/cert/ca > /tmp/intermediate_ca.crt
vault read -field=certificate pki_root/cert/ca > /tmp/root_ca.crt
cat /tmp/intermediate_ca.crt <(echo) /tmp/root_ca.crt > /tmp/ca_chain.pem
echo "✅ CA chain created"

# ============================================
# STEP 4: CREATE ROLE
# ============================================
echo ""
echo "📋 Step 4: Creating certificate role..."

vault write pki_int/roles/trading-services \
    issuer_ref="intermediate-2024" \
    allowed_domains="trading.local,localhost" \
    allow_subdomains=true \
    allow_bare_domains=true \
    allow_localhost=true \
    allow_ip_sans=true \
    allow_any_name=true \
    max_ttl="3650h" \
    ttl="720h" \
    key_bits=2048 \
    key_usage="DigitalSignature,KeyEncipherment" \
    ext_key_usage="ServerAuth,ClientAuth" \
    generate_lease=true
echo "✅ Role 'trading-services' created"

# ============================================
# STEP 5: STORE IN KV
# ============================================
echo ""
echo "📋 Step 5: Storing CA chain in KV store..."

vault secrets enable -path=kv -version=2 kv 2>/dev/null || echo "KV already enabled"

vault kv put kv/pki/ca_chain certificate="$(cat /tmp/ca_chain.pem)"
vault kv put kv/pki/root_ca certificate="$(cat /tmp/root_ca.crt)"
vault kv put kv/pki/intermediate_ca certificate="$(cat /tmp/intermediate_ca.crt)"
echo "✅ CA certificates stored in KV"

# ============================================
# STEP 6: SETUP APPROLE
# ============================================
echo ""
echo "📋 Step 6: Setting up AppRole for the agent..."

vault policy write vault-agent-policy /opt/policies/vault-agent-policy.hcl 2>/dev/null || echo "Policy already exists"
vault policy write reporting-policy /opt/policies/metrics-policy.hcl 2>/dev/null || echo "Reporting policy already exists"
vault auth enable approle 2>/dev/null || echo "AppRole already enabled"

vault write auth/approle/role/cert-agent \
    token_policies="vault-agent-policy,reporting-policy" \
    secret_id_ttl=24h \
    token_ttl=72h \
    token_max_ttl=168h
echo "✅ AppRole 'cert-agent' created"

echo "🔐 Retrieving AppRole credentials..."
vault read -field=role_id auth/approle/role/cert-agent/role-id > /opt/auth/approle/cert-agent/role_id
vault write -f -field=secret_id auth/approle/role/cert-agent/secret-id > /opt/auth/approle/cert-agent/secret_id
echo "✅ AppRole credentials ready"



# ============================================
# STEP 7: GENERATE VAULT CERTIFICATE
# ============================================
echo ""
echo "📋 Step 7: Generating Vault server certificate..."

vault write -format=json pki_int/issue/trading-services \
    common_name="vault.trading.local" \
    alt_names="vault,localhost,trading-vault" \
    ip_sans=127.0.0.1 \
    ttl="3650h" > /tmp/vault.json

jq -r '.data.certificate' "/tmp/vault.json" > "$VAULT_CERT_DIR/server.crt"
jq -r '.data.private_key' "/tmp/vault.json" > "$VAULT_CERT_DIR/server.key"
echo "✅ Vault certificates generated"

# ============================================
# STEP 8: COPY CA CHAIN FOR AGENT
# ============================================
echo ""
echo "📋 Step 8: Copying CA chain for agent..."

cp /tmp/ca_chain.pem "$AGENT_CERT_DIR/ca_chain.pem"
echo "✅ CA chain copied to agent directory"

# ============================================
# STEP 9: SET PERMISSIONS
# ============================================
echo ""
echo "📋 Step 9: Setting permissions..."

chmod 644 "$VAULT_CERT_DIR/server.crt" "$VAULT_CERT_DIR/ca_chain.pem"
chmod 640 "$VAULT_CERT_DIR/server.key"
chmod 644 "$AGENT_CERT_DIR/ca_chain.pem"
chown root:tls-cert "$VAULT_CERT_DIR/server.crt" "$VAULT_CERT_DIR/server.key" "$VAULT_CERT_DIR/ca_chain.pem" 2>/dev/null || true

echo "✅ PKI setup complete!"

touch /vault/data/.initialized

echo "🔄 Restarting Vault with production config..."
kill -SIGHUP 1