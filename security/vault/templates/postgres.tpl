{{ with secret "pki_int/issue/trading-services" "common_name=postgres.trading.local" "alt_names=localhost,postgres,timescaledb,trading-postgres" "ip_sans=127.0.0.1" "ttl=720h" }}
{{ .Data.certificate | trimSpace | writeToFile "/certs/postgres/server.crt" "" "410" "0644" }}
{{ .Data.private_key | trimSpace | writeToFile "/certs/postgres/server.key" "" "410" "0640" }}
{{- end -}}

{{ with secret "kv/data/pki/ca_chain" }}
{{ .Data.data.certificate | trimSpace | writeToFile "/certs/postgres/ca.crt" "" "410" "0644" }}
{{- end -}}