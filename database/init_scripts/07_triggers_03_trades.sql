-- ============================================
-- Script: 07_triggers/03_trades.sql
-- Description: Triggers for trades table
-- Dependencies: 06_functions/02_orders.sql
-- Usage: psql -U postgres -d trading -f 07_triggers/03_trades.sql
-- ============================================

\c trading

-- ============================================
-- TRADES TRIGGERS
-- ============================================

-- Update parent order when trade executes
CREATE TRIGGER trades_update_order
AFTER INSERT ON trades
FOR EACH ROW EXECUTE FUNCTION update_order_on_trade();

\echo '✓ Trigger created: trades_update_order'