-- ============================================
-- Script: 07_triggers/01_core_tables.sql
-- Description: Triggers for core tables (assets, symbols, strategy)
-- Dependencies: 06_functions/01_utilities.sql
-- Usage: psql -U postgres -d trading -f 07_triggers/01_core_tables.sql
-- ============================================

\c trading

-- ============================================
-- CORE TABLES TRIGGERS
-- ============================================

-- Assets
CREATE TRIGGER assets_updated_at
BEFORE UPDATE ON assets
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Symbols
CREATE TRIGGER symbols_updated_at
BEFORE UPDATE ON symbols
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Strategy
CREATE TRIGGER strategy_updated_at
BEFORE UPDATE ON strategy
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

\echo '✓ Triggers created for: assets, symbols, strategy'