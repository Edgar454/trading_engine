FROM grafana/grafana:12.3

USER root

RUN addgroup -g 410 tls-cert && \
    adduser grafana tls-cert && \
    # Create directory with correct ownership BEFORE switching user
    mkdir -p /certs/grafana && \
    chown -R grafana:tls-cert /certs && \
    chmod 750 /certs /certs/grafana


USER grafana