FROM eclipse-temurin:17-jdk-jammy

USER root

RUN apt-get update && apt-get install -y curl unzip openssl acl \
    && curl -sSL https://releases.hashicorp.com/vault/1.21.3/vault_1.21.3_linux_amd64.zip -o /tmp/vault.zip \
    && unzip /tmp/vault.zip -d /usr/local/bin/ \
    && rm /tmp/vault.zip

RUN groupadd -g 410 tls-cert && usermod -aG tls-cert root

# Now set ACL (user exists now)
RUN mkdir -p /certs && setfacl -R -m u:root:rwx /certs \
    && setfacl -R -d -m u:root:rwx /certs

COPY security/vault/config/agent_config.hcl /vault/config/agent.hcl
COPY security/vault/templates /vault/templates/
COPY security/vault/setup/generate_nifi_keystore.sh /certs/generate_nifi_keystore.sh

RUN chmod +x /certs/generate_nifi_keystore.sh

ENTRYPOINT ["vault", "agent", "-config=/vault/config/agent.hcl"]