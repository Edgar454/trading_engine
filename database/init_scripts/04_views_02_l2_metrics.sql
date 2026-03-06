-- ============================================
-- Script: 04_continuous_aggregates/02_l2_metrics.sql
-- Description: L2 orderbook metrics continuous aggregate
-- Dependencies: 03_hypertables.sql
-- Usage: psql -U postgres -d trading -f 04_continuous_aggregates/02_l2_metrics.sql
-- ============================================

\c trading

-- ============================================
-- L2 METRICS VIEW
-- ============================================

-- Drop the useless aggregate
DROP MATERIALIZED VIEW IF EXISTS l2_metrics_5m CASCADE;

-- Create a simple view that calculates metrics on-the-fly
CREATE VIEW l2_metrics AS
SELECT 
    symbol_id,
    ts,
    
    -- Orderbook imbalance (bid vs ask volume at top 5 levels)
    (sum(CASE WHEN side = 'BUY' AND level <= 5 THEN quantity ELSE 0 END) -
     sum(CASE WHEN side = 'SELL' AND level <= 5 THEN quantity ELSE 0 END)) /
    NULLIF(sum(CASE WHEN level <= 5 THEN quantity ELSE 0 END), 0) AS imbalance,
    
    -- Spread in basis points
    (max(CASE WHEN side = 'SELL' AND level = 1 THEN price END) -
     max(CASE WHEN side = 'BUY' AND level = 1 THEN price END)) /
    NULLIF(max(CASE WHEN side = 'BUY' AND level = 1 THEN price END), 0) * 10000 AS spread_bps,
    
    -- Best bid/ask
    max(CASE WHEN side = 'BUY' AND level = 1 THEN price END) AS best_bid,
    max(CASE WHEN side = 'SELL' AND level = 1 THEN price END) AS best_ask,
    
    -- Depth at top 10 levels
    sum(CASE WHEN side = 'BUY' AND level <= 10 THEN quantity ELSE 0 END) AS bid_depth_10,
    sum(CASE WHEN side = 'SELL' AND level <= 10 THEN quantity ELSE 0 END) AS ask_depth_10
    
FROM l2_orderbook
GROUP BY symbol_id, ts;


COMMENT ON VIEW l2_metrics IS 'L2 orderbook metrics calculated per snapshot (no aggregation since snapshots are every 5 min)';

\echo '✓ Continuous aggregate created: l2_metrics'