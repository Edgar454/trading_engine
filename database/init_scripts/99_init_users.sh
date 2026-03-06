#!/bin/bash
# ============================================
# init_users.sh
# ============================================
# Description: Update user passwords from environment variables
# Run order: AFTER init_database.sql, init_rbac.sql, seed_assets.sql
# Prerequisites: Users must exist (created by init_rbac.sql)
# ============================================

set -e  # Exit on error

echo "============================================"
echo "Updating user passwords from environment..."
echo "============================================"

# Check required environment variables
REQUIRED_VARS=(
    "ADMIN_PASSWORD"
)

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo "ERROR: Environment variable $var is not set!"
        exit 1
    fi
done

# Connect to database and update passwords
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "trading" <<-EOSQL
    -- Update admin user
    ALTER USER edgar WITH PASSWORD '$ADMIN_PASSWORD';

    
    -- Verify users exist
    SELECT 
        usename as username,
        CASE 
            WHEN usename = 'edgar' THEN 'admin (edgar)'
            WHEN usename = 'nifi_user' THEN 'ingestion_services (nifi_user)'
            WHEN usename = 'dbt_user' THEN 'analytics_services (dbt_user)'
            WHEN usename = 'trading_engine' THEN 'trading_engine_services (trading_engine)'
        END as role_description,
        valuntil as password_expiry
    FROM pg_user 
    WHERE usename IN ('edgar', 'nifi_user', 'dbt_user', 'trading_engine')
    ORDER BY usename;
EOSQL

echo ""
echo "============================================"
echo "User passwords updated successfully!"
echo "============================================"
echo ""
echo "Users configured:"
echo "  ✓ edgar (admin)"
echo "  ✓ nifi_user (ingestion_services)"
echo "  ✓ dbt_user (analytics_services)"
echo "  ✓ trading_engine (trading_engine_services)"
echo ""
echo "Database ready for use!"
echo "============================================"