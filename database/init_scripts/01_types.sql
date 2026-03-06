-- ============================================
-- Script: 01_types.sql
-- Description: Create custom types (ENUMs)
-- Dependencies: 00_database.sql
-- Usage: psql -U postgres -d trading -f 01_types.sql
-- ============================================

\c trading

-- ============================================
-- ENUMS (stable values that rarely change)
-- ============================================

-- Trading side (BUY/SELL)
CREATE TYPE side_enum AS ENUM ('BUY', 'SELL');

-- Contract types
CREATE TYPE contract_type_enum AS ENUM (
    'SPOT',        -- Spot trading (immediate settlement)
    'PERPETUAL',   -- Perpetual futures (no expiry, funding rate)
    'FUTURES',     -- Dated futures (with expiry)
    'OPTION'       -- Options contracts
);

-- Comments
COMMENT ON TYPE side_enum IS 'Trading direction: BUY (long) or SELL (short)';
COMMENT ON TYPE contract_type_enum IS 'Contract instrument types. Stable values that rarely change.';

-- Verify types created
SELECT 
    t.typname AS enum_name,
    e.enumlabel AS enum_value
FROM pg_type t
JOIN pg_enum e ON t.oid = e.enumtypid
WHERE t.typname IN ('side_enum', 'contract_type_enum')
ORDER BY t.typname, e.enumsortorder;

\echo '✓ Custom types created: side_enum, contract_type_enum'