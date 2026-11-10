-- =============================================================================
-- Stage 1.3 - Cortex access for the project role
-- Source: workspace SQL/01_account_setup.sql (section 6)
-- =============================================================================
USE ROLE ACCOUNTADMIN;

GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE DEMO_19865_ROLE;

-- Let Cortex (CoCo in Snowsight, Cortex Agents, Cortex Analyst, AI functions) route requests to any region
-- where the required models are available, so the labs work whatever region the trainee account is in.
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';

SELECT 'Stage 1 complete' AS STATUS,
       'DEMO_19865_ROLE' AS ROLE_NAME,
       'DEMO_19865_WH'   AS WAREHOUSE_NAME,
       'DEMO_19865_POOL' AS COMPUTE_POOL_NAME,
       'DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK' AS PROJECT_SCHEMA;
