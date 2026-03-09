vault {
  address = "https://vault:8200"  
  
  # TLS client certificates
  ca_cert   = "/certs/agent/ca_chain.pem"
}

auto_auth {
    method "approle" {
        mount_path = "auth/approle"
        config = {
            role_id_file_path = "/etc/vault/role_id"
            secret_id_file_path = "/etc/vault/secret_id"
        }
    }
    sink "file" {
        config = {
            path = "/etc/vault/token"
        }
    }
}

cache {
  use_auto_auth_token = true
}

listener "unix" {
  address = "/tmp/agent.sock"
  tls_disable = true
}

telemetry {
  prometheus_retention_time = "24h"
  disable_hostname = true
  disable_redirect = false
}

listener "tcp" {
  address = "0.0.0.0:9102"
  tls_disable = true  
}

# ============================================
# VAULT
# ============================================

template {
 source       = "/vault/templates/vault.tpl"
 destination  = "/tmp/vault.tpl.rendered"
}



# ============================================
# POSTGRESQL
# ============================================

template {
 source       = "/vault/templates/postgres.tpl"
 destination  = "/tmp/postgres.tpl.rendered"
}


# ============================================
# NIFI
# ============================================

template {
 source       = "/vault/templates/nifi.tpl"
 destination  = "/tmp/nifi.tpl.rendered"
 command = "/certs/generate_nifi_keystore.sh >> /certs/keystore_gen.logs 2>&1"
 wait {
    min = "2s"
    max = "5s"
  }
}

# ============================================
# NIFI-REGISTRY
# ============================================

template {
 source       = "/vault/templates/nifi-registry.tpl"
 destination  = "/tmp/nifi-registry.tpl.rendered"
 command = "/certs/generate_nifi_keystore.sh true >> /certs/keystore_gen.logs 2>&1"
 wait {
    min = "2s"
    max = "5s"
  }
}


# ============================================
# NGINX
# ============================================

template {
 source       = "/vault/templates/nginx.tpl"
 destination  = "/tmp/nginx.tpl.rendered"
}

# ============================================
# DEMO NGINX
# ============================================

template {
 source       = "/vault/templates/demo.tpl"
 destination  = "/tmp/demo.tpl.rendered"
}


# ============================================
# PROMETHEUS
# ============================================

template {
 source       = "/vault/templates/prometheus.tpl"
 destination  = "/tmp/prometheus.tpl.rendered"
}

# ============================================
# POSTGRES-EXPORTER
# ============================================

template {
 source       = "/vault/templates/postgres-exporter.tpl"
 destination  = "/tmp/postgres-exporter.tpl.rendered"
}

# ============================================
# GRAFANA
# ============================================

template {
 source       = "/vault/templates/grafana.tpl"
 destination  = "/tmp/grafana.tpl.rendered"
}

# ============================================
# PROMETHEUS TOKEN 
# ============================================
template {
 source       = "/vault/templates/prometheus-vault-token.tpl"
 destination  = "/tmp/token.tpl.rendered"
}

