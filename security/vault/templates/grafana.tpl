{{ with secret "pki_int/issue/trading-services" "common_name=grafana.trading.local" "alt_names=localhost,grafana,trading-grafana" "ip_sans=127.0.0.1" "ttl=720h" }}
{{ .Data.certificate | trimSpace | writeToFile "/certs/grafana/server.crt" "" "410" "0644" }}
{{ .Data.private_key | trimSpace | writeToFile "/certs/grafana/server.key" "" "410" "0600" }}
{{- end -}}

{{ with secret "pki_int/issue/trading-services" "common_name=grafana-client.trading.local" "alt_names=localhost,grafana,trading-grafana" "ip_sans=127.0.0.1" "ttl=720h" }}
{{ .Data.certificate | trimSpace | writeToFile "/certs/grafana/client.crt" "" "410" "0644" }}
{{ .Data.private_key | trimSpace | writeToFile "/certs/grafana/client.key" "" "410" "0640" }}
{{- end -}}


{{ with secret "kv/data/pki/ca_chain" }}
{{ .Data.data.certificate | trimSpace | writeToFile "/certs/grafana/ca.pem" "" "410" "0644" }}
{{- end -}}