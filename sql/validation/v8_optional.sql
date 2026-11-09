-- =============================================================================
-- Validation - Stage 8 (optional module). Read-only.
-- Reader-role privilege test (SELECT works, DROP fails) is done by a person; see SETUP_GUIDE.md.
-- =============================================================================
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE DEMO_19865_WH;

SHOW ROLES LIKE 'DEMO_READER_ROLE';
SET V_READER = (SELECT COUNT(*) FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));

SELECT 'S8 optional reader role installed' AS CHECK_NAME, '0 (default) or 1 (--with-reader-role)' AS EXPECTED,
       $V_READER::VARCHAR AS ACTUAL, 'INFO' AS RESULT;
