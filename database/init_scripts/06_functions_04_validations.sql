-- ============================================
-- Script: 06_functions/04_validations.sql
-- Description: Validation functions (constraints)
-- Dependencies: 02_tables/03_derivatives.sql
-- Usage: psql -U postgres -d trading -f 06_functions/04_validations.sql
-- ============================================

\c trading

-- ============================================
-- CHECK FUNDING RATES PERPETUAL ONLY
-- ============================================

CREATE OR REPLACE FUNCTION check_funding_rates_perpetual()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM symbols 
        WHERE symbol_id = NEW.symbol_id 
        AND contract_type = 'PERPETUAL'
    ) THEN
        RAISE EXCEPTION 'Funding rates only apply to PERPETUAL contracts (symbol_id: %)', NEW.symbol_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION check_funding_rates_perpetual IS 'Ensures only perpetual contracts can have funding rates.';

\echo '✓ Function created: check_funding_rates_perpetual'