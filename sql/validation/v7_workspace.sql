-- =============================================================================
-- Validation - Stage 7 (shared workspace). Read-only.
-- Check C (opening the workspace in Snowsight) is done by a person; see SETUP_GUIDE.md.
-- =============================================================================
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE DEMO_19865_WH;

SHOW WORKSPACES IN SCHEMA DEMO_SHARED_WORKSPACES.DEMO_19865_WORKSPACE;
SET V_WS = (SELECT COUNT(*) || ':' || COALESCE(LISTAGG("name", ','), '') FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));

-- Published files (head = what other users see after COMMIT).
LS 'snow://workspace/DEMO_SHARED_WORKSPACES.DEMO_19865_WORKSPACE.DEMO_19865/versions/head/';
SET V_FILES = (SELECT COUNT(*) || ' files: SQL ' || COUNT_IF(CONTAINS("name", '/SQL/'))
                   || ', Notebooks ' || COUNT_IF(CONTAINS("name", '/Notebooks/'))
                   || ', Data ' || COUNT_IF(CONTAINS("name", '/Data/'))
               FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));

SHOW GRANTS ON WORKSPACE DEMO_SHARED_WORKSPACES.DEMO_19865_WORKSPACE.DEMO_19865;
SET V_WRITE = (SELECT COUNT_IF("privilege" = 'WRITE' AND "grantee_name" = 'DEMO_19865_ROLE')
               FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));

SELECT 'S7-A workspace exists' AS CHECK_NAME, '1:DEMO_19865' AS EXPECTED, $V_WS AS ACTUAL,
       IFF($V_WS = '1:DEMO_19865', 'PASS', 'FAIL') AS RESULT
UNION ALL
SELECT 'S7-B published files', '7 files: SQL 3, Notebooks 2, Data 2', $V_FILES,
       IFF($V_FILES = '7 files: SQL 3, Notebooks 2, Data 2', 'PASS', 'FAIL')
UNION ALL
SELECT 'S7-C DEMO_19865_ROLE has WRITE on workspace', '1', $V_WRITE::VARCHAR, IFF($V_WRITE = 1, 'PASS', 'FAIL');
