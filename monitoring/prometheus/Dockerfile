FROM prom/prometheus:v3.10.0

USER root

RUN addgroup -g 410 tls-cert && \
    adduser nobody tls-cert && \
    # Create directory with correct ownership BEFORE switching user
    mkdir -p /certs/prometheus && \
    chown -R nobody:tls-cert /certs && \
    chmod 750 /certs /certs/prometheus

USER nobody