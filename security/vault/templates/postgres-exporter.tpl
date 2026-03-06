{{ with secret "pki_int/issue/trading-services" "common_name=postgres-exporter.trading.local" "alt_names=localhost,postgres-exporter,trading-postgres-exporter" "ip_sans=127.0.0.1" "ttl=720h" }}
{{ .Data.certificate | trimSpace | writeToFile "/certs/postgres-exporter/server.crt" "" "410" "0644" }}
{{ .Data.private_key | trimSpace | writeToFile "/certs/postgres-exporter/server.key" "" "410" "0640" }}
{{- end -}}

{{ with secret "kv/data/pki/ca_chain" }}
{{ .Data.data.certificate | trimSpace | writeToFile "/certs/postgres-exporter/ca.crt" "" "410" "0644" }}
{{- end -}}