-- ============================================
-- Script: 02_tables/04_trading.sql
-- Description: Trading operations tables (signals, orders, trades, positions)
-- Dependencies: 02_tables/01_core.sql
-- Usage: psql -U postgres -d trading -f 02_tables/04_trading.sql
-- ============================================

\c trading

-- ============================================
-- SIGNAL EVENTS (signals produced by trading engine)
-- ============================================

CREATE TABLE signal_events (
    event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    session_id UUID NOT NULL REFERENCES sessions(session_id),
    strategy_id UUID NOT NULL REFERENCES strategy(id),
    symbol_id UUID NOT NULL REFERENCES symbols(symbol_id),

    -- Signal details
    action TEXT NOT NULL CHECK (action IN ('BUY','SELL','CLOSE')),
    quantity DECIMAL(20,8) NOT NULL,
    price_limit DECIMAL(20,8),

    signal_timestamp TIMESTAMPTZ NOT NULL,

    -- Signal outcome
    event_type TEXT NOT NULL CHECK (event_type IN (
        'SIGNAL_GENERATED',
        'RISK_REJECTED',
        'EXCHANGE_REJECTED',
        'MARKET_CLOSED',
        'INSUFFICIENT_FUNDS',
        'ORDER_PLACED',
        'ORDER_FAILED'
    )),

    -- Risk context
    risk_check_passed BOOLEAN,
    risk_reason TEXT,
    risk_metadata JSONB,

    -- Exchange response
    exchange_response JSONB,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_signal_events_session
ON signal_events(session_id);

CREATE INDEX idx_signal_events_strategy
ON signal_events(strategy_id);

CREATE INDEX idx_signal_events_symbol
ON signal_events(symbol_id);

CREATE INDEX idx_signal_events_type
ON signal_events(event_type);

CREATE INDEX idx_signal_events_timestamp
ON signal_events(signal_timestamp DESC);


-- ============================================
-- ORDERS (order lifecycle)
-- ============================================

CREATE TABLE orders (
    order_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Link to signal
    signal_id UUID NOT NULL REFERENCES signal_events(event_id),

    -- Exchange identifiers
    exchange_order_id TEXT,
    client_order_id TEXT,

    -- Order details
    side side_enum NOT NULL,

    order_type TEXT NOT NULL CHECK (order_type IN (
        'MARKET',
        'LIMIT',
        'STOP_LOSS',
        'STOP_LOSS_LIMIT',
        'TAKE_PROFIT',
        'TAKE_PROFIT_LIMIT',
        'TRAILING_STOP',
        'ICEBERG',
        'POST_ONLY'
    )),

    quantity DECIMAL(20,8) NOT NULL CHECK (quantity > 0),
    filled_quantity DECIMAL(20,8) DEFAULT 0 CHECK (filled_quantity >= 0),

    remaining_quantity DECIMAL(20,8)
    GENERATED ALWAYS AS (quantity - filled_quantity) STORED,

    price DECIMAL(20,8) CHECK (price > 0),
    stop_price DECIMAL(20,8) CHECK (stop_price > 0),
    avg_fill_price DECIMAL(20,8),

    time_in_force TEXT CHECK (time_in_force IN ('GTC','IOC','FOK','GTD','DAY')),
    expire_time TIMESTAMPTZ,

    status TEXT NOT NULL DEFAULT 'PENDING' CHECK (status IN (
        'PENDING',
        'SUBMITTED',
        'ACCEPTED',
        'PARTIALLY_FILLED',
        'FILLED',
        'CANCELLED',
        'REJECTED',
        'EXPIRED'
    )),

    reject_reason TEXT,
    commission DECIMAL(20,8) DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    submitted_at TIMESTAMPTZ,
    filled_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_orders_signal
ON orders(signal_id);

CREATE INDEX idx_orders_status
ON orders(status);

CREATE INDEX idx_orders_side
ON orders(side);

CREATE INDEX idx_orders_exchange_order_id
ON orders(exchange_order_id)
WHERE exchange_order_id IS NOT NULL;

CREATE INDEX idx_orders_client_order_id
ON orders(client_order_id)
WHERE client_order_id IS NOT NULL;

CREATE INDEX idx_orders_created_at
ON orders(created_at DESC);

COMMENT ON TABLE orders IS
'Tracks the complete order lifecycle.';


-- ============================================
-- TRADE EVENTS (order executions / fills)
-- ============================================

CREATE TABLE trade_events (
    trade_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    order_id UUID REFERENCES orders(order_id),

    price DECIMAL(20,8) NOT NULL CHECK (price > 0),
    quantity DECIMAL(20,8) NOT NULL CHECK (quantity > 0),
    fee DECIMAL(20,8) DEFAULT 0,

    exchange_trade_id TEXT,

    ts TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_trade_events_order
ON trade_events(order_id);

CREATE INDEX idx_trade_events_ts
ON trade_events(ts DESC);

CREATE INDEX idx_trade_events_exchange_trade_id
ON trade_events(exchange_trade_id)
WHERE exchange_trade_id IS NOT NULL;

COMMENT ON TABLE trade_events IS
'Individual executions for orders. One order may generate multiple trade events.';


-- ============================================
-- POSITION EVENTS (event sourced positions)
-- ============================================

CREATE TABLE position_events (
    event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    position_id UUID NOT NULL,
    trade_id UUID REFERENCES trade_events(trade_id),

    event_type TEXT CHECK (
        event_type IN ('OPEN','ADD','REDUCE','CLOSE','PRICE_UPDATE')
    ),

    size_delta DECIMAL(20,8),
    price DECIMAL(20,8),
    pnl_delta DECIMAL(20,8),

    event_timestamp TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_position_events_position
ON position_events(position_id);

CREATE INDEX idx_position_events_trade
ON position_events(trade_id);

CREATE INDEX idx_position_events_type
ON position_events(event_type);

CREATE INDEX idx_position_events_ts
ON position_events(event_timestamp DESC);

COMMENT ON TABLE position_events IS
'Event sourced position tracking. Positions are reconstructed from events.';


-- ============================================
-- RISK LIMITS (risk management rules)
-- ============================================

CREATE TABLE risk_limits (
    risk_limit_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    strategy_id UUID REFERENCES strategy(id),
    symbol_id UUID REFERENCES symbols(symbol_id),

    rule TEXT NOT NULL,
    threshold DECIMAL(20,8) NOT NULL,

    scope TEXT CHECK (scope IN ('GLOBAL','STRATEGY','SYMBOL')),

    description TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_risk_limits_strategy
ON risk_limits(strategy_id);

CREATE INDEX idx_risk_limits_symbol
ON risk_limits(symbol_id);

COMMENT ON TABLE risk_limits IS
'Risk management rules enforced by the trading engine.';


\echo '✓ Trading tables created: signal_events, orders, trade_events, position_events, risk_limits'