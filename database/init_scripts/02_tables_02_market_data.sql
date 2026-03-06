-- ============================================
-- Script: 02_tables/02_market_data.sql
-- Description: Market data tables (trades, orderbook)
-- Dependencies: 02_tables/01_core.sql
-- Usage: psql -U postgres -d trading -f 02_tables/02_market_data.sql
-- ============================================

\c trading

-- ============================================
-- MARKET TRADES (raw trade data from exchanges)
-- ============================================

CREATE TABLE market_trades (
    ts TIMESTAMPTZ NOT NULL,
    symbol_id UUID NOT NULL REFERENCES symbols(symbol_id),
    
    -- Trade identification
    exchange_trade_id TEXT NOT NULL,
    
    -- Trade details
    price DECIMAL(20,8) NOT NULL CHECK (price > 0),
    quantity DECIMAL(20,8) NOT NULL CHECK (quantity > 0),
    
    side TEXT NOT NULL CHECK (side IN ('buy', 'sell')),
    is_maker BOOLEAN,
    
    -- Source metadata
    source TEXT,
    
    PRIMARY KEY (symbol_id, ts, exchange_trade_id)
);

-- Indexes (basic, hypertable conversion comes later)
CREATE INDEX idx_market_trades_symbol_ts ON market_trades (symbol_id, ts DESC);

-- Comments
COMMENT ON TABLE market_trades IS 'Raw market trades from exchanges. Primary source for candles. 30-day retention.';
COMMENT ON COLUMN market_trades.side IS 'Aggressor side: BUY (taker bought) or SELL (taker sold).';

-- ============================================
-- TICKS (Binance backup/validation)
-- ============================================

CREATE TABLE ticks (
    ts TIMESTAMPTZ NOT NULL,
    symbol_id UUID NOT NULL REFERENCES symbols(symbol_id),
    
    price DECIMAL(20,8) NOT NULL CHECK (price > 0),
    quantity DECIMAL(20,8) NOT NULL CHECK (quantity > 0),
    
    trade_id TEXT,
    is_buyer_maker BOOLEAN,
    
    PRIMARY KEY (symbol_id, ts, trade_id)
);

-- Indexes
CREATE INDEX idx_ticks_symbol_ts ON ticks (symbol_id, ts DESC);

-- Comments
COMMENT ON TABLE ticks IS 'Binance tick data for backup/validation. 30-day retention.';

-- ============================================
-- Candles (OHLCV bars for multiple intervals)
-- ============================================
CREATE TABLE candles (
    ts TIMESTAMPTZ NOT NULL,
    symbol_id UUID NOT NULL REFERENCES symbols(symbol_id) ON DELETE CASCADE,
    interval VARCHAR(10) NOT NULL,
    
    -- OHLCV (standard)
    open DECIMAL(20,8) NOT NULL,
    high DECIMAL(20,8) NOT NULL,
    low DECIMAL(20,8) NOT NULL,
    close DECIMAL(20,8) NOT NULL,
    volume DECIMAL(30,8) NOT NULL,
    quote_volume DECIMAL(30,8) NOT NULL,
    
    -- Order flow data (for future strategy development)
    taker_buy_volume DECIMAL(30,8),
    taker_buy_quote_volume DECIMAL(30,8),
    trade_count INTEGER,
    
    PRIMARY KEY (symbol_id, interval, ts)
);

SELECT create_hypertable('candles', 'ts');

CREATE INDEX idx_candles_symbol_interval_ts ON candles (symbol_id, interval, ts DESC);

ALTER TABLE candles SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'symbol_id, interval',
    timescaledb.compress_orderby = 'ts DESC'
);

SELECT add_compression_policy('candles', INTERVAL '7 days');

COMMENT ON TABLE candles IS 'OHLCV candle data from Binance Klines API with order flow metrics';

-- ============================================
-- L1 ORDERBOOK (best bid/ask)
-- ============================================

CREATE TABLE l1_orderbook (
    ts TIMESTAMPTZ NOT NULL,
    symbol_id UUID NOT NULL REFERENCES symbols(symbol_id),
    
    best_bid_price DECIMAL(20,8) CHECK (best_bid_price > 0),
    best_bid_qty DECIMAL(20,8) CHECK (best_bid_qty > 0),
    best_ask_price DECIMAL(20,8) CHECK (best_ask_price > 0),
    best_ask_qty DECIMAL(20,8) CHECK (best_ask_qty > 0),
    
    PRIMARY KEY (symbol_id, ts),
    
    CHECK (best_ask_price >= best_bid_price)
);

-- Indexes
CREATE INDEX idx_l1_orderbook_symbol_ts ON l1_orderbook (symbol_id, ts DESC);

-- Comments
COMMENT ON TABLE l1_orderbook IS 'Level 1 orderbook (best bid/ask). 30-day retention.';

-- ============================================
-- L2 ORDERBOOK (depth, top 20 levels)
-- ============================================

CREATE TABLE l2_orderbook (
    ts TIMESTAMPTZ NOT NULL,
    symbol_id UUID NOT NULL REFERENCES symbols(symbol_id),
    
    side TEXT NOT NULL CHECK (side IN ('bid', 'ask')),
    
    price DECIMAL(20,8) NOT NULL CHECK (price > 0),
    quantity DECIMAL(20,8) NOT NULL CHECK (quantity > 0),
    
    level BIGINT NOT NULL CHECK (level > 0 AND level <= 20),
    
    PRIMARY KEY (symbol_id, ts, side, level)
);

-- Indexes
CREATE INDEX idx_l2_orderbook_symbol_ts ON l2_orderbook (symbol_id, ts DESC);
CREATE INDEX idx_l2_orderbook_side ON l2_orderbook (side);
CREATE INDEX idx_l2_orderbook_level ON l2_orderbook (level) WHERE level <= 5;

-- Comments
COMMENT ON TABLE l2_orderbook IS 'Level 2 orderbook depth (top 20 levels). 7-day retention due to size.';
COMMENT ON COLUMN l2_orderbook.level IS 'Depth level: 1 = best bid/ask, 20 = worst in top 20.';

\echo '✓ Market data tables created: market_trades, ticks, l1_orderbook, l2_orderbook'