-- =============================================================================
-- Validation - Stage 1 (account objects). Read-only.
-- =============================================================================
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE DEMO_19865_WH;

SHOW ROLES LIKE 'DEMO_19865_ROLE';
SET V_ROLE = (SELECT COUNT(*) FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));

SHOW WAREHOUSES LIKE 'DEMO_19865_WH';
SET V_WH = (SELECT MAX(UPPER("size") || '/' || "auto_suspend" || '/' || "owner") FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));

SHOW COMPUTE POOLS LIKE 'DEMO_19865_POOL';
SET V_POOL = (SELECT MAX("instance_family" || '/' || "min_nodes" || '-' || "max_nodes") FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));

SHOW EXTERNAL ACCESS INTEGRATIONS LIKE 'DEMO_19865_%';
SET V_EAI = (SELECT COALESCE(NULLIF(LISTAGG("name" || ':' || "enabled", ',') WITHIN GROUP (ORDER BY "name"), ''), 'none')
             FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));

SHOW GRANTS TO ROLE DEMO_19865_ROLE;
SET V_GRANTS = (SELECT
      COUNT_IF("privilege" = 'USAGE' AND "granted_on" = 'INTEGRATION' AND "name" = 'DEMO_19865_PIP_INSTALLATION')
    + COUNT_IF("privilege" = 'OWNERSHIP' AND "granted_on" = 'WAREHOUSE' AND "name" = 'DEMO_19865_WH')
    + COUNT_IF("privilege" = 'OWNERSHIP' AND "granted_on" = 'COMPUTE_POOL' AND "name" = 'DEMO_19865_POOL')
    + COUNT_IF("granted_on" = 'DATABASE_ROLE' AND "name" = 'SNOWFLAKE.CORTEX_USER')
  FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));

SELECT 'S1-A role DEMO_19865_ROLE exists' AS CHECK_NAME, '1' AS EXPECTED, $V_ROLE::VARCHAR AS ACTUAL,
       IFF($V_ROLE = 1, 'PASS', 'FAIL') AS RESULT
UNION ALL
SELECT 'S1-A warehouse size/auto_suspend/owner', 'SMALL/300/DEMO_19865_ROLE', $V_WH,
       IFF($V_WH = 'SMALL/300/DEMO_19865_ROLE', 'PASS', 'FAIL')
UNION ALL
SELECT 'S1-A compute pool family/nodes', 'CPU_X64_M/1-1', $V_POOL,
       IFF($V_POOL = 'CPU_X64_M/1-1', 'PASS', 'FAIL')
UNION ALL
SELECT 'S1-B integrations', 'DEMO_19865_PIP_INSTALLATION:true', $V_EAI,
       IFF($V_EAI = 'DEMO_19865_PIP_INSTALLATION:true', 'PASS',
           IFF($V_EAI = 'none', 'INFO - not created (trial account); only Lab 4 needs it', 'FAIL'))
UNION ALL
SELECT 'S1-C key grants to DEMO_19865_ROLE (WH, pool, CORTEX_USER [+ EAI])', IFF($V_EAI = 'none', '3', '4'), $V_GRANTS::VARCHAR,
       IFF($V_GRANTS = IFF($V_EAI = 'none', 3, 4), 'PASS', 'FAIL');
