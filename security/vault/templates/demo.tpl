{{ with secret "pki_int/issue/trading-services" "common_name=demo.trading.local" "alt_names=localhost,demo,trading-demo" "ip_sans=127.0.0.1" "ttl=720h" }}
{{ .Data.certificate | trimSpace | writeToFile "/certs/demo/demo.crt" "" "" "0644" }}
{{ .Data.private_key | trimSpace | writeToFile "/certs/demo/demo.key" "" "" "0600" }}
{{- end -}}

{{ with secret "kv/data/pki/ca_chain" }}
{{ .Data.data.certificate | trimSpace | writeToFile "/certs/demo/ca.pem" "" "" "0644" }}
{{- end -}}