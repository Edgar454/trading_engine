-- ============================================
-- Script: 08_policies/02_compression.sql
-- Description: Data compression policies
-- Dependencies: 03_hypertables.sql
-- Usage: psql -U postgres -d trading -f 08_policies/02_compression.sql
-- ============================================

\c trading

-- ============================================
-- COMPRESSION SETTINGS
-- ============================================

-- Market trades
ALTER TABLE market_trades SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'symbol_id',
    timescaledb.compress_orderby = 'ts DESC'
);
SELECT add_compression_policy('market_trades', INTERVAL '7 days', if_not_exists => TRUE);

-- Ticks
ALTER TABLE ticks SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'symbol_id',
    timescaledb.compress_orderby = 'ts DESC'
);
SELECT add_compression_policy('ticks', INTERVAL '7 days', if_not_exists => TRUE);

-- L1 orderbook
ALTER TABLE l1_orderbook SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'symbol_id',
    timescaledb.compress_orderby = 'ts DESC'
);
SELECT add_compression_policy('l1_orderbook', INTERVAL '7 days', if_not_exists => TRUE);

-- L2 orderbook
ALTER TABLE l2_orderbook SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'symbol_id, side',
    timescaledb.compress_orderby = 'ts DESC, level ASC'
);
SELECT add_compression_policy('l2_orderbook', INTERVAL '3 days', if_not_exists => TRUE);

-- Verify compression policies
SELECT 
    hypertable_name,
    job_id,
    config
FROM timescaledb_information.jobs
WHERE proc_name = 'policy_compression'
ORDER BY hypertable_name;

\echo '✓ Compression policies configured for all hypertables'