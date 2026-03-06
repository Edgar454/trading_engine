# Monitoring

The platform includes a lightweight observability stack built around **Prometheus** and **Grafana**.

Prometheus collects operational metrics from the different components of the system while Grafana provides dashboards for visualization and troubleshooting.

This monitoring layer allows quick detection of performance issues, bottlenecks, or abnormal system behavior.

Prometheus stores metrics in a **time-series database** and exposes them through a query language that Grafana uses to build dashboards and visualizations.

---

# Monitoring Stack

```
Prometheus  →  collects metrics
Grafana     →  visualizes metrics via dashboards
```

Prometheus scrapes metrics exposed by the different services and Grafana queries Prometheus to build real-time dashboards.

---

# Dashboards

The monitoring setup currently includes **three dashboards**, each focused on a critical component of the system.

## Vault Dashboard

Based on Grafana dashboard **12904**

This dashboard provides visibility into the health and activity of the secrets management layer.

Typical metrics include:

* number of active tokens
* number of secrets stored
* request rates
* audit log request counts
* memory usage
* runtime metrics
* identity and token statistics

This dashboard helps detect authentication issues, token leaks, or abnormal secret usage patterns.

---

## NiFi Dashboard

Based on Grafana dashboard **21172**

The NiFi monitoring dashboard focuses on **dataflow performance and JVM health**.

Key indicators include:

* JVM heap usage (used / free / max)
* CPU usage
* FlowFile counts
* queue sizes
* processor throughput
* slowest / fastest processors
* backpressure indicators
* data provenance metrics

This allows rapid identification of bottlenecks or stalled pipelines in the ingestion flow.

---

## PostgreSQL Dashboard

Based on Grafana dashboard **24298**

This dashboard monitors the database that stores market data and trading events.

Key metrics include:

* query throughput
* active connections
* slow queries
* transaction rates
* cache hit ratio
* WAL activity
* disk usage
* replication status (if applicable)

Because the database is the platform's central persistence layer, monitoring these metrics helps detect performance degradation early.

---

# Observability Goals

The monitoring stack focuses on three primary objectives.

## System Health

Ensuring core infrastructure components remain operational.

Examples:

* Vault availability
* PostgreSQL health
* NiFi JVM metrics

---

## Pipeline Visibility

Understanding how data flows through the ingestion pipeline.

Examples:

* queue backlogs
* processor latency
* FlowFile throughput

---

## Performance Monitoring

Detecting performance regressions or resource saturation.

Examples:

* database slow queries
* heap pressure
* high token usage in Vault

---

# Observability Philosophy

Monitoring is treated as a **first-class component of the system architecture**, not an afterthought.

The goal is to ensure that every critical layer of the platform exposes sufficient telemetry to answer three questions quickly:

1. **Is the system healthy?**
2. **Is data flowing correctly through the pipeline?**
3. **Is performance degrading anywhere in the stack?**

By combining infrastructure metrics, application metrics, and pipeline indicators, the monitoring stack provides a clear operational view of the system.

This approach makes it possible to detect issues early, diagnose bottlenecks efficiently, and maintain reliable data ingestion and trading operations.

---

# Future Improvements

Potential future additions include:

* alerting rules with Prometheus Alertmanager
* automated anomaly detection
* distributed tracing for the trading engine
* historical performance analysis dashboards
