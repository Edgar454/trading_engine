-- ============================================
-- Script: 98_init_rbac.sql
-- Description: Setup roles and users with least-privilege access
-- Dependencies: All table/view/function creation scripts
-- Executed by: docker-entrypoint-initdb.d (or manual)
-- ============================================

\echo ''
\echo '============================================'
\echo 'RBAC SETUP - ROLES AND USERS'
\echo '============================================'
\echo ''

-- ============================================
-- ROLE 1: ADMIN (full privileges)
-- ============================================

CREATE ROLE admin NOLOGIN ;

-- Limit concurrent admin connections
ALTER ROLE admin CONNECTION LIMIT 3;

-- Set statement timeout for admin sessions
ALTER ROLE admin SET statement_timeout = '5min';

-- Create admin user
CREATE USER edgar WITH PASSWORD 'CHANGE_ME_SECURE_PASSWORD';
GRANT admin TO edgar;

-- Grant ALL privileges
GRANT ALL PRIVILEGES ON DATABASE trading TO admin;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO admin;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO admin;

-- Future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO admin;

\echo '✓ Role: admin'
\echo '  User: edgar'
\echo '  Access: ALL PRIVILEGES (full database access)'

-- ============================================
-- ROLE 2: INGESTION_SERVICES (NiFi)
-- ============================================

CREATE ROLE ingestion_services NOLOGIN ;

-- Create user
CREATE USER nifi_user LOGIN;
GRANT ingestion_services TO nifi_user;

-- Database access
GRANT CONNECT ON DATABASE trading TO ingestion_services;
GRANT USAGE ON SCHEMA public TO ingestion_services;

-- ============================================
-- WRITE permissions (market data ONLY)
-- ============================================
--core tables
GRANT SELECT, INSERT, UPDATE ON TABLE symbols TO ingestion_services;

-- Market trades (raw data from exchanges)
GRANT SELECT, INSERT, UPDATE ON TABLE market_trades TO ingestion_services;
GRANT SELECT, INSERT, UPDATE ON TABLE ticks TO ingestion_services;
GRANT SELECT, INSERT, UPDATE ON TABLE candles TO ingestion_services;

-- Orderbook data
GRANT SELECT, INSERT, UPDATE ON TABLE l1_orderbook TO ingestion_services;
GRANT SELECT, INSERT, UPDATE ON TABLE l2_orderbook TO ingestion_services;

-- Derivatives data
GRANT SELECT, INSERT, UPDATE ON TABLE funding_rates TO ingestion_services;
GRANT SELECT, INSERT, UPDATE ON TABLE open_interests TO ingestion_services;
GRANT SELECT, INSERT, UPDATE ON TABLE liquidations TO ingestion_services;

-- ============================================
-- READ permissions (for validation/mapping)
-- ============================================

-- Reference tables (needed for symbol_id lookup)
GRANT SELECT ON TABLE assets TO ingestion_services;
GRANT SELECT ON TABLE symbols TO ingestion_services;

-- Sequences
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO ingestion_services;

\echo ''
\echo '✓ Role: ingestion_services'
\echo '  User: nifi_user'
\echo '  WRITE access:'
\echo '    - symbols'
\echo '    - market_trades, ticks'
\echo '    - l1_orderbook, l2_orderbook'
\echo '    - funding_rates, open_interests, liquidations'
\echo '  READ access:'
\echo '    - assets, symbols (for validation only)'
\echo '  NO access to business tables (orders, trades, positions, sessions, strategy)'

-- ============================================
-- ROLE 3: ANALYTICS_SERVICES (DBT → DuckDB)
-- ============================================

CREATE ROLE analytics_services NOLOGIN;

-- Create user
CREATE USER dbt_user LOGIN;
GRANT analytics_services TO dbt_user;

-- Database access
GRANT CONNECT ON DATABASE trading TO analytics_services;
GRANT USAGE ON SCHEMA public TO analytics_services;

-- READ ONLY on ALL tables (for extraction to DuckDB)
GRANT SELECT ON ALL TABLES IN SCHEMA public TO analytics_services;

-- READ ONLY on ALL materialized views
GRANT SELECT ON candles_enriched TO analytics_services;
GRANT SELECT ON l2_metrics TO analytics_services;
GRANT SELECT ON market_regimes TO analytics_services;


-- Future tables (read-only)
ALTER DEFAULT PRIVILEGES IN SCHEMA public 
    GRANT SELECT ON TABLES TO analytics_services;

\echo ''
\echo '✓ Role: analytics_services'
\echo '  User: dbt_user'
\echo '  READ access: ALL tables and views (for DuckDB extraction)'
\echo '  NO WRITE/UPDATE/DELETE permissions'

-- ============================================
-- ROLE 4: TRADING_ENGINE_SERVICES (optional)
-- ============================================

CREATE ROLE trading_engine_services NOLOGIN;

-- Create user
CREATE USER trading_engine LOGIN;
GRANT trading_engine_services TO trading_engine;

-- Database access
GRANT CONNECT ON DATABASE trading TO trading_engine_services;
GRANT USAGE ON SCHEMA public TO trading_engine_services;

-- ============================================
-- READ permissions (market data for decisions)
-- ============================================

-- Reference tables
GRANT SELECT ON TABLE assets TO trading_engine_services;
GRANT SELECT ON TABLE symbols TO trading_engine_services;
GRANT SELECT ON TABLE strategy TO trading_engine_services;

-- Market data
GRANT SELECT ON TABLE market_trades TO trading_engine_services;
GRANT SELECT ON TABLE ticks TO trading_engine_services;
GRANT SELECT ON TABLE candles TO trading_engine_services;
GRANT SELECT ON TABLE l1_orderbook TO trading_engine_services;
GRANT SELECT ON TABLE l2_orderbook TO trading_engine_services;

-- Derivatives data
GRANT SELECT ON TABLE funding_rates TO trading_engine_services;
GRANT SELECT ON TABLE open_interests TO trading_engine_services;
GRANT SELECT ON TABLE liquidations TO trading_engine_services;



-- Views
GRANT SELECT ON market_regimes TO trading_engine_services;
GRANT SELECT ON candles_enriched TO trading_engine_services;
GRANT SELECT ON l2_metrics TO trading_engine_services;


-- ============================================
-- WRITE permissions (trading operations)
-- ============================================

-- Business tables (trading operations)
GRANT INSERT, UPDATE, DELETE ON TABLE sessions TO trading_engine_services;
GRANT INSERT, UPDATE, DELETE ON TABLE orders TO trading_engine_services;
GRANT INSERT, UPDATE, DELETE ON TABLE trade_events TO trading_engine_services;
GRANT INSERT, UPDATE, DELETE ON TABLE position_events TO trading_engine_services;

-- Sequences
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO trading_engine_services;

\echo ''
\echo '✓ Role: trading_engine_services'
\echo '  User: trading_engine'
\echo '  READ access:'
\echo '    - assets, symbols, strategy'
\echo '    - market_trades, orderbooks, derivatives'
\echo '    - candles, market_regimes (all views)'
\echo '  WRITE access:'
\echo '    - sessions, orders, trades, positions'

-- ============================================
-- ROLE 5: Postgres Monitor (optional)
-- ============================================
CREATE USER postgres_exporter;
GRANT pg_monitor, pg_read_all_stats  TO postgres_exporter;


GRANT CONNECT ON DATABASE trading TO postgres_exporter;
GRANT CONNECT ON DATABASE postgres TO postgres_exporter;

-- Also grant usage on the schemas
\c postgres
GRANT USAGE ON SCHEMA public TO postgres_exporter;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO postgres_exporter;
ALTER DEFAULT PRIVILEGES IN SCHEMA public 
    GRANT SELECT ON TABLES TO postgres_exporter;

\c trading
GRANT USAGE ON SCHEMA public TO postgres_exporter;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO postgres_exporter;
ALTER DEFAULT PRIVILEGES IN SCHEMA public 
    GRANT SELECT ON TABLES TO postgres_exporter;

-- ============================================
-- SUMMARY
-- ============================================

\echo ''
\echo '============================================'
\echo '✓ RBAC SETUP COMPLETE'
\echo '============================================'
\echo ''
\echo 'Roles and users created:'
\echo ''
\echo '  1. admin (user: edgar)'
\echo '     → ALL PRIVILEGES'
\echo ''
\echo '  2. ingestion_services (user: nifi_user)'
\echo '     → WRITE: market data tables only'
\echo '     → READ: assets, symbols (validation)'
\echo '     → NO ACCESS: business tables'
\echo ''
\echo '  3. analytics_services (user: dbt_user)'
\echo '     → READ: everything (extract to DuckDB)'
\echo '     → NO WRITE permissions'
\echo ''
\echo '  4. trading_engine_services (user: trading_engine)'
\echo '     → READ: market data, candles, views'
\echo '     → WRITE: trading operations only'
\echo ''
\echo '============================================'
\echo '⚠️  SECURITY WARNING'
\echo '============================================'
\echo ''
\echo 'No passwords are needed. Any connection needs a valid certificate (SSL/TLS) and the correct username. This is more secure than password-based auth.'
\echo ''
\echo '============================================'
\echo 'Next step: Run 99_seed_assets.sql'
\echo '============================================'
\echo ''