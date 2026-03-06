-- ============================================
-- Script: 07_triggers/04_positions.sql
-- Description: Triggers for positions table
-- Dependencies: 06_functions/01_utilities.sql, 06_functions/03_positions.sql
-- Usage: psql -U postgres -d trading -f 07_triggers/04_positions.sql
-- ============================================

\c trading

-- ============================================
-- POSITIONS TRIGGERS
-- ============================================

-- Auto-update updated_at
CREATE TRIGGER positions_updated_at
BEFORE UPDATE ON positions
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Auto-calculate unrealized PnL
CREATE TRIGGER positions_update_pnl
BEFORE INSERT OR UPDATE OF current_price ON positions
FOR EACH ROW EXECUTE FUNCTION update_position_unrealized_pnl();

\echo '✓ Triggers created: positions_updated_at, positions_update_pnl'