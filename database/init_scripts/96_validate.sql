-- ============================================
-- Script: 99_validate.sql
-- Description: Validation queries to verify setup
-- Dependencies: All previous scripts
-- Usage: psql -U postgres -d trading -f 99_validate.sql
-- ============================================

\c trading

\echo ''
\echo '============================================'
\echo 'DATABASE SCHEMA VALIDATION'
\echo '============================================'
\echo ''

-- Check extensions
\echo '--- Extensions ---'
SELECT extname, extversion FROM pg_extension WHERE extname IN ('timescaledb', 'uuid-ossp');

\echo ''
\echo '--- Custom Types ---'
SELECT DISTINCT typname FROM pg_type WHERE typname IN ('side_enum', 'contract_type_enum');

\echo ''
\echo '--- Tables ---'
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

\echo ''
\echo '--- Hypertables ---'
SELECT 
    hypertable_schema,
    hypertable_name,
    num_dimensions,
    num_chunks
FROM timescaledb_information.hypertables
WHERE hypertable_schema = 'public'
ORDER BY hypertable_name;

\echo ''
\echo '--- Continuous Aggregates ---'
SELECT 
    view_name,
    materialization_hypertable_name
FROM timescaledb_information.continuous_aggregates
ORDER BY view_name;

\echo ''
\echo '--- Views ---'
SELECT 
    schemaname,
    viewname
FROM pg_views
WHERE schemaname = 'public'
ORDER BY viewname;

\echo ''
\echo '--- Functions ---'
SELECT 
    proname AS function_name,
    pg_get_function_arguments(oid) AS arguments
FROM pg_proc
WHERE pronamespace = 'public'::regnamespace
ORDER BY proname;

\echo ''
\echo '--- Triggers ---'
SELECT 
    trigger_name,
    event_object_table AS table_name,
    event_manipulation AS event
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY event_object_table, trigger_name;

\echo ''
\echo '--- Retention Policies ---'
SELECT 
    hypertable_name,
    job_id,
    (config->>'drop_after')::interval AS retention_period
FROM timescaledb_information.jobs
WHERE proc_name = 'policy_retention'
ORDER BY hypertable_name;

\echo ''
\echo '--- Compression Policies ---'
SELECT 
    hypertable_name,
    job_id,
    (config->>'compress_after')::interval AS compress_after
FROM timescaledb_information.jobs
WHERE proc_name = 'policy_compression'
ORDER BY hypertable_name;

\echo ''
\echo '--- Continuous Aggregate Refresh Policies ---'
SELECT 
    ca.view_name,
    j.job_id,
    (j.config->>'start_offset')::interval AS start_offset,
    (j.config->>'end_offset')::interval AS end_offset,
    (j.config->>'schedule_interval')::interval AS schedule_interval
FROM timescaledb_information.jobs j
JOIN timescaledb_information.continuous_aggregates ca 
    ON j.hypertable_name = ca.materialization_hypertable_name
WHERE j.proc_name = 'policy_refresh_continuous_aggregate'
ORDER BY ca.view_name;

\echo ''
\echo '============================================'
\echo '✓ VALIDATION COMPLETE'
\echo '============================================'