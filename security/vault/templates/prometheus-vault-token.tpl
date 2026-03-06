{{ with secret "auth/token/create" "policies=reporting-policy" "display_name=prometheus"}}
  {{ .Auth.ClientToken | writeToFile "/opt/prometheus/token/vault-token" "" "410" "0640" }}
{{ end }}