FROM timescale/timescaledb:latest-pg15

USER root

RUN addgroup -g 410 tls-cert && \
    adduser postgres tls-cert && \
    # Create directory with correct ownership BEFORE switching user
    mkdir -p /certs/postgres && \
    chown -R postgres:tls-cert /certs && \
    chmod 750 /certs /certs/postgres

COPY ./config/postgresql.conf /etc/postgresql/postgresql.conf
COPY ./config/pg_hba.conf /etc/postgresql/pg_hba.conf
COPY ./config/pg_ident.conf /etc/postgresql/pg_ident.conf

USER postgres

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["postgres", "-c", "config_file=/etc/postgresql/postgresql.conf", "-c", "hba_file=/etc/postgresql/pg_hba.conf", "-c", "ident_file=/etc/postgresql/pg_ident.conf"]


