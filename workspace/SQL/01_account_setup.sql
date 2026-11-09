-- Account setup for GNN Supply Chain Risk demo with CPU compute pool fallback
-- Co-authored with CoCo
-- =============================================================================
-- DEMO 19865 - GNN Supply Chain Risk - Account-Level Setup
-- =============================================================================
-- This script creates account-level Snowflake objects:
--   - Role
--   - Database and Schema
--   - Warehouse
--   - Compute Pool
--   - Network Rules and External Access Integration
--
-- Required Session Variables (set by shell script before executing):
--   $FULL_PREFIX        - Full database/resource prefix (e.g., DEV_GNN_SUPPLY_CHAIN_RISK)
--   $PROJECT_ROLE       - Role name (e.g., DEV_GNN_SUPPLY_CHAIN_RISK_ROLE -> DEMO_19865_ROLE)
--   $PROJECT_WH         - Warehouse name (e.g., DEV_GNN_SUPPLY_CHAIN_RISK_WH -> DEMO_19865_WH)
--   $PROJECT_COMPUTE_POOL - Compute pool name
--   $PROJECT_SCHEMA     - Schema name (unprefixed, e.g., GNN_SUPPLY_CHAIN_RISK)
--   $PROJECT_NETWORK_RULE - Network rule name
--   $PROJECT_EXTERNAL_ACCESS - External access integration name
--	 Database Name - GNN_SUPPLY_CHAIN -> DEMO_19865_DB
-- =============================================================================

-- =============================================================================
-- 1. Create Role (ACCOUNTADMIN)
-- =============================================================================
USE ROLE ACCOUNTADMIN;

CREATE ROLE IF NOT EXISTS IDENTIFIER('DEMO_19865_ROLE')
    COMMENT = 'Role for GNN Supply Chain Risk project';

-- Grant role to current user
SET MY_USER = (SELECT CURRENT_USER());
GRANT ROLE IDENTIFIER('DEMO_19865_ROLE') TO USER IDENTIFIER($MY_USER);
GRANT ROLE IDENTIFIER('DEMO_19865_ROLE') TO ROLE SYSADMIN;

-- =============================================================================
-- 2. Create Database and Schema
-- =============================================================================
CREATE DATABASE IF NOT EXISTS IDENTIFIER('DEMO_19865_DB');

-- Build fully qualified schema name for creation
SET FQ_SCHEMA = 'DEMO_19865_DB' || '.' || 'GNN_SUPPLY_CHAIN_RISK';
CREATE SCHEMA IF NOT EXISTS IDENTIFIER('GNN_SUPPLY_CHAIN_RISK');

-- Grant ownership on database
GRANT OWNERSHIP ON DATABASE IDENTIFIER('DEMO_19865_DB')
    TO ROLE IDENTIFIER('DEMO_19865_ROLE') COPY CURRENT GRANTS;

-- Grant ownership on schema
GRANT OWNERSHIP ON SCHEMA IDENTIFIER('GNN_SUPPLY_CHAIN_RISK')
    TO ROLE IDENTIFIER('DEMO_19865_ROLE') COPY CURRENT GRANTS;

-- =============================================================================
-- 3. Create Warehouse
-- =============================================================================
CREATE WAREHOUSE IF NOT EXISTS IDENTIFIER('DEMO_19865_WH')
    WAREHOUSE_SIZE = SMALL
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Warehouse for GNN Supply Chain Risk SQL operations';

GRANT OWNERSHIP ON WAREHOUSE IDENTIFIER('DEMO_19865_WH')
    TO ROLE IDENTIFIER('DEMO_19865_ROLE') COPY CURRENT GRANTS;

-- =============================================================================
-- 4. Create Compute Pool for GPU Notebooks
-- =============================================================================
CREATE COMPUTE POOL IF NOT EXISTS IDENTIFIER('DEMO_19865_POOL')
    MIN_NODES = 1
    MAX_NODES = 1
    INSTANCE_FAMILY = CPU_X64_M
    AUTO_RESUME = TRUE
    AUTO_SUSPEND_SECS = 600
    COMMENT = 'CPU compute pool for PyTorch Geometric GNN training (GPU unavailable in region)';

GRANT OWNERSHIP ON COMPUTE POOL IDENTIFIER('DEMO_19865_POOL')
    TO ROLE IDENTIFIER('DEMO_19865_ROLE') COPY CURRENT GRANTS;

-- =============================================================================
-- 5. Create Network Access for PyPI (PyTorch Geometric installation) and Hana Cloud Access
-- =============================================================================
-- Switch to database/schema context for network rule creation
USE DATABASE IDENTIFIER('DEMO_19865_DB');
USE SCHEMA IDENTIFIER('GNN_SUPPLY_CHAIN_RISK');

-- PyPI 
CREATE OR REPLACE NETWORK RULE IDENTIFIER('PIP_INSTALLATION')
    TYPE = HOST_PORT
    MODE = EGRESS
    VALUE_LIST = (
        'pypi.org:443',
        'files.pythonhosted.org:443',
        'download.pytorch.org:443',
        'data.pyg.org:443'
    )
    COMMENT = 'Required for PyTorch Geometric and dependencies';

-- External access integration references the network rule by name
-- IDENTIFIER() doesn't work inside ALLOWED_NETWORK_RULES, so use EXECUTE IMMEDIATE
SET FQ_NETWORK_RULE = 'DEMO_19865_DB' || '.' || 'GNN_SUPPLY_CHAIN_RISK' || '.' || 'PIP_INSTALLATION';

-- Note: Session variables limited to 256 bytes, so keep dynamic SQL short
SET CREATE_EAI_SQL = 'CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION ' || 'DEMO_19865_PIP_INSTALLATION'||
    ' ALLOWED_NETWORK_RULES = (' || $FQ_NETWORK_RULE || ') ENABLED = TRUE';
EXECUTE IMMEDIATE $CREATE_EAI_SQL;

SET GRANT_EAI_SQL = 'GRANT USAGE ON INTEGRATION ' || 'DEMO_19865_PIP_INSTALLATION' || ' TO ROLE ' || 'DEMO_19865_ROLE';
EXECUTE IMMEDIATE $GRANT_EAI_SQL;


-- Hana Cloud
CREATE OR REPLACE NETWORK RULE IDENTIFIER('HANA_CLOUD_ACCESS')
    TYPE = HOST_PORT
    MODE = EGRESS
    VALUE_LIST = (
        '<HANA_HOST>:443'
    )
    COMMENT = 'Required for Acccessing Hana Cloud';

-- External access integration references the network rule by name
-- IDENTIFIER() doesn't work inside ALLOWED_NETWORK_RULES, so use EXECUTE IMMEDIATE
SET FQ_NETWORK_RULE = 'DEMO_19865_DB' || '.' || 'GNN_SUPPLY_CHAIN_RISK' || '.' || 'HANA_CLOUD_ACCESS';

-- Note: Session variables limited to 256 bytes, so keep dynamic SQL short
SET CREATE_EAI_SQL = 'CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION ' || 'DEMO_19865_HANA_CLOUD_ACCESS'||
    ' ALLOWED_NETWORK_RULES = (' || $FQ_NETWORK_RULE || ') ENABLED = TRUE';
EXECUTE IMMEDIATE $CREATE_EAI_SQL;

SET GRANT_EAI_SQL = 'GRANT USAGE ON INTEGRATION ' || 'DEMO_19865_HANA_CLOUD_ACCESS' || ' TO ROLE ' || 'DEMO_19865_ROLE';
EXECUTE IMMEDIATE $GRANT_EAI_SQL;


-- =============================================================================
-- 6. Grant Cortex LLM Access
-- =============================================================================
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE IDENTIFIER('DEMO_19865_ROLE');

-- =============================================================================
-- 7. Display Summary
-- =============================================================================
SELECT 'Account-level setup completed successfully!' AS STATUS,
       'DEMO_19865_DB'AS DATABASE_NAME,
       'DEMO_19865_ROLE' AS ROLE_NAME,
       'DEMO_19865_WH'AS WAREHOUSE_NAME,
       'DEMO_19865_POOL' AS COMPUTE_POOL_NAME;

