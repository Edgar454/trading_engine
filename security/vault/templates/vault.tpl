{{ with secret "pki_int/issue/trading-services" "common_name=vault.trading.local" "alt_names=localhost,vault,trading-vault" "ip_sans=127.0.0.1" "ttl=720h" }}
{{ .Data.certificate | trimSpace | writeToFile "/certs/vault/server.crt" "" "410" "0644" }}
{{ .Data.private_key | trimSpace | writeToFile "/certs/vault/server.key" "" "410" "0640" }}
{{- end -}}
