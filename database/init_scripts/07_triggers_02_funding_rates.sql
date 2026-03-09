-- ============================================
-- Script: 07_triggers/05_funding_rates.sql
-- Description: Triggers for funding_rates table
-- Dependencies: 06_functions/04_validations.sql
-- Usage: psql -U postgres -d trading -f 07_triggers/05_funding_rates.sql
-- ============================================

\c trading

-- ============================================
-- FUNDING RATES TRIGGERS
-- ============================================

-- Ensure only perpetual contracts
CREATE TRIGGER funding_rates_perpetual_check
BEFORE INSERT OR UPDATE ON funding_rates
FOR EACH ROW EXECUTE FUNCTION check_funding_rates_perpetual();

\echo '✓ Trigger created: funding_rates_perpetual_check'