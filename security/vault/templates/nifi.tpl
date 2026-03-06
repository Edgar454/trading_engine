{{ with secret "pki_int/issue/trading-services" "common_name=nifi.trading.local" "alt_names=localhost,nifi,trading-nifi" "ip_sans=127.0.0.1" "ttl=720h" }}
{{ .Data.certificate | trimSpace | writeToFile "/certs/nifi/server.crt" "" "410" "0644" }}
{{ .Data.private_key  | trimSpace | writeToFile "/certs/nifi/server.key" "" "410" "0640" }}
{{- end -}}

{{ with secret "pki_int/issue/trading-services" "common_name=nifi-client.trading.local" "alt_names=localhost,nifi,trading-nifi" "ip_sans=127.0.0.1" "private_key_format=pkcs8"  "ttl=720h" }}
{{ .Data.certificate | trimSpace | writeToFile "/certs/nifi/client.crt" "" "410" "0644" }}
{{ .Data.private_key  | trimSpace | writeToFile "/certs/nifi/client.key" "" "410" "0640" }}
{{- end -}}

{{ with secret "kv/data/pki/ca_chain" }}
{{ .Data.data.certificate | trimSpace | writeToFile "/certs/nifi/ca.pem" "" "410" "0644" }}
{{- end -}}