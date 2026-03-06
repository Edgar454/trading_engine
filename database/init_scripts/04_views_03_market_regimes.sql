-- ============================================
-- Script: 05_views/01_market_regimes.sql
-- Description: Market regime classification view
-- Dependencies: 04_continuous_aggregates/*.sql
-- Usage: psql -U postgres -d trading -f 05_views/01_market_regimes.sql
-- ============================================

\c trading

-- ============================================
-- MARKET REGIMES VIEW
-- ============================================

DROP VIEW IF EXISTS market_regimes;

CREATE VIEW market_regimes AS
SELECT 
    c.symbol_id,
    c.ts,
    
    -- Classification logic
    CASE 
        WHEN l2.spread_bps > 50 THEN 'LOW_LIQUIDITY'
        WHEN c.volatility_pct > 3.0 THEN 'VOLATILE'
        WHEN c.returns_pct > 1.0 AND l2.imbalance > 0.3 THEN 'BULLISH_TRENDING'
        WHEN c.returns_pct < -1.0 AND l2.imbalance < -0.3 THEN 'BEARISH_TRENDING'
        WHEN c.buy_pressure_ratio > 0.6 AND c.returns_pct > 0 THEN 'BULLISH_RANGING'
        WHEN c.buy_pressure_ratio < 0.4 AND c.returns_pct < 0 THEN 'BEARISH_RANGING'
        ELSE 'NEUTRAL'
    END AS regime,
    
    -- Confidence score
    CASE 
        WHEN l2.spread_bps > 50 THEN 0.90
        WHEN c.volatility_pct > 3.0 THEN 0.85
        WHEN ABS(c.returns_pct) > 1.0 AND ABS(l2.imbalance) > 0.3 THEN 0.80
        WHEN c.buy_pressure_ratio IS NOT NULL THEN 0.75
        ELSE 0.70
    END AS confidence,
    
    -- Supporting metrics
    l2.imbalance AS orderbook_imbalance,
    l2.spread_bps,
    l2.bid_depth_10,
    l2.ask_depth_10,
    c.volatility_pct,
    c.returns_pct,
    c.buy_pressure_ratio,
    c.volume,
    c.quote_volume,
    
    CASE 
        WHEN l2.ts IS NOT NULL THEN 'L2_AND_CANDLES'
        ELSE 'CANDLES_ONLY'
    END AS source
    
FROM candles_enriched c
LEFT JOIN l2_metrics l2 
    ON c.symbol_id = l2.symbol_id 
    AND c.ts = l2.ts
WHERE c.interval = '5m';

COMMENT ON VIEW market_regimes IS 'Market regime classification using 5-minute candles and L2 snapshots';

\echo '✓ View created: market_regimes'