{{ with secret "pki_int/issue/trading-services" "common_name=nginx.trading.local" "alt_names=localhost,nginx,trading-nginx" "ip_sans=127.0.0.1" "ttl=720h" }}
{{ .Data.certificate | trimSpace | writeToFile "/certs/nginx/server.crt" "" "" "0644" }}
{{ .Data.private_key | trimSpace | writeToFile "/certs/nginx/server.key" "" "" "0600" }}
{{- end -}}

{{ with secret "kv/data/pki/ca_chain" }}
{{ .Data.data.certificate | trimSpace | writeToFile "/certs/nginx/ca.pem" "" "" "0644" }}
{{- end -}}