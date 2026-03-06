-- ============================================
-- Script: 05_views/02_summary_views.sql
-- Description: Helper views for common queries
-- Dependencies: 02_tables/*.sql
-- Usage: psql -U postgres -d trading -f 05_views/02_summary_views.sql
-- ============================================

\c trading

-- ============================================
-- OPEN POSITIONS SUMMARY
-- ============================================

CREATE VIEW open_positions_summary AS
SELECT 
    p.position_id,
    p.session_id,
    a.ticker AS asset_ticker,
    a.name AS asset_name,
    s.symbol,
    s.exchange,
    p.side,
    p.size,
    p.avg_price,
    p.current_price,
    p.unrealized_pnl,
    p.realized_pnl,
    p.entry_ts,
    
    -- Calculated fields
    p.size * p.avg_price AS position_value,
    
    CASE 
        WHEN p.side = 'LONG' THEN ((p.current_price - p.avg_price) / p.avg_price) * 100
        WHEN p.side = 'SHORT' THEN ((p.avg_price - p.current_price) / p.avg_price) * 100
    END AS pnl_pct
    
FROM positions p
JOIN assets a ON p.asset_id = a.asset_id
LEFT JOIN symbols s ON p.symbol_id = s.symbol_id
WHERE p.status = 'OPEN'
ORDER BY p.entry_ts DESC;

COMMENT ON VIEW open_positions_summary IS 'Summary of open positions with calculated PnL percentage and position value.';

-- ============================================
-- PENDING ORDERS SUMMARY
-- ============================================

CREATE VIEW pending_orders_summary AS
SELECT 
    o.order_id,
    o.session_id,
    s.symbol,
    s.exchange,
    a.ticker AS asset_ticker,
    o.side,
    o.order_type,
    o.quantity,
    o.filled_quantity,
    o.remaining_quantity,
    o.price,
    o.stop_price,
    o.status,
    o.time_in_force,
    o.created_at,
    o.broker
FROM orders o
JOIN symbols s ON o.symbol_id = s.symbol_id
JOIN assets a ON s.asset_id = a.asset_id
WHERE o.status IN ('PENDING', 'SUBMITTED', 'ACCEPTED', 'PARTIALLY_FILLED')
ORDER BY o.created_at DESC;

COMMENT ON VIEW pending_orders_summary IS 'Active orders (pending, submitted, accepted, partially filled) with symbol and asset details.';

-- ============================================
-- TRADES SUMMARY
-- ============================================

CREATE VIEW trades_summary AS
SELECT 
    t.trade_id,
    t.session_id,
    s.symbol,
    s.exchange,
    a.ticker AS asset_ticker,
    t.side,
    t.price,
    t.quantity,
    t.fee,
    t.price * t.quantity AS trade_value,
    t.broker,
    t.ts,
    o.order_type,
    o.client_order_id
FROM trades t
JOIN symbols s ON t.symbol_id = s.symbol_id
JOIN assets a ON s.asset_id = a.asset_id
LEFT JOIN orders o ON t.order_id = o.order_id
ORDER BY t.ts DESC;

COMMENT ON VIEW trades_summary IS 'Executed trades with calculated trade value and linked order details.';

\echo '✓ Views created: open_positions_summary, pending_orders_summary, trades_summary, candles'