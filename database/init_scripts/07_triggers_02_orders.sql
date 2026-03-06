-- ============================================
-- Script: 07_triggers/02_orders.sql
-- Description: Triggers for orders table
-- Dependencies: 06_functions/02_orders.sql
-- Usage: psql -U postgres -d trading -f 07_triggers/02_orders.sql
-- ============================================

\c trading

-- ============================================
-- ORDERS TRIGGERS
-- ============================================

-- Update remaining quantity and status
CREATE TRIGGER orders_update_remaining
BEFORE INSERT OR UPDATE OF filled_quantity ON orders
FOR EACH ROW EXECUTE FUNCTION update_order_remaining_quantity();

\echo '✓ Trigger created: orders_update_remaining'