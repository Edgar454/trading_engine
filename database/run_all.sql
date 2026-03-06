-- ============================================
-- Script: run_all.sql
-- Description: Master orchestrator - runs all setup scripts in order
-- Dependencies: None
-- Usage: psql -U postgres -f run_all.sql
-- ============================================

\echo ''
\echo '============================================'
\echo 'TRADING ANALYTICS PLATFORM - DATABASE SETUP'
\echo '============================================'
\echo ''

\timing on

-- 00: Database and extensions
\echo '>>> Running: 00_database.sql'
\i 00_database.sql

-- 01: Types
\echo ''
\echo '>>> Running: 01_types.sql'
\i 01_types.sql

-- 02: Tables
\echo ''
\echo '>>> Running: 02_tables/01_core.sql'
\i 02_tables/01_core.sql

\echo ''
\echo '>>> Running: 02_tables/02_market_data.sql'
\i 02_tables/02_market_data.sql

\echo ''
\echo '>>> Running: 02_tables/03_derivatives.sql'
\i 02_tables/03_derivatives.sql

\echo ''
\echo '>>> Running: 02_tables/04_trading.sql'
\i 02_tables/04_trading.sql

-- 03: Hypertables
\echo ''
\echo '>>> Running: 03_hypertables.sql'
\i 03_hypertables.sql

-- 04: Continuous aggregates
\echo ''
\echo '>>> Running: 04_continuous_aggregates/01_candles.sql'
\i 04_continuous_aggregates/01_candles.sql

\echo ''
\echo '>>> Running: 04_continuous_aggregates/02_l2_metrics.sql'
\i 04_continuous_aggregates/02_l2_metrics.sql

-- 05: Views
\echo ''
\echo '>>> Running: 05_views/01_market_regimes.sql'
\i 05_views/01_market_regimes.sql

\echo ''
\echo '>>> Running: 05_views/02_summary_views.sql'
\i 05_views/02_summary_views.sql

-- 06: Functions
\echo ''
\echo '>>> Running: 06_functions/01_utilities.sql'
\i 06_functions/01_utilities.sql

\echo ''
\echo '>>> Running: 06_functions/02_orders.sql'
\i 06_functions/02_orders.sql

\echo ''
\echo '>>> Running: 06_functions/03_positions.sql'
\i 06_functions/03_positions.sql

\echo ''
\echo '>>> Running: 06_functions/04_validations.sql'
\i 06_functions/04_validations.sql

-- 07: Triggers
\echo ''
\echo '>>> Running: 07_triggers/01_core_tables.sql'
\i 07_triggers/01_core_tables.sql

\echo ''
\echo '>>> Running: 07_triggers/02_orders.sql'
\i 07_triggers/02_orders.sql

\echo ''
\echo '>>> Running: 07_triggers/03_trades.sql'
\i 07_triggers/03_trades.sql

\echo ''
\echo '>>> Running: 07_triggers/04_positions.sql'
\i 07_triggers/04_positions.sql

\echo ''
\echo '>>> Running: 07_triggers/05_funding_rates.sql'
\i 07_triggers/05_funding_rates.sql

-- 08: Policies
\echo ''
\echo '>>> Running: 08_policies/01_retention.sql'
\i 08_policies/01_retention.sql

\echo ''
\echo '>>> Running: 08_policies/02_compression.sql'
\i 08_policies/02_compression.sql

\echo ''
\echo '>>> Running: 08_policies/03_continuous_agg_refresh.sql'
\i 08_policies/03_continuous_agg_refresh.sql

-- 99: Validation
\echo ''
\echo '>>> Running: 99_validate.sql'
\i 99_validate.sql

\timing off

\echo ''
\echo '============================================'
\echo '✓ DATABASE SETUP COMPLETE'
\echo '============================================'
\echo ''
\echo 'Next steps:'
\echo '1. Run init_rbac.sql to setup roles and users'
\echo '2. Run seed_assets.sql to populate initial data'
\echo ''