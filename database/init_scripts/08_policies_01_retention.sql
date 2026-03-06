-- ============================================
-- Script: 08_policies/01_retention.sql
-- Description: Data retention policies
-- Dependencies: 03_hypertables.sql
-- Usage: psql -U postgres -d trading -f 08_policies/01_retention.sql
-- ============================================

\c trading

-- ============================================
-- RETENTION POLICIES
-- ============================================

-- Market trades (30 days)
SELECT add_retention_policy('market_trades', INTERVAL '30 days', if_not_exists => TRUE);

-- Ticks (30 days)
SELECT add_retention_policy('ticks', INTERVAL '30 days', if_not_exists => TRUE);

-- L1 orderbook (30 days)
SELECT add_retention_policy('l1_orderbook', INTERVAL '30 days', if_not_exists => TRUE);

-- L2 orderbook (7 days - large volume)
SELECT add_retention_policy('l2_orderbook', INTERVAL '7 days', if_not_exists => TRUE);

-- Funding rates (1 year)
SELECT add_retention_policy('funding_rates', INTERVAL '1 year', if_not_exists => TRUE);

-- Open interests (2 years)
SELECT add_retention_policy('open_interests', INTERVAL '2 years', if_not_exists => TRUE);

-- Liquidations (1 year)
SELECT add_retention_policy('liquidations', INTERVAL '1 year', if_not_exists => TRUE);

-- Verify retention policies
SELECT 
    hypertable_name,
    job_id,
    config
FROM timescaledb_information.jobs
WHERE proc_name = 'policy_retention'
ORDER BY hypertable_name;

\echo '✓ Retention policies configured for all hypertables'