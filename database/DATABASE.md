# Database Architecture

## Overview

The trading system relies on a PostgreSQL database extended with several modules to support high-volume time-series storage and analytical workloads.

The database serves multiple purposes:

* storing **raw market data**
* storing **derivatives market metrics**
* storing **trading engine decisions and execution events**
* storing **core system metadata**
* supporting **post-trade analytics**

The schema is designed around an **event-driven architecture** where most operational data is recorded as immutable events. This makes it possible to reconstruct system behavior and perform detailed analysis after trading sessions.

The database is initialized automatically using PostgreSQL's `docker-entrypoint-initdb.d` mechanism.

Initialization scripts create:

* schemas
* tables
* extensions
* indexes
* triggers
* views
* roles and permissions

The full database setup is implemented through **26 SQL scripts** organized by responsibility.

Below is a simplified view of the database that excludes the views and the the risk limit table.
![Database](images/database.png)

---

# PostgreSQL Extensions

Several PostgreSQL extensions are used to enhance the capabilities of the database.

### pgcrypto

Used for generating UUID values securely.

Example usage:

```
gen_random_uuid()
```

---

### TimescaleDB

TimescaleDB is used for efficient storage of **time-series market data**.

It provides:

* hypertables
* time-partitioning
* compression
* retention policies
* efficient time-range queries

High-volume tables such as `candles` are implemented as hypertables.

Compression is used to reduce storage costs while maintaining query performance for analytical workloads.

---

### pg_stat_statements

This extension provides visibility into query performance.

It allows monitoring:

* slow queries
* query frequency
* execution statistics

This is useful for identifying inefficient analytical queries and improving system performance.

---

### Additional Query Logging Extension

An additional PostgreSQL extension is used to log executed queries, including `SELECT` statements, to support auditing and performance monitoring.

This helps track how analytical queries interact with the database during system analysis.

---

# Schema Design Philosophy

The schema follows several guiding principles.

### Event Sourcing

Many tables record **events instead of state**.

Examples include:

* signal_events
* trade_events
* position_events

Instead of updating rows to represent the latest state, new events are inserted to represent state changes.

This allows:

* full historical traceability
* deterministic system replay
* detailed post-trade analysis

Derived state such as positions or strategy metrics can later be reconstructed from these events.

---

### Separation of Concerns

The schema is divided into several conceptual domains:

| Domain           | Purpose                                 |
| ---------------- | --------------------------------------- |
| Core entities    | Static reference data                   |
| Market data      | Raw exchange market data                |
| Derivatives data | Metrics specific to derivatives markets |
| Trading events   | Decisions and execution results         |
| Risk management  | Strategy risk limits                    |

---

# Core Entities

Several tables provide foundational metadata used throughout the system.

Examples include:

* assets
* symbols
* strategies
* sessions

These tables describe the trading universe and system configuration.

For example:

* `assets` represent base instruments such as BTC or ETH
* `symbols` represent tradable pairs such as BTCUSDT
* `strategies` represent algorithmic trading strategies
* `sessions` represent trading sessions executed by the system

These tables change infrequently and act as reference data for event tables.

---

# Market Data

The system collects raw market data from exchanges and stores it for analysis and strategy evaluation.

Market data is divided into several categories.

---

## Market Trades

The `market_trades` table stores raw trade data received from exchanges.

Each row represents a trade executed on the exchange.

Stored information includes:

* trade timestamp
* symbol
* price
* quantity
* aggressor side
* exchange trade identifier

This data can be used to reconstruct detailed market activity.

---

## Tick Data

The `ticks` table stores additional tick data used primarily for validation and backup.

In this system it is mainly used for **Binance trade stream validation**.

This redundancy allows the system to detect inconsistencies between different data feeds.

---

## Candlestick Data

The `candles` table stores OHLCV market data for multiple time intervals.

Each candle includes:

* open price
* high price
* low price
* close price
* volume
* quote volume
* trade count
* taker buy volume metrics

This table is implemented as a **TimescaleDB hypertable**.

Compression policies are applied to reduce storage usage while preserving historical data for analysis.

Candles serve as the primary input for the trading engine.

---

## Orderbook Data

Two tables store orderbook snapshots.

### L1 Orderbook

`l1_orderbook` stores the **best bid and ask** at a given timestamp.

This provides a lightweight representation of the market spread.

---

### L2 Orderbook

`l2_orderbook` stores **depth information for the top 20 levels** of the orderbook.

Each row contains:

* side (bid or ask)
* price
* quantity
* depth level

Because of the large volume of this data, retention periods are shorter.

---

# Derivatives Market Data

Additional tables store metrics specific to derivatives markets.

These metrics are useful for sentiment analysis and advanced strategies.

---

## Funding Rates

The `funding_rates` table stores funding rates for perpetual futures contracts.

Each record includes:

* funding rate
* mark price
* funding period interval

Funding rates are important indicators of market sentiment and leverage imbalance.

---

## Open Interest

The `open_interests` table tracks the total number of open contracts in the market.

Increasing open interest may indicate growing participation in a market move.

---

## Liquidations

The `liquidations` table records forced liquidations occurring on derivatives exchanges.

Each liquidation event includes:

* liquidation side (long or short)
* price
* quantity

Large liquidation cascades can signal significant market stress.

---

# Trading Engine Events

The trading engine records its decisions and execution outcomes in several event tables.

These tables represent the operational history of the trading system.

---

## Signal Events

`signal_events` records signals generated by trading strategies.

Each signal represents a decision produced by the trading engine.

Signals include:

* strategy
* symbol
* action (buy, sell, close)
* quantity
* optional limit price

Signals may also record risk evaluation results and exchange responses.

This table provides visibility into **why a trade was attempted**.

---

## Orders

The `orders` table tracks the lifecycle of orders sent to exchanges.

Orders move through several states:

```
PENDING → SUBMITTED → ACCEPTED → PARTIALLY_FILLED → FILLED
```

or

```
PENDING → REJECTED / CANCELLED / EXPIRED
```

Each order references the signal that generated it.

---

## Trade Events

`trade_events` records executions returned by exchanges.

One order may generate multiple trade events due to partial fills.

Each trade event includes:

* execution price
* quantity
* fee
* exchange trade identifier

---

## Position Events

Positions are represented using an event model.

Instead of updating a position record directly, position changes are recorded as events such as:

* OPEN
* ADD
* REDUCE
* CLOSE
* PRICE_UPDATE

This allows full reconstruction of position history and accurate performance analysis.

---

# Risk Management

Risk rules used by trading strategies are stored in the `risk_limits` table.

Each rule defines:

* the strategy to which it applies
* an optional symbol scope
* the rule name
* a numeric threshold

These limits are evaluated by the trading engine before orders are submitted.

Examples of risk rules may include:

* maximum position size
* maximum drawdown
* maximum exposure per asset

---

# Data Retention

Because market data can grow rapidly, several tables use retention strategies.

Typical retention policies include:

| Table          | Retention              |
| -------------- | ---------------------- |
| market_trades  | ~30 days               |
| ticks          | ~30 days               |
| l1_orderbook   | ~30 days               |
| l2_orderbook   | ~7 days                |
| candles        | long-term (compressed) |
| funding_rates  | ~1 year                |
| liquidations   | ~1 year                |
| open_interests | ~2 years               |

Compression policies are applied where appropriate using TimescaleDB.

---

# Analytical Workflows

The operational database primarily serves as a **data ingestion and storage layer**.

For heavy analytical workloads, data is extracted and transformed using **dbt pipelines** and loaded into **DuckDB analytical environments**.

This architecture provides:

* fast analytical queries
* separation of operational and analytical workloads
* efficient dashboard generation

Analytical queries typically run **weekly**, rather than continuously.

---

# Summary

The database architecture is designed to support:

* reliable ingestion of market data
* detailed tracking of trading engine decisions
* complete historical reconstruction of trading activity
* efficient analytical workflows

By combining **event sourcing**, **TimescaleDB time-series storage**, and **analytical pipelines**, the system provides both operational robustness and powerful post-trade analysis capabilities.

---
