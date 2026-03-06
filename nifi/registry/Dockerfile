FROM apache/nifi-registry:2.7.2

USER root

RUN groupadd -g 410 tls-cert && usermod -aG tls-cert nifi

USER nifi