FROM ghcr.io/nbari/pg_exporter:latest

USER root

RUN addgroup -g 410 tls-cert && \
    adduser nobody tls-cert && \
    # Create directory with correct ownership BEFORE switching user
    mkdir -p /certs/postgres-exporter && \
    chown -R nobody:tls-cert /certs && \
    chmod 750 /certs /certs/postgres-exporter

USER nobody