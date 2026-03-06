-- ============================================
-- Script: 06_functions/01_utilities.sql
-- Description: Utility functions (update timestamps)
-- Dependencies: None
-- Usage: psql -U postgres -d trading -f 06_functions/01_utilities.sql
-- ============================================

\c trading

-- ============================================
-- AUTO-UPDATE updated_at COLUMN
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_updated_at_column IS 'Automatically updates updated_at column on row update.';

\echo '✓ Function created: update_updated_at_column'