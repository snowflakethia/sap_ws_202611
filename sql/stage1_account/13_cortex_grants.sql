-- =============================================================================
-- Stage 1.3 - Cortex access for the project role
-- Source: workspace SQL/01_account_setup.sql (section 6)
-- =============================================================================
USE ROLE ACCOUNTADMIN;

GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE DEMO_19865_ROLE;

SELECT 'Stage 1 complete' AS STATUS,
       'DEMO_19865_ROLE' AS ROLE_NAME,
       'DEMO_19865_WH'   AS WAREHOUSE_NAME,
       'DEMO_19865_POOL' AS COMPUTE_POOL_NAME,
       'DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK' AS PROJECT_SCHEMA;
