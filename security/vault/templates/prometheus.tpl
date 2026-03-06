{{ with secret "pki_int/issue/trading-services" "common_name=prometheus.trading.local" "alt_names=localhost,prometheus,trading-prometheus" "ip_sans=127.0.0.1" "ttl=720h" }}
{{ .Data.certificate | trimSpace | writeToFile "/certs/prometheus/server.crt" "" "410" "0644" }}
{{ .Data.private_key | trimSpace | writeToFile "/certs/prometheus/server.key" "" "410" "0640" }}
{{- end -}}

{{ with secret "pki_int/issue/trading-services" "common_name=prometheus-client.trading.local" "alt_names=localhost,prometheus,trading-prometheus" "ip_sans=127.0.0.1" "ttl=720h" }}
{{ .Data.certificate | trimSpace | writeToFile "/certs/prometheus/client.crt" "" "410" "0644" }}
{{ .Data.private_key | trimSpace | writeToFile "/certs/prometheus/client.key" "" "410" "0640" }}
{{- end -}}

{{ with secret "kv/data/pki/ca_chain" }}
{{ .Data.data.certificate | trimSpace | writeToFile "/certs/prometheus/ca.pem" "" "410" "0644" }}
{{- end -}}