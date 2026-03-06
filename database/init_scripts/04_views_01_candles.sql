-- ============================================
-- Script: 04_continuous_aggregates/01_candles.sql
-- Description: Create continuous aggregates for all candle intervals
-- Dependencies: 03_hypertables.sql
-- Usage: psql -U postgres -d trading -f 04_continuous_aggregates/01_candles.sql
-- ============================================

\c trading

-- ============================================
-- CANDLES Enriched
-- ============================================

CREATE VIEW candles_enriched AS
SELECT 
    symbol_id,
    interval,
    ts,
    
    -- Raw OHLCV
    open, high, low, close, volume, quote_volume,
    
    -- Order flow
    taker_buy_volume,
    taker_buy_quote_volume,
    (volume - COALESCE(taker_buy_volume, 0)) AS taker_sell_volume,
    (quote_volume - COALESCE(taker_buy_quote_volume, 0)) AS taker_sell_quote_volume,
    
    -- Derived metrics
    CASE WHEN volume > 0 THEN taker_buy_volume / volume ELSE NULL END AS buy_pressure_ratio,
    (close - open) / NULLIF(open, 0) * 100 AS returns_pct,
    (high - low) / NULLIF(close, 0) * 100 AS volatility_pct,
    quote_volume / NULLIF(volume, 0) AS vwap,
    
    trade_count
    
FROM candles;

COMMENT ON VIEW candles_enriched IS 'Enriched candles with calculated order flow and volatility metrics';

-- Verify continuous aggregates
SELECT 
    view_name,
    materialization_hypertable_name
FROM timescaledb_information.continuous_aggregates
WHERE view_name LIKE 'candles_%'
ORDER BY view_name;

\echo '✓ Continuous aggregates created: candles_enriched'