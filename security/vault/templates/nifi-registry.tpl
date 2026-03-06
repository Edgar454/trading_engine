{{ with secret "pki_int/issue/trading-services" "common_name=nifi-registry.trading.local" "alt_names=localhost,nifi-registry,trading-nifi-registry" "ip_sans=127.0.0.1" "ttl=720h" }}
{{ .Data.certificate | trimSpace | writeToFile "/certs/nifi-registry/server.crt" "" "410" "0644" }}
{{ .Data.private_key  | trimSpace | writeToFile "/certs/nifi-registry/server.key" "" "410" "0600" }}
{{- end -}}


{{ with secret "kv/data/pki/ca_chain" }}
{{ .Data.data.certificate | trimSpace | writeToFile "/certs/nifi-registry/ca.pem" "" "410" "0644" }}
{{- end -}}