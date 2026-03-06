-- ============================================
-- Script: 00_database.sql
-- Description: Create trading database and enable extensions
-- Dependencies: None (run as postgres superuser)
-- Usage: psql -U postgres -f 00_database.sql
-- ============================================

-- ============================================
-- EXTENSIONS
-- ============================================

CREATE EXTENSION IF NOT EXISTS timescaledb;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Verify extensions
\dx

\echo '✓ Database "trading" created successfully'
\echo '✓ Extensions enabled: timescaledb, uuid-ossp'