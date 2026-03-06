-- ============================================
-- Script: 06_functions/02_orders.sql
-- Description: Functions for orders table logic
-- Dependencies: 02_tables/04_trading.sql
-- Usage: psql -U postgres -d trading -f 06_functions/02_orders.sql
-- ============================================

\c trading

-- ============================================
-- UPDATE ORDER REMAINING QUANTITY
-- ============================================

CREATE OR REPLACE FUNCTION update_order_remaining_quantity()
RETURNS TRIGGER AS $$
BEGIN
    -- Update remaining quantity
    NEW.remaining_quantity = NEW.quantity - NEW.filled_quantity;
    
    -- Auto-update status based on filled quantity
    IF NEW.filled_quantity = 0 AND NEW.status NOT IN ('CANCELLED', 'REJECTED', 'EXPIRED') THEN
        -- No fills yet, keep current status
        NULL;
    ELSIF NEW.filled_quantity > 0 AND NEW.filled_quantity < NEW.quantity THEN
        NEW.status = 'PARTIALLY_FILLED';
    ELSIF NEW.filled_quantity >= NEW.quantity THEN
        NEW.status = 'FILLED';
        NEW.filled_at = COALESCE(NEW.filled_at, NOW());
    END IF;
    
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_order_remaining_quantity IS 'Auto-updates remaining_quantity and status when filled_quantity changes.';

-- ============================================
-- UPDATE ORDER ON TRADE EXECUTION
-- ============================================

CREATE OR REPLACE FUNCTION update_order_on_trade()
RETURNS TRIGGER AS $$
DECLARE
    order_qty DECIMAL(20,8);
    order_filled DECIMAL(20,8);
BEGIN
    -- Only update if order_id is not NULL
    IF NEW.order_id IS NULL THEN
        RETURN NEW;
    END IF;
    
    -- Get current order state
    SELECT quantity, filled_quantity INTO order_qty, order_filled
    FROM orders
    WHERE order_id = NEW.order_id;
    
    -- Update parent order
    UPDATE orders
    SET 
        filled_quantity = order_filled + NEW.quantity,
        
        -- Update weighted average fill price
        avg_fill_price = CASE
            WHEN order_filled = 0 THEN NEW.price
            ELSE (COALESCE(avg_fill_price, 0) * order_filled + NEW.price * NEW.quantity) / (order_filled + NEW.quantity)
        END,
        
        -- Add commission
        commission = commission + NEW.fee,
        
        updated_at = NOW()
        
    WHERE order_id = NEW.order_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_order_on_trade IS 'Updates parent order when trade executes: increments filled_quantity, updates avg_fill_price (weighted), adds commission.';

\echo '✓ Functions created: update_order_remaining_quantity, update_order_on_trade'