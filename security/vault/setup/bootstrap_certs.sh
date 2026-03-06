#!/bin/bash
set -euo pipefail

# Your mounted certs directory
CERT_DIR="/home/azureuser/data_pipeline/security/vault/vault_certs"

# Create directory if it doesn't exist
mkdir -p "$CERT_DIR"

echo "🔐 Generating PLACEHOLDER bootstrap certificates in $CERT_DIR..."
echo "These will be replaced by real certificates from Vault PKI later."

# ============================================
# Generate a simple CA (placeholder)
# ============================================
echo "📋 Generating CA..."
openssl genrsa -out "$CERT_DIR/ca.key" 2048

# Fixed: Removed the comment after the line continuation
openssl req -x509 -new -nodes -key "$CERT_DIR/ca.key" \
    -sha256 -days 30 \
    -out "$CERT_DIR/ca.crt" \
    -subj "/CN=Placeholder CA/O=Trading Stack/OU=Bootstrap"

# ============================================
# Generate placeholder server cert
# ============================================
echo "📋 Generating server certificate..."
openssl genrsa -out "$CERT_DIR/server.key" 2048

# Simple CSR config
cat > /tmp/placeholder.conf <<EOF
[req]
distinguished_name = req_distinguished_name
prompt = no

[req_distinguished_name]
CN = placeholder.trading.local
EOF

openssl req -new -key "$CERT_DIR/server.key" \
    -out /tmp/server.csr \
    -config /tmp/placeholder.conf

# Sign with placeholder CA
openssl x509 -req -in /tmp/server.csr \
    -CA "$CERT_DIR/ca.crt" -CAkey "$CERT_DIR/ca.key" -CAcreateserial \
    -out "$CERT_DIR/server.crt" -days 30 \
    -sha256

# ============================================
# Create placeholder CA chain
# ============================================
#cp "$CERT_DIR/ca.crt" "$CERT_DIR/ca_chain.pem"
cp "$CERT_DIR/ca.crt" "$CERT_DIR/ca_chain.pem"

chmod 644 "$CERT_DIR/server.crt" "$CERT_DIR/ca_chain.pem" #"$CERT_DIR/ca.pem"
chmod 644 "$CERT_DIR/server.key"
# ============================================
# Clean up
# ============================================
rm -f /tmp/server.csr /tmp/placeholder.conf "$CERT_DIR/ca.srl" "$CERT_DIR/ca.key" "$CERT_DIR/ca.crt"

echo ""
echo "✅ PLACEHOLDER certificates created in: $CERT_DIR"
ls -la "$CERT_DIR"
echo ""
echo "⚠️  These are temporary! Your Vault init script will replace them."