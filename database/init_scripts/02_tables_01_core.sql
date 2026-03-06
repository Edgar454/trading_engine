-- ============================================
-- Script: 02_tables/01_core.sql
-- Description: Core tables (assets, symbols, strategy, sessions)
-- Dependencies: 01_types.sql
-- Usage: psql -U postgres -d trading -f 02_tables/01_core.sql
-- ============================================

\c trading

-- ============================================
-- ASSETS (broker-agnostic instruments)
-- ============================================

CREATE TABLE assets (
    asset_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Asset identification
    name VARCHAR(100) NOT NULL,
    ticker VARCHAR(20) NOT NULL UNIQUE,
    
    -- Classification
    sector VARCHAR(50),  -- Technology, Banking, Energy, Healthcare, Consumer Goods
    
    -- Metadata
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ
);

-- Indexes
CREATE INDEX idx_assets_sector ON assets(sector) WHERE sector IS NOT NULL;
CREATE INDEX idx_assets_ticker ON assets(ticker);
CREATE INDEX idx_assets_active ON assets(is_active) WHERE is_active = true;

-- Comments
COMMENT ON TABLE assets IS 'Broker-agnostic assets (what to trade). Pure instruments without exchange specificity.';
COMMENT ON COLUMN assets.ticker IS 'Universal ticker symbol (BTC, AAPL, JPM). Unique across all assets.';
COMMENT ON COLUMN assets.sector IS 'Industry sector: Technology, Banking, Energy, Healthcare, etc.';

-- ============================================
-- SYMBOLS (exchange-specific contracts)
-- ============================================

CREATE TABLE symbols (
    symbol_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Link to underlying asset
    asset_id UUID NOT NULL REFERENCES assets(asset_id) ON DELETE CASCADE,
    
    -- Exchange-specific identification
    symbol VARCHAR(30) NOT NULL,
    exchange VARCHAR(20) NOT NULL,
    
    -- Contract type (ENUM)
    contract_type contract_type_enum NOT NULL,
    
    -- Data source
    source VARCHAR(50),
    
    -- Contract-specific details
    expiry_date DATE,
    strike_price DECIMAL(20,8),
    contract_size DECIMAL(20,8) DEFAULT 1,
    
    -- Status
    is_active BOOLEAN DEFAULT true,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ,
    
    -- Constraints
    UNIQUE(symbol, exchange),
    
    CHECK (
        (contract_type IN ('SPOT', 'PERPETUAL') AND expiry_date IS NULL) OR
        (contract_type IN ('FUTURES', 'OPTION') AND expiry_date IS NOT NULL)
    ),
    
    CHECK (
        (contract_type = 'OPTION' AND strike_price IS NOT NULL) OR
        (contract_type != 'OPTION' AND strike_price IS NULL)
    )
);

-- Indexes
CREATE INDEX idx_symbols_asset ON symbols(asset_id);
CREATE INDEX idx_symbols_exchange ON symbols(exchange);
CREATE INDEX idx_symbols_contract_type ON symbols(contract_type);
CREATE INDEX idx_symbols_symbol ON symbols(symbol);
CREATE INDEX idx_symbols_active ON symbols(is_active) WHERE is_active = true;
CREATE INDEX idx_symbols_expiry ON symbols(expiry_date) WHERE expiry_date IS NOT NULL;

-- Comments
COMMENT ON TABLE symbols IS 'Exchange-specific tradeable symbols. Maps broker naming to assets.';
COMMENT ON COLUMN symbols.symbol IS 'Exchange-specific symbol name (BTCUSDT on Binance, BTC-USD on Coinbase)';
COMMENT ON COLUMN symbols.contract_type IS 'Type of contract: SPOT, PERPETUAL, FUTURES, OPTION';
COMMENT ON COLUMN symbols.source IS 'API source for data ingestion (binance_api, coinbase_api, alpaca_api)';
COMMENT ON COLUMN symbols.exchange IS 'Exchange where symbol trades (BINANCE, COINBASE, ALPACA, IB)';

-- ============================================
-- STRATEGY (trading strategy definitions)
-- ============================================

CREATE TABLE strategy (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Strategy identification
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    
    -- Classification
    strategy_type TEXT CHECK (strategy_type IN (
        'MEAN_REVERSION',
        'MOMENTUM',
        'ARBITRAGE',
        'MARKET_MAKING',
        'TREND_FOLLOWING',
        'STATISTICAL_ARBITRAGE',
        'PAIRS_TRADING',
        'CUSTOM'
    )),
    
    -- Status
    status TEXT DEFAULT 'ACTIVE' CHECK (status IN (
        'ACTIVE',
        'PAUSED',
        'ARCHIVED',
        'TESTING'
    )),
    
    -- Version control
    version VARCHAR(20),
    
    -- Parameters (JSONB)
    params JSONB,
    
    -- Metadata
    author TEXT,
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ
);

-- Indexes
CREATE INDEX idx_strategy_status ON strategy(status);
CREATE INDEX idx_strategy_type ON strategy(strategy_type);
CREATE INDEX idx_strategy_name ON strategy(name);
CREATE INDEX idx_strategy_params_gin ON strategy USING GIN (params);

-- Comments
COMMENT ON TABLE strategy IS 'Trading strategy definitions with flexible JSONB parameters.';
COMMENT ON COLUMN strategy.params IS 'Strategy parameters in JSONB format. Example: {"rsi_period": 14, "stop_loss_pct": 0.02}';

-- ============================================
-- SESSIONS (strategy execution instances)
-- ============================================

CREATE TABLE sessions (
    session_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Links
    asset_id UUID NOT NULL REFERENCES assets(asset_id),
    strategy_id UUID REFERENCES strategy(id),
    
    -- Session timing
    start_ts TIMESTAMPTZ DEFAULT NOW(),
    end_ts TIMESTAMPTZ,
    
    -- Performance metrics
    max_drawdown DECIMAL(10, 4),
    total_pnl DECIMAL(20, 8),
    
    -- Status
    status TEXT DEFAULT 'ACTIVE' CHECK (status IN (
        'ACTIVE',
        'PAUSED',
        'COMPLETED'
    )),
    
    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_sessions_asset ON sessions(asset_id);
CREATE INDEX idx_sessions_strategy ON sessions(strategy_id);
CREATE INDEX idx_sessions_status ON sessions(status);
CREATE INDEX idx_sessions_start_ts ON sessions(start_ts DESC);

-- Comments
COMMENT ON TABLE sessions IS 'Strategy execution instances. Operates at ASSET level (broker-agnostic).';
COMMENT ON COLUMN sessions.asset_id IS 'Target asset (e.g., BTC). Strategy decides to trade BTC, not BTCUSDT specifically.';

\echo '✓ Core tables created: assets, symbols, strategy, sessions'