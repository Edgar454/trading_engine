-- ============================================
-- Script: 06_functions/03_positions.sql
-- Description: Functions for positions table logic
-- Dependencies: 02_tables/04_trading.sql
-- Usage: psql -U postgres -d trading -f 06_functions/03_positions.sql
-- ============================================

\c trading

-- ============================================
-- UPDATE POSITION UNREALIZED PNL
-- ============================================

CREATE OR REPLACE FUNCTION update_position_unrealized_pnl()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.current_price IS NOT NULL AND NEW.status = 'OPEN' THEN
        -- Calculate unrealized PnL
        -- LONG: (current_price - avg_price) * size
        -- SHORT: (avg_price - current_price) * size
        NEW.unrealized_pnl = CASE
            WHEN NEW.side = 'LONG' THEN (NEW.current_price - NEW.avg_price) * NEW.size
            WHEN NEW.side = 'SHORT' THEN (NEW.avg_price - NEW.current_price) * NEW.size
        END;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_position_unrealized_pnl IS 'Auto-calculates unrealized_pnl when current_price is updated. LONG: (current - avg) * size, SHORT: (avg - current) * size.';

\echo '✓ Function created: update_position_unrealized_pnl'