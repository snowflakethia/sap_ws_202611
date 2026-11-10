-- =============================================================================
-- Lab 5 fallback - deploy the tested reference dashboard from the course repository
--
-- WHEN TO USE: Lab 5 normally builds the dashboard with one prompt in Cortex Code (CoCo). Run this file
-- instead if CoCo isn't available, or to compare your CoCo-built app with the reference version.
-- WHAT IT DOES: creates the Streamlit in Snowflake app SUPPLY_RISK_DASHBOARD from
--   labs/lab5_app/streamlit_app.py in the Git repository, owned by DEMO_19865_ROLE.
-- SAFE TO RE-RUN: yes (CREATE OR REPLACE). It replaces an app with the same name, including one built by CoCo.
-- HOW TO RUN: role ACCOUNTADMIN, Run All.
-- Expected result (last statement): every RESULT = PASS.
-- =============================================================================
USE ROLE ACCOUNTADMIN;
ALTER GIT REPOSITORY TRAINING_KIT_REPO.PUBLIC.GNN_KIT FETCH;

-- The app is owned by the course role, so it runs with that role's (read-only) access to the SAP and demo data.
GRANT USAGE ON DATABASE TRAINING_KIT_REPO TO ROLE DEMO_19865_ROLE;
GRANT USAGE ON SCHEMA TRAINING_KIT_REPO.PUBLIC TO ROLE DEMO_19865_ROLE;
GRANT READ ON GIT REPOSITORY TRAINING_KIT_REPO.PUBLIC.GNN_KIT TO ROLE DEMO_19865_ROLE;

USE ROLE DEMO_19865_ROLE;
USE WAREHOUSE DEMO_19865_WH;

-- Warehouse runtime: runs on DEMO_19865_WH and installs packages from the Snowflake Anaconda channel
-- (environment.yml). The container runtime would need a compute pool plus pyproject.toml/requirements.txt.
CREATE OR REPLACE STREAMLIT DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.SUPPLY_RISK_DASHBOARD
    FROM '@TRAINING_KIT_REPO.PUBLIC.GNN_KIT/branches/main/labs/lab5_app'
    MAIN_FILE = 'streamlit_app.py'
    RUNTIME_NAME = 'SYSTEM$WAREHOUSE_RUNTIME'
    QUERY_WAREHOUSE = DEMO_19865_WH
    TITLE = 'Supply Chain Risk Dashboard'
    COMMENT = 'Lab 5 reference app - synthetic data, for demonstration only';

-- Validation
USE ROLE ACCOUNTADMIN;
DESCRIBE STREAMLIT DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.SUPPLY_RISK_DASHBOARD;
SET V_RUNTIME = (SELECT COALESCE(MAX("runtime_name"), 'not set') FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));

SHOW STREAMLITS LIKE 'SUPPLY_RISK_DASHBOARD' IN SCHEMA DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK;
SELECT 'L5-A app SUPPLY_RISK_DASHBOARD exists' AS CHECK_NAME, '1' AS EXPECTED, COUNT(*)::VARCHAR AS ACTUAL,
       IFF(COUNT(*) = 1, 'PASS', 'FAIL') AS RESULT
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
UNION ALL
SELECT 'L5-B owner / warehouse', 'DEMO_19865_ROLE / DEMO_19865_WH', MAX("owner" || ' / ' || "query_warehouse"),
       IFF(MAX("owner" || ' / ' || "query_warehouse") = 'DEMO_19865_ROLE / DEMO_19865_WH', 'PASS', 'FAIL')
FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))
UNION ALL
SELECT 'L5-C runtime', 'SYSTEM$WAREHOUSE_RUNTIME', $V_RUNTIME,
       IFF($V_RUNTIME = 'SYSTEM$WAREHOUSE_RUNTIME', 'PASS', 'FAIL');
