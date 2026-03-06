FROM hashicorp/vault:1.21.3

RUN apk add --no-cache jq

RUN mkdir -p /vault/data && chown vault:vault /vault/data

RUN addgroup -g 410 tls-cert && \
    adduser vault tls-cert && \
    adduser root tls-cert && \
    # Create directories with ROOT ownership
    mkdir -p /certs/vault && \
    chown -R root:tls-cert /certs && \
    chmod 750 /certs /certs/vault

# NO USER directive - runs as root