-- =============================================================================
-- Stage 5.0 - Cortex Search service over customer contracts
-- Source: GET_DDL('cortex_search_service') on F9A3UBGT (unchanged)
-- Source service: embedding model snowflake-arctic-embed-m-v1.5 (default), 12 rows indexed.
-- Indexing takes a few minutes after creation; Stage 5 check A waits for ACTIVE.
-- =============================================================================
USE ROLE DEMO_19865_ROLE;
USE WAREHOUSE DEMO_19865_WH;
USE SCHEMA DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK;

CREATE OR REPLACE CORTEX SEARCH SERVICE CONTRACT_SEARCH_SERVICE
    ON CONTRACT_TEXT
    ATTRIBUTES CONTRACT_ID, CONTRACT_TITLE, SUPPLIER_NAME, BUYER_NAME, SUPPLIER_COUNTRY,
               BUYER_COUNTRY, MATERIAL_TYPE, CONTRACT_DATE, ANNUAL_VALUE_USD
    WAREHOUSE = DEMO_19865_WH
    TARGET_LAG = '1 hour'
    REFRESH_MODE = INCREMENTAL
AS (
    SELECT
        CONTRACT_TEXT,
        CONTRACT_ID,
        CONTRACT_TITLE,
        SUPPLIER_NAME,
        BUYER_NAME,
        SUPPLIER_COUNTRY,
        BUYER_COUNTRY,
        MATERIAL_TYPE,
        CONTRACT_DATE,
        ANNUAL_VALUE_USD
    FROM DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.CUSTOMER_CONTRACTS
);
