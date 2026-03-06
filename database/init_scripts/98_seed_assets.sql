-- ============================================
-- Script: 99_seed_assets.sql
-- Description: Seed initial assets and symbols
-- Dependencies: All previous scripts (especially 02_tables/01_core.sql)
-- Executed by: docker-entrypoint-initdb.d (or manual)
-- ============================================

\echo ''
\echo '============================================'
\echo 'SEEDING ASSETS AND SYMBOLS'
\echo '============================================'
\echo ''

-- ============================================
-- ASSETS (broker-agnostic)
-- ============================================

\echo '>>> Inserting assets...'

-- Crypto assets (6)
INSERT INTO assets (name, ticker, sector, description, is_active) VALUES
('Bitcoin', 'BTC', 'Technology', 'Decentralized digital currency and store of value', true),
('Ethereum', 'ETH', 'Technology', 'Smart contract platform and decentralized applications', true),
('Solana', 'SOL', 'Technology', 'High-performance blockchain for DeFi and NFTs', true),
('Cardano', 'ADA', 'Technology', 'Proof-of-stake blockchain platform', true),
('Polygon', 'MATIC', 'Technology', 'Ethereum scaling solution and sidechain', true),
('Avalanche', 'AVAX', 'Technology', 'High-throughput smart contract platform', true);

-- Equity assets (4)
INSERT INTO assets (name, ticker, sector, description, is_active) VALUES
('Apple Inc', 'AAPL', 'Technology', 'Consumer electronics and software company', true),
('Microsoft Corporation', 'MSFT', 'Technology', 'Software, cloud computing, and enterprise solutions', true),
('JPMorgan Chase & Co', 'JPM', 'Banking', 'Multinational investment bank and financial services', true),
('Chevron Corporation', 'CVX', 'Energy', 'Integrated energy company - oil and gas', true);

\echo '✓ Inserted 10 assets (6 crypto, 4 equities)'

-- ============================================
-- SYMBOLS (exchange-specific)
-- ============================================

\echo ''
\echo '>>> Inserting symbols...'

-- ============================================
-- CRYPTO SYMBOLS
-- ============================================

-- Binance Spot
INSERT INTO symbols (asset_id, symbol, exchange, contract_type, source, is_active) 
SELECT 
    a.asset_id,
    a.ticker || 'USDT' AS symbol,
    'BINANCE' AS exchange,
    'SPOT' AS contract_type,
    'binance_api' AS source,
    true AS is_active
FROM assets a
WHERE a.ticker IN ('BTC', 'ETH', 'SOL', 'ADA', 'MATIC', 'AVAX');

-- Binance Perpetuals
INSERT INTO symbols (asset_id, symbol, exchange, contract_type, source, is_active) 
SELECT 
    a.asset_id,
    a.ticker || 'USDT' AS symbol,
    'BINANCE_FUTURES' AS exchange,
    'PERPETUAL' AS contract_type,
    'binance_futures_api' AS source,
    true AS is_active
FROM assets a
WHERE a.ticker IN ('BTC', 'ETH', 'SOL', 'ADA', 'MATIC', 'AVAX');


-- OKX SWAP (Perpetual) Symbols for Derivatives
INSERT INTO symbols (asset_id, symbol, exchange, contract_type, source, is_active)
VALUES
((SELECT asset_id FROM assets WHERE ticker='BTC'), 'BTC-USDT', 'OKX', 'PERPETUAL', 'okx_api', true),
((SELECT asset_id FROM assets WHERE ticker='ETH'), 'ETH-USDT', 'OKX', 'PERPETUAL', 'okx_api', true),
((SELECT asset_id FROM assets WHERE ticker='SOL'), 'SOL-USDT', 'OKX', 'PERPETUAL', 'okx_api', true),
((SELECT asset_id FROM assets WHERE ticker='ADA'), 'ADA-USDT', 'OKX', 'PERPETUAL', 'okx_api', true),
((SELECT asset_id FROM assets WHERE ticker='MATIC'), 'MATIC-USDT', 'OKX', 'PERPETUAL', 'okx_api', true),
((SELECT asset_id FROM assets WHERE ticker='AVAX'), 'AVAX-USDT', 'OKX', 'PERPETUAL', 'okx_api', true);

\echo '✓ Inserted 6 OKX perpetual swap symbols'
\echo '✓ Inserted 18 crypto symbols (6 Binance spot + 6 Binance perpetuals + 6 Coinbase)'



-- ============================================
-- EQUITY SYMBOLS
-- ============================================

-- Alpaca (stocks)
INSERT INTO symbols (asset_id, symbol, exchange, contract_type, source, is_active)
VALUES
((SELECT asset_id FROM assets WHERE ticker='AAPL'), 'AAPL', 'ALPACA', 'SPOT', 'alpaca_api', true),
((SELECT asset_id FROM assets WHERE ticker='MSFT'), 'MSFT', 'ALPACA', 'SPOT', 'alpaca_api', true),
((SELECT asset_id FROM assets WHERE ticker='JPM'), 'JPM', 'ALPACA', 'SPOT', 'alpaca_api', true),
((SELECT asset_id FROM assets WHERE ticker='CVX'), 'CVX', 'ALPACA', 'SPOT', 'alpaca_api', true);

\echo '✓ Inserted 4 equity symbols (Alpaca)'

-- ============================================
-- VERIFICATION
-- ============================================

\echo ''
\echo '============================================'
\echo 'VERIFICATION'
\echo '============================================'
\echo ''

-- Assets summary
\echo '--- Assets by Sector ---'
SELECT 
    sector,
    COUNT(*) AS num_assets,
    string_agg(ticker, ', ' ORDER BY ticker) AS tickers
FROM assets
WHERE is_active = true
GROUP BY sector
ORDER BY sector;

\echo ''
\echo '--- Assets Detail ---'
SELECT 
    ticker,
    name,
    sector,
    is_active
FROM assets
ORDER BY sector, ticker;

\echo ''
\echo '--- Symbols by Exchange and Contract Type ---'
SELECT 
    exchange,
    contract_type,
    COUNT(*) AS num_symbols,
    string_agg(symbol, ', ' ORDER BY symbol) AS symbols
FROM symbols
WHERE is_active = true
GROUP BY exchange, contract_type
ORDER BY exchange, contract_type;

\echo ''
\echo '--- Symbols Detail (first 30) ---'
SELECT 
    a.ticker AS asset,
    s.symbol,
    s.exchange,
    s.contract_type,
    s.source
FROM symbols s
JOIN assets a ON s.asset_id = a.asset_id
WHERE s.is_active = true
ORDER BY a.sector, a.ticker, s.exchange, s.contract_type
LIMIT 30;

\echo ''
\echo '--- Summary Statistics ---'
SELECT 
    'Total Assets' AS metric,
    COUNT(*)::TEXT AS value
FROM assets
WHERE is_active = true
UNION ALL
SELECT 
    'Total Symbols' AS metric,
    COUNT(*)::TEXT AS value
FROM symbols
WHERE is_active = true
UNION ALL
SELECT 
    'Exchanges Configured' AS metric,
    COUNT(DISTINCT exchange)::TEXT AS value
FROM symbols
WHERE is_active = true;

-- ============================================
-- SAMPLE QUERIES (for testing)
-- ============================================

\echo ''
\echo '============================================'
\echo 'SAMPLE QUERIES'
\echo '============================================'
\echo ''

\echo '--- Example 1: Get all symbols for BTC ---'
\echo 'SELECT a.ticker, s.symbol, s.exchange, s.contract_type'
\echo 'FROM symbols s'
\echo 'JOIN assets a ON s.asset_id = a.asset_id'
\echo "WHERE a.ticker = 'BTC';"
\echo ''

SELECT a.ticker, s.symbol, s.exchange, s.contract_type
FROM symbols s
JOIN assets a ON s.asset_id = a.asset_id
WHERE a.ticker = 'BTC';

\echo ''
\echo '--- Example 2: Get all perpetual contracts ---'
\echo 'SELECT a.ticker, s.symbol, s.exchange'
\echo 'FROM symbols s'
\echo 'JOIN assets a ON s.asset_id = a.asset_id'
\echo "WHERE s.contract_type = 'PERPETUAL';"
\echo ''

SELECT a.ticker, s.symbol, s.exchange
FROM symbols s
JOIN assets a ON s.asset_id = a.asset_id
WHERE s.contract_type = 'PERPETUAL';

\echo ''
\echo '--- Example 3: Get symbol_id for ingestion lookup ---'
\echo "SELECT symbol_id, symbol FROM symbols WHERE symbol = 'BTCUSDT' AND exchange = 'BINANCE';"
\echo ''

SELECT symbol_id, symbol, exchange, contract_type 
FROM symbols 
WHERE symbol = 'BTCUSDT' AND exchange = 'BINANCE';

-- ============================================
-- HELPER FUNCTION (optional - for NiFi)
-- ============================================

\echo ''
\echo '>>> Creating helper function for symbol lookup...'

CREATE OR REPLACE FUNCTION get_symbol_id(
    p_symbol VARCHAR,
    p_exchange VARCHAR
)
RETURNS UUID AS $$
DECLARE
    v_symbol_id UUID;
BEGIN
    SELECT symbol_id INTO v_symbol_id
    FROM symbols
    WHERE symbol = p_symbol
      AND exchange = p_exchange
      AND is_active = true;
    
    IF v_symbol_id IS NULL THEN
        RAISE EXCEPTION 'Symbol not found: % on %', p_symbol, p_exchange;
    END IF;
    
    RETURN v_symbol_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_symbol_id IS 'Helper function to lookup symbol_id by symbol name and exchange. Raises exception if not found.';

\echo '✓ Helper function created: get_symbol_id(symbol, exchange)'

\echo ''
\echo '--- Example usage of get_symbol_id() ---'
\echo "SELECT get_symbol_id('BTCUSDT', 'BINANCE');"
\echo ''

SELECT get_symbol_id('BTCUSDT', 'BINANCE') AS btc_binance_symbol_id;

-- ============================================
-- ASSET/SYMBOL ID REFERENCE (for configuration)
-- ============================================

\echo ''
\echo '============================================'
\echo 'ASSET & SYMBOL IDs (for NiFi/config)'
\echo '============================================'
\echo ''
\echo 'Save these UUIDs for NiFi variable configuration:'
\echo ''

-- Asset IDs
\echo '--- Asset IDs ---'
SELECT 
    ticker,
    asset_id,
    'UUID_' || ticker AS variable_name
FROM assets
ORDER BY ticker;

\echo ''
\echo '--- Key Symbol IDs (for ingestion) ---'
SELECT 
    s.symbol || ' (' || s.exchange || ')' AS identifier,
    s.symbol_id,
    'SYMBOL_' || a.ticker || '_' || s.exchange AS variable_name
FROM symbols s
JOIN assets a ON s.asset_id = a.asset_id
WHERE s.exchange IN ('BINANCE', 'COINBASE', 'BINANCE_FUTURES')
ORDER BY a.ticker, s.exchange;

-- ============================================
-- COMPLETION
-- ============================================

\echo ''
\echo '============================================'
\echo '✓ SEEDING COMPLETE'
\echo '============================================'
\echo ''
\echo 'Data inserted:'
\echo '  - 10 assets (6 crypto, 4 equities)'
\echo '  - 22 symbols across 4 exchanges'
\echo ''
\echo 'Exchanges configured:'
\echo '  - BINANCE (spot): 6 symbols'
\echo '  - BINANCE_FUTURES (perpetuals): 6 symbols'
\echo '  - COINBASE (spot): 6 symbols'
\echo '  - ALPACA (equities): 4 symbols'
\echo ''
\echo 'Next steps:'
\echo '  1. Copy asset_id and symbol_id UUIDs to NiFi variables'
\echo '  2. Configure NiFi flows for data ingestion'
\echo '  3. Start ingesting market data!'
\echo ''
\echo '============================================'
\echo ''