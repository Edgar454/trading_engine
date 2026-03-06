-- ============================================
-- Script: 03_hypertables.sql
-- Description: Convert time-series tables to TimescaleDB hypertables
-- Dependencies: 02_tables/*.sql
-- Usage: psql -U postgres -d trading -f 03_hypertables.sql
-- ============================================

\c trading

-- ============================================
-- CONVERT TO HYPERTABLES
-- ============================================

-- Market trades
SELECT create_hypertable(
    'market_trades', 
    'ts',
    chunk_time_interval => INTERVAL '1 day',
    if_not_exists => TRUE
);

-- Ticks
SELECT create_hypertable(
    'ticks', 
    'ts',
    chunk_time_interval => INTERVAL '1 day',
    if_not_exists => TRUE
);

-- L1 orderbook
SELECT create_hypertable(
    'l1_orderbook', 
    'ts',
    chunk_time_interval => INTERVAL '1 day',
    if_not_exists => TRUE
);

-- L2 orderbook
SELECT create_hypertable(
    'l2_orderbook', 
    'ts',
    chunk_time_interval => INTERVAL '1 day',
    if_not_exists => TRUE
);

-- Funding rates
SELECT create_hypertable(
    'funding_rates', 
    'ts',
    chunk_time_interval => INTERVAL '7 days',
    if_not_exists => TRUE
);

-- Open interests
SELECT create_hypertable(
    'open_interests', 
    'ts',
    chunk_time_interval => INTERVAL '7 days',
    if_not_exists => TRUE
);

-- Liquidations
SELECT create_hypertable(
    'liquidations', 
    'ts',
    chunk_time_interval => INTERVAL '7 days',
    if_not_exists => TRUE
);

-- Verify hypertables
SELECT 
    hypertable_schema,
    hypertable_name,
    num_dimensions
FROM timescaledb_information.hypertables
WHERE hypertable_schema = 'public'
ORDER BY hypertable_name;

\echo '✓ Hypertables created: market_trades, ticks, l1_orderbook, l2_orderbook, funding_rates, open_interests, liquidations'