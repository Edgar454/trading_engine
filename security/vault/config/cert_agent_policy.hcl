# file: policies/pki-agent.hcl
path "pki_int/issue/trading-services" {
  capabilities = ["create", "update"]
}

path "pki_int/roles/trading-services" {
  capabilities = ["read"]
}

path "pki_int/cert/*" {
  capabilities = ["read"]
}

path "kv/data/pki/*" {
  capabilities = ["read"]
}

path "auth/token/create" {
  capabilities = ["create", "update"]
}

# Optional but good for cleanup
path "auth/token/revoke-accessor" {
  capabilities = ["update"]
}