-- =============================================================================
-- Stage 0 - Prerequisites check (read-only, no warehouse needed)
-- =============================================================================
-- Run as the trainee in their own account. Nothing is created here.
-- Expected: role ACCOUNTADMIN, account is NOT F9A3UBGT, and no DEMO_19865_DB yet.
-- =============================================================================
USE ROLE ACCOUNTADMIN;

SELECT CURRENT_ORGANIZATION_NAME() AS ORGANIZATION,
       CURRENT_ACCOUNT_NAME()      AS ACCOUNT,
       CURRENT_REGION()            AS REGION,
       CURRENT_USER()              AS USER_NAME,
       CURRENT_ROLE()              AS ROLE_NAME,
       IFF(CURRENT_ROLE() = 'ACCOUNTADMIN', 'PASS', 'FAIL') AS ROLE_CHECK,
       IFF(CURRENT_ORGANIZATION_NAME() = 'F9A3UBGT', 'FAIL - this is the SOURCE account', 'PASS') AS TARGET_CHECK;

-- Expect 0 rows on a clean account. Rows here mean the kit was already deployed
-- (re-running is safe) or the names collide with existing objects.
SHOW DATABASES LIKE 'DEMO_19865_DB';
SHOW DATABASES LIKE 'S4_Z%_DP_DELTA_SHARING_V1';
