
-- =============================================================================
-- DEMO 19865 - Read-Only Role Creation (Updated for separate workspace DB/Schema)
-- =============================================================================
-- This role gives read-only access to:
--   • All objects in DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK (tables, views, stages, etc.)
--   • Warehouse and Compute Pool
--   • The shared workspace "demo_19865" located in DEMO_SHARED_WORKSPACES.DEMO_19865_WORKSPACE
-- =============================================================================

USE ROLE ACCOUNTADMIN;

-- =============================================================================
-- 1. Create the Read-Only Role
-- =============================================================================
CREATE ROLE IF NOT EXISTS DEMO_READER_ROLE
    COMMENT = 'Read-only role for DEMO_19865 GNN Supply Chain Risk demo (data + shared workspace)';

-- Grant role to yourself
SET MY_USER = (SELECT CURRENT_USER());
GRANT ROLE DEMO_READER_ROLE TO USER IDENTIFIER($MY_USER);

GRANT ROLE DEMO_READER_ROLE TO USER DESMITH;

GRANT ROLE DEMO_READER_ROLE TO USER SMITHJO;

-- Optional: also grant to SYSADMIN for admin convenience
GRANT ROLE DEMO_READER_ROLE TO ROLE SYSADMIN;

-- =============================================================================
-- 2. Access to Main Demo Database & Schema
-- =============================================================================
GRANT USAGE ON DATABASE DEMO_19865_DB 
    TO ROLE DEMO_READER_ROLE;

GRANT USAGE ON SCHEMA DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK 
    TO ROLE DEMO_READER_ROLE;

-- =============================================================================
-- 3. Warehouse & Compute Pool
-- =============================================================================
GRANT USAGE ON WAREHOUSE DEMO_19865_WH 
    TO ROLE DEMO_READER_ROLE;

GRANT USAGE ON COMPUTE POOL DEMO_19865_POOL 
    TO ROLE DEMO_READER_ROLE;

-- =============================================================================
-- 4. Stages & File Format in Main Schema
-- =============================================================================
GRANT READ ON STAGE DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.MODELS_STAGE 
    TO ROLE DEMO_READER_ROLE;

GRANT READ ON STAGE DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.DATA_STAGE 
    TO ROLE DEMO_READER_ROLE;
	
GRANT READ ON STAGE DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.DEMO_SECRETS_STAGE 
    TO ROLE DEMO_READER_ROLE;	

GRANT USAGE ON FILE FORMAT DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.CSV_FORMAT 
    TO ROLE DEMO_READER_ROLE;

-- =============================================================================
-- 5. Data Access (Tables + Views) - Main Schema
-- =============================================================================
GRANT SELECT ON ALL TABLES IN SCHEMA DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK 
    TO ROLE DEMO_READER_ROLE;

GRANT SELECT ON ALL VIEWS IN SCHEMA DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK 
    TO ROLE DEMO_READER_ROLE;

-- Future objects (so Python notebooks creating new tables/views remain readable)
GRANT SELECT ON FUTURE TABLES IN SCHEMA DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK 
    TO ROLE DEMO_READER_ROLE;

GRANT SELECT ON FUTURE VIEWS IN SCHEMA DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK 
    TO ROLE DEMO_READER_ROLE;

-- =============================================================================
-- 6. Access to Shared Workspace Database & Schema
-- =============================================================================
GRANT USAGE ON DATABASE DEMO_SHARED_WORKSPACES 
    TO ROLE DEMO_READER_ROLE;

GRANT USAGE ON SCHEMA DEMO_SHARED_WORKSPACES.DEMO_19865_WORKSPACE 
    TO ROLE DEMO_READER_ROLE;

-- =============================================================================
-- 7. Read Access to the Shared Workspace "demo_19865"
-- =============================================================================
-- Use quoted identifier because the name is lowercase with underscore
GRANT READ ON WORKSPACE DEMO_SHARED_WORKSPACES.DEMO_19865_WORKSPACE."DEMO_19865"
    TO ROLE DEMO_READER_ROLE;

GRANT WRITE ON WORKSPACE DEMO_SHARED_WORKSPACES.DEMO_19865_WORKSPACE."DEMO_19865"
    TO ROLE DEMO_19865_ROLE;    

GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE IDENTIFIER('DEMO_READER_ROLE');

-- =============================================================================
-- 8. Verification
-- =============================================================================
SELECT '✅ DEMO_READER_ROLE created successfully with workspace access!' AS STATUS,
       CURRENT_TIMESTAMP() AS CREATED_AT;

-- Check grants on the workspace
SHOW GRANTS ON WORKSPACE DEMO_SHARED_WORKSPACES.DEMO_19865_WORKSPACE."DEMO_19865";

-- Optional: list all workspaces in that schema to confirm name
-- SHOW WORKSPACES IN SCHEMA DEMO_SHARED_WORKSPACES.DEMO_19865_WORKSPACE;

