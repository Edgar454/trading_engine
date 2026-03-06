# Security Architecture

This document describes the security model used by the trading platform. The system follows a **Zero Trust architecture** where every service must prove its identity cryptographically using certificates.

The core assumption of the system is simple:

> A certificate represents the identity of a service.

Instead of relying on passwords or trusted networks, every service authenticates using **mutual TLS (mTLS)**. Certificates are automatically generated, distributed, and rotated using Vault and Vault Agent.

---

# Zero Trust Model

The platform follows a Zero Trust design where no component is implicitly trusted.

Key principles:

* Identity is enforced through **cryptographic certificates**
* All service communications use **mutual TLS**
* Secrets are **automatically generated and rotated**
* Access control is enforced using **least privilege policies**

Even if a service obtains a valid certificate, it must still satisfy additional authorization checks before accessing protected resources.

---

# PKI Infrastructure

The platform uses an internal Public Key Infrastructure (PKI) managed by Vault.

The PKI hierarchy consists of two levels:

Root CA (10 years)
↓
Intermediate CA (5 years)
↓
Service Certificates

The Root CA signs the Intermediate CA through a Certificate Signing Request (CSR). Service certificates are issued by the Intermediate CA.

Certificates are restricted to the internal domain:

```
trading.local
```

This ensures that certificates cannot be used outside of the platform infrastructure.

---

# Certificate Lifecycle

Certificates are generated and managed automatically using **Vault Agent**.

The agent authenticates to Vault using **AppRole** and retrieves certificates through Consul Template.

Responsibilities of the Vault Agent:

* Authenticate to Vault
* Generate service certificates
* Renew certificates before expiration
* Distribute secrets to services
* Generate additional artifacts when required (for example keystores)

Certificates are automatically rotated without requiring manual intervention.

Typical certificate lifetimes:

* Client services: 30 days
* Server services: 6 months

---

# Service Identity

Each service receives its own certificate.

Service identity is derived directly from the certificate used during authentication.

Example identity flow:

```
Service Certificate
   ↓
PostgreSQL pg_ident mapping
   ↓
Database User
   ↓
Role Permissions
```

Even with a valid certificate, access is denied if the identity is not mapped to a valid database role.

---

# Database Security

PostgreSQL authentication relies primarily on **certificate-based authentication**.

Key mechanisms:

* Database users are derived from client certificates
* `pg_ident` maps certificate identities to database users
* Role-based access control restricts allowed operations

This ensures that possessing a certificate alone is insufficient to access the database.

Additional monitoring includes:

* Connection logging
* SSL statistics
* Table-level statistics

Individual queries are not logged to avoid performance degradation, but aggregated statistics are collected.

An emergency superuser account exists using password authentication. This account is intended only for disaster recovery scenarios.

---

# Monitoring and Observability

Security monitoring is performed using **Prometheus** and **Grafana**.

Metrics collected include:

Vault metrics:

* number of active identities
* certificate issuance statistics
* secret access frequency
* Vault health status

Database metrics:

* connection statistics
* SSL usage
* table access statistics

These metrics allow detection of abnormal behaviors and long-term trend analysis.

---

# Network Isolation

Vault and its agents operate on a **dedicated internal network** and are not directly exposed.

All platform services communicate using **mutual TLS**.

Services that do not natively support mTLS are placed behind an **NGINX reverse proxy** that enforces TLS authentication.

This reduces the attack surface and ensures that all traffic is authenticated.

---

# Vault Infrastructure Layout

Security-related files are organized under:

```
security/vault/
```

The directory contains four main components.

## config

Contains configuration files:

* Vault configuration
* Vault policies
* Vault Agent configuration
* Vault Dockerfile

## setup

Bootstrap scripts used to initialize the PKI infrastructure.

Scripts include:

* `init_vault` — initializes Vault and creates the PKI hierarchy
* `generate_keystore` — generates keystore and truststore artifacts required by NiFi
* `bootstrap_certs` — creates temporary certificates allowing Vault to start before the PKI infrastructure is initialized

## templates

Consul Template files used by Vault Agent to generate and distribute:

* certificates
* tokens
* AppRole credentials
* CA certificate chain

## vault_certs

Temporary certificates used to start Vault with TLS enabled before the PKI is fully initialized.

These certificates are replaced once Vault generates the official certificate chain.

---

# Security Principles Summary

The platform security model is based on the following principles:

* Identity-based authentication using certificates
* Automatic secret lifecycle management
* Strict least-privilege access control
* Continuous monitoring and observability
* Reduced attack surface through network isolation

This architecture minimizes manual secret management and reduces the risk of credential compromise while maintaining strong operational security.
