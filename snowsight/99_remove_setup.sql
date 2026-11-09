-- =============================================================================
-- REMOVE THE SETUP - deletes everything the training setup created in this account
-- =============================================================================
-- Run All. Role: ACCOUNTADMIN. Takes about 1 minute. This cannot be undone
-- (apart from UNDROP DATABASE within the Time Travel period).
--
-- Removes: databases DEMO_19865_DB, DEMO_SHARED_WORKSPACES, the 4 S4_Z*_DP_DELTA_SHARING_V1
-- databases and TRAINING_KIT_REPO; warehouse DEMO_19865_WH; compute pool DEMO_19865_POOL;
-- integrations DEMO_19865_PIP_INSTALLATION and GNN_KIT_GITHUB; roles DEMO_19865_ROLE and
-- DEMO_READER_ROLE. Nothing else in the account is touched.
--
-- Expected result (last statement): 6 rows, every RESULT = REMOVED.
-- AFTERWARDS, delete your Git workspace in the UI:
--   Projects > Workspaces > gnn_training > (... menu next to the workspace name) > Delete.
-- =============================================================================
USE ROLE ACCOUNTADMIN;

-- Safety guard: stops Run All with an error if this is the source demo account.
EXECUTE IMMEDIATE $$
DECLARE
  source_account EXCEPTION (-20001, 'STOP: this is the SOURCE demo account (F9A3UBGT). Nothing was removed.');
BEGIN
  IF (CURRENT_ORGANIZATION_NAME() = 'F9A3UBGT') THEN
    RAISE source_account;
  END IF;
  RETURN 'OK - removing the training setup from ' || CURRENT_ORGANIZATION_NAME() || '.' || CURRENT_ACCOUNT_NAME();
END;
$$;

-- The statements are inline (not run from the Git repository) because the repository
-- itself is dropped at the end. Integrations first: they reference objects in the databases.
DROP INTEGRATION IF EXISTS DEMO_19865_PIP_INSTALLATION;
DROP DATABASE IF EXISTS DEMO_SHARED_WORKSPACES;
DROP DATABASE IF EXISTS DEMO_19865_DB;
DROP DATABASE IF EXISTS S4_ZVENDORINFO_DP_DELTA_SHARING_V1;
DROP DATABASE IF EXISTS S4_ZMATERIALS_DP_DELTA_SHARING_V1;
DROP DATABASE IF EXISTS S4_ZPURCHASEORDERS_DP_DELTA_SHARING_V1;
DROP DATABASE IF EXISTS S4_ZBILLOFMATERIALS_DP_DELTA_SHARING_V1;
ALTER COMPUTE POOL IF EXISTS DEMO_19865_POOL STOP ALL;
DROP COMPUTE POOL IF EXISTS DEMO_19865_POOL;
DROP WAREHOUSE IF EXISTS DEMO_19865_WH;
DROP ROLE IF EXISTS DEMO_READER_ROLE;
DROP ROLE IF EXISTS DEMO_19865_ROLE;
DROP DATABASE IF EXISTS TRAINING_KIT_REPO;
DROP INTEGRATION IF EXISTS GNN_KIT_GITHUB;

-- Verification (no warehouse needed): counts what is left. Every row must read REMOVED.
EXECUTE IMMEDIATE $$
DECLARE
  n_db INTEGER DEFAULT 0; n_wh INTEGER DEFAULT 0; n_pool INTEGER DEFAULT 0;
  n_role INTEGER DEFAULT 0; n_int INTEGER DEFAULT 0; n_repo INTEGER DEFAULT 0;
  res RESULTSET;
BEGIN
  LET r1 RESULTSET := (SHOW DATABASES);
  LET c1 CURSOR FOR r1;
  FOR r IN c1 DO
    IF (r."name" IN ('DEMO_19865_DB', 'DEMO_SHARED_WORKSPACES', 'S4_ZVENDORINFO_DP_DELTA_SHARING_V1',
        'S4_ZMATERIALS_DP_DELTA_SHARING_V1', 'S4_ZPURCHASEORDERS_DP_DELTA_SHARING_V1',
        'S4_ZBILLOFMATERIALS_DP_DELTA_SHARING_V1')) THEN n_db := n_db + 1; END IF;
    IF (r."name" = 'TRAINING_KIT_REPO') THEN n_repo := n_repo + 1; END IF;
  END FOR;
  LET r2 RESULTSET := (SHOW WAREHOUSES LIKE 'DEMO_19865_WH');
  LET c2 CURSOR FOR r2;
  FOR r IN c2 DO n_wh := n_wh + 1; END FOR;
  LET r3 RESULTSET := (SHOW COMPUTE POOLS LIKE 'DEMO_19865_POOL');
  LET c3 CURSOR FOR r3;
  FOR r IN c3 DO n_pool := n_pool + 1; END FOR;
  LET r4 RESULTSET := (SHOW ROLES LIKE 'DEMO_%');
  LET c4 CURSOR FOR r4;
  FOR r IN c4 DO
    IF (r."name" IN ('DEMO_19865_ROLE', 'DEMO_READER_ROLE')) THEN n_role := n_role + 1; END IF;
  END FOR;
  LET r5 RESULTSET := (SHOW INTEGRATIONS);
  LET c5 CURSOR FOR r5;
  FOR r IN c5 DO
    IF (r."name" IN ('DEMO_19865_PIP_INSTALLATION', 'GNN_KIT_GITHUB')) THEN n_int := n_int + 1; END IF;
  END FOR;
  res := (EXECUTE IMMEDIATE
       'SELECT ''Training databases (6)'' AS OBJECT_NAME, ' || n_db || ' AS REMAINING, ' || IFF(n_db = 0, '''REMOVED''', '''STILL PRESENT''') || ' AS RESULT'
    || ' UNION ALL SELECT ''Git repository database TRAINING_KIT_REPO'', ' || n_repo || ', ' || IFF(n_repo = 0, '''REMOVED''', '''STILL PRESENT''')
    || ' UNION ALL SELECT ''Warehouse DEMO_19865_WH'', ' || n_wh || ', ' || IFF(n_wh = 0, '''REMOVED''', '''STILL PRESENT''')
    || ' UNION ALL SELECT ''Compute pool DEMO_19865_POOL'', ' || n_pool || ', ' || IFF(n_pool = 0, '''REMOVED''', '''STILL PRESENT''')
    || ' UNION ALL SELECT ''Roles DEMO_19865_ROLE, DEMO_READER_ROLE'', ' || n_role || ', ' || IFF(n_role = 0, '''REMOVED''', '''STILL PRESENT''')
    || ' UNION ALL SELECT ''Integrations DEMO_19865_PIP_INSTALLATION, GNN_KIT_GITHUB'', ' || n_int || ', ' || IFF(n_int = 0, '''REMOVED''', '''STILL PRESENT'''));
  RETURN TABLE(res);
END;
$$;
