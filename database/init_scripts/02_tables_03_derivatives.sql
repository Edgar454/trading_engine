-- ============================================
-- Script: 02_tables/03_derivatives.sql
-- Description: Derivatives tables (funding rates, OI, liquidations)
-- Dependencies: 02_tables/01_core.sql
-- Usage: psql -U postgres -d trading -f 02_tables/03_derivatives.sql
-- ============================================

\c trading

-- ============================================
-- FUNDING RATES (perpetual contracts only)
-- ============================================

CREATE TABLE funding_rates (
    ts TIMESTAMPTZ NOT NULL,
    symbol_id UUID NOT NULL REFERENCES symbols(symbol_id),
    
    rate DECIMAL(10,8) NOT NULL,
    mark_price DECIMAL(20,8) NOT NULL,
    period_interval DECIMAL(5,2) DEFAULT 8.0,
    
    PRIMARY KEY (symbol_id, ts)
);

-- Indexes
CREATE INDEX idx_funding_rates_symbol_ts ON funding_rates (symbol_id, ts DESC);

-- Comments
COMMENT ON TABLE funding_rates IS 'Funding rates for perpetual contracts only. 1-year retention.';
COMMENT ON COLUMN funding_rates.rate IS 'Current funding rate as decimal (0.0001 = 0.01% per period).';
COMMENT ON COLUMN funding_rates.period_interval IS 'Funding period in hours (typically 8 hours).';

-- ============================================
-- OPEN INTERESTS (perpetuals & futures)
-- ============================================

CREATE TABLE open_interests (
    ts TIMESTAMPTZ NOT NULL,
    symbol_id UUID NOT NULL REFERENCES symbols(symbol_id),
    
    oi DECIMAL(20,8) NOT NULL CHECK (oi >= 0),
    
    PRIMARY KEY (symbol_id, ts)
);

-- Indexes
CREATE INDEX idx_open_interests_symbol_ts ON open_interests (symbol_id, ts DESC);

-- Comments
COMMENT ON TABLE open_interests IS 'Open interest for perpetuals and futures. 2-year retention.';
COMMENT ON COLUMN open_interests.oi IS 'Total open interest in number of contracts.';

-- ============================================
-- LIQUIDATIONS (perpetuals & futures)
-- ============================================

CREATE TABLE liquidations (
    ts TIMESTAMPTZ NOT NULL,
    symbol_id UUID NOT NULL REFERENCES symbols(symbol_id),
    
    side TEXT NOT NULL CHECK (side IN ('LONG', 'SHORT')),
    
    price DECIMAL(20,8) NOT NULL CHECK (price > 0),
    quantity DECIMAL(20,8) NOT NULL CHECK (quantity > 0),
    
    PRIMARY KEY (symbol_id, ts, side)
);

-- Indexes
CREATE INDEX idx_liquidations_symbol_ts ON liquidations (symbol_id, ts DESC);
CREATE INDEX idx_liquidations_side ON liquidations (side);

-- Comments
COMMENT ON TABLE liquidations IS 'Liquidation events. Tracks cascade liquidations. 1-year retention.';
COMMENT ON COLUMN liquidations.side IS 'Which side got liquidated: LONG or SHORT.';

\echo '✓ Derivatives tables created: funding_rates, open_interests, liquidations'