-- =============================================================================
-- Validation - Stage 0 (prerequisites). Read-only. No warehouse needed.
-- (No warehouse exists yet, so SHOW output is read by eye instead of RESULT_SCAN.)
-- =============================================================================
USE ROLE ACCOUNTADMIN;

SELECT 'S0-A role is ACCOUNTADMIN' AS CHECK_NAME, 'ACCOUNTADMIN' AS EXPECTED, CURRENT_ROLE() AS ACTUAL,
       IFF(CURRENT_ROLE() = 'ACCOUNTADMIN', 'PASS', 'FAIL') AS RESULT
UNION ALL
SELECT 'S0-B target is not the source account', 'org <> F9A3UBGT',
       CURRENT_ORGANIZATION_NAME() || '.' || CURRENT_ACCOUNT_NAME() || ' (' || CURRENT_REGION() || ')',
       IFF(CURRENT_ORGANIZATION_NAME() <> 'F9A3UBGT', 'PASS', 'FAIL');

-- S0-C: expect NO rows on a clean account (rows = already deployed; re-running is safe).
SHOW DATABASES LIKE 'DEMO_19865_DB';
SHOW DATABASES LIKE 'S4_Z%_DP_DELTA_SHARING_V1';
