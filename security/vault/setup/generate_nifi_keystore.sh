#!/bin/sh
# Convert PEM certificates to Java keystores for NiFi
set -e

IS_REGISTRY=${1:-"false"}
CERT_DIR="/certs/nifi"
PASSWORD=${NIFI_KEYSTORE_PASSWORD}
CLIENT_PASSWORD=${NIFI_CLIENT_KEYSTORE_PASSWORD:-$NIFI_KEYSTORE_PASSWORD}

if [ "$IS_REGISTRY" = "true" ]; then
  CERT_DIR="/certs/nifi-registry"
  PASSWORD=${NIFI_REGISTRY_KEYSTORE_PASSWORD:-$NIFI_KEYSTORE_PASSWORD}
fi


echo "🔐 Creating NiFi Java keystores..."

# Wait for Vault Agent to create certs
while [ ! -f "$CERT_DIR/server.crt" ]; do
  echo "Waiting for certificates..."
  sleep 2
done

if [  -f "$CERT_DIR/keystore.jks" ] && [ -f "$CERT_DIR/truststore.jks" ]; then
  echo "Found  existing keystore and truststore, removing and regenerating..."
  rm -f "$CERT_DIR/keystore.jks" "$CERT_DIR/truststore.jks"
fi

# Create PKCS12 keystore (contains private key + cert)
openssl pkcs12 -export \
    -in "$CERT_DIR/server.crt" \
    -inkey "$CERT_DIR/server.key" \
    -out "$CERT_DIR/keystore.p12" \
    -name nifi \
    -CAfile "$CERT_DIR/ca.pem" \
    -chain \
    -password "pass:$PASSWORD"

# Convert PKCS12 to JKS
keytool -importkeystore \
  -srckeystore "$CERT_DIR/keystore.p12"\
  -srcstoretype PKCS12 \
  -srcstorepass "$PASSWORD" \
  -destkeystore "$CERT_DIR/keystore.jks" \
  -deststoretype JKS \
  -deststorepass "$PASSWORD" \
  -noprompt

if [ "$IS_REGISTRY" = "false" ]; then

  openssl pkcs12 -export \
      -in "$CERT_DIR/client.crt" \
      -inkey "$CERT_DIR/client.key" \
      -out "$CERT_DIR/client_keystore.p12" \
      -name nifi \
      -CAfile "$CERT_DIR/ca.pem" \
      -chain \
      -password "pass:$CLIENT_PASSWORD"

  # Convert PKCS12 to JKS
  keytool -importkeystore \
    -srckeystore "$CERT_DIR/client_keystore.p12"\
    -srcstoretype PKCS12 \
    -srcstorepass "$PASSWORD" \
    -destkeystore "$CERT_DIR/client_keystore.jks" \
    -deststoretype JKS \
    -deststorepass "$CLIENT_PASSWORD" \
    -noprompt

  # Also export client key in PKCS8 DER format for NiFi Postgres connexion
  openssl pkcs8 -topk8 -inform PEM -outform DER \
    -in "$CERT_DIR/client.key" -out "$CERT_DIR/client.pk8" -nocrypt

  chown root:tls-cert "$CERT_DIR/client.pk8"
  chmod 640 "$CERT_DIR/client.pk8"
fi

# Create truststore with CA chain
keytool -import \
  -file "$CERT_DIR/ca.pem" \
  -alias ca-chain \
  -keystore "$CERT_DIR/truststore.jks" \
  -storepass "$PASSWORD" \
  -noprompt

# Cleanup intermediate files
rm -f "$CERT_DIR/keystore.p12" "$CERT_DIR/server.crt" "$CERT_DIR/server.key" 

echo "✅ NiFi stores created!"
ls -lh "$CERT_DIR"/*.jks