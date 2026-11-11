-- =============================================================================
-- Snowsight path - readiness check (called by snowsight/08_readiness_check.sql)
-- Read-only. Never fails: a missing object is reported as FAIL with the file to re-run.
-- Returns one table: CHECK_NAME | EXPECTED | ACTUAL | RESULT | FIX, with OVERALL first.
-- =============================================================================
USE ROLE ACCOUNTADMIN;

EXECUTE IMMEDIATE $$
DECLARE
  rows_sql VARCHAR DEFAULT '';
  fails    INTEGER DEFAULT 0;
  actual   VARCHAR;
  has_wh   BOOLEAN DEFAULT FALSE;
  res      RESULTSET;
BEGIN
  -- Helper pattern for every check: compute ACTUAL, compare, append one SELECT row to rows_sql.

  -- 1. Git repository (Step 0)
  BEGIN
    SHOW GIT REPOSITORIES LIKE 'GNN_KIT' IN SCHEMA TRAINING_KIT_REPO.PUBLIC;
    actual := (SELECT COUNT(*)::VARCHAR FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));
  EXCEPTION WHEN OTHER THEN actual := 'missing';
  END;
  IF (actual <> '1') THEN fails := fails + 1; END IF;
  rows_sql := rows_sql || ' UNION ALL SELECT 2, ''Git repository GNN_KIT'', ''1'', ''' || actual || ''', '''
           || IFF(actual = '1', 'PASS', 'FAIL') || ''', ''00_bootstrap.sql''';

  -- 2. Warehouse (Stage 1) - every later check needs it
  BEGIN
    USE WAREHOUSE DEMO_19865_WH;
    has_wh := TRUE;
    actual := 'DEMO_19865_WH';
  EXCEPTION WHEN OTHER THEN actual := 'missing';
  END;
  IF (NOT has_wh) THEN fails := fails + 1; END IF;
  rows_sql := rows_sql || ' UNION ALL SELECT 3, ''Warehouse'', ''DEMO_19865_WH'', ''' || actual || ''', '''
           || IFF(has_wh, 'PASS', 'FAIL') || ''', ''01_stage1_account.sql''';

  -- 3. SAP snapshot rows (Stage 2)
  BEGIN
    actual := (SELECT (
        (SELECT COUNT(*) FROM S4_ZVENDORINFO_DP_DELTA_SHARING_V1."s4_zvendorinfo_dp_srv:v1"."s4custom_vendors")
      + (SELECT COUNT(*) FROM S4_ZMATERIALS_DP_DELTA_SHARING_V1."s4_zmaterials_dp_srv:v1"."s4custom_materials")
      + (SELECT COUNT(*) FROM S4_ZPURCHASEORDERS_DP_DELTA_SHARING_V1."s4_zpurchaseorders_dp_srv:v1"."s4custom_purchase_orders")
      + (SELECT COUNT(*) FROM S4_ZBILLOFMATERIALS_DP_DELTA_SHARING_V1."s4_zbillofmaterials_dp_srv:v1"."s4custom_billofmaterials"))::VARCHAR);
  EXCEPTION WHEN OTHER THEN actual := 'missing';
  END;
  IF (actual <> '219') THEN fails := fails + 1; END IF;
  rows_sql := rows_sql || ' UNION ALL SELECT 4, ''SAP snapshot rows'', ''219'', ''' || actual || ''', '''
           || IFF(actual = '219', 'PASS', 'FAIL') || ''', ''02_stage2_sap_data.sql''';

  -- 4. Demo table rows (Stages 3-4)
  BEGIN
    actual := (SELECT (
        (SELECT COUNT(*) FROM DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.BOTTLENECKS_PREDICTIONS)
      + (SELECT COUNT(*) FROM DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.CUSTOMER_CONTRACTS)
      + (SELECT COUNT(*) FROM DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.REGIONS_EXTERNAL)
      + (SELECT COUNT(*) FROM DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.RISK_SCORES_PREDICTIONS)
      + (SELECT COUNT(*) FROM DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.SUPPLIER_LINKS_PREDICTIONS)
      + (SELECT COUNT(*) FROM DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.TRADE_DATA_EXTERNAL))::VARCHAR);
  EXCEPTION WHEN OTHER THEN actual := 'missing';
  END;
  IF (actual <> '648') THEN fails := fails + 1; END IF;
  rows_sql := rows_sql || ' UNION ALL SELECT 5, ''Demo table rows'', ''648'', ''' || actual || ''', '''
           || IFF(actual = '648', 'PASS', 'FAIL') || ''', ''03_stage3_demo_schema.sql then 04_stage4_demo_data.sql''';

  -- 5. Risk summary view (Stages 3-4)
  BEGIN
    actual := (SELECT LISTAGG(CATEGORY || ' ' || TOTAL_COUNT, ', ') WITHIN GROUP (ORDER BY CATEGORY DESC)
               FROM DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.VW_RISK_SUMMARY);
  EXCEPTION WHEN OTHER THEN actual := 'missing';
  END;
  IF (actual <> 'SUPPLIERS 50, PARTS 26') THEN fails := fails + 1; END IF;
  rows_sql := rows_sql || ' UNION ALL SELECT 6, ''VW_RISK_SUMMARY'', ''SUPPLIERS 50, PARTS 26'', ''' || actual || ''', '''
           || IFF(actual = 'SUPPLIERS 50, PARTS 26', 'PASS', 'FAIL') || ''', ''04_stage4_demo_data.sql''';

  -- 6. Cortex Search (Stage 5)
  BEGIN
    SHOW CORTEX SEARCH SERVICES LIKE 'CONTRACT_SEARCH_SERVICE' IN SCHEMA DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK;
    actual := (SELECT COALESCE(MAX("indexing_state" || '/' || "serving_state"), 'missing') FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));
  EXCEPTION WHEN OTHER THEN actual := 'missing';
  END;
  IF (actual <> 'ACTIVE/ACTIVE') THEN fails := fails + 1; END IF;
  rows_sql := rows_sql || ' UNION ALL SELECT 7, ''Cortex Search CONTRACT_SEARCH_SERVICE'', ''ACTIVE/ACTIVE'', ''' || actual || ''', '''
           || IFF(actual = 'ACTIVE/ACTIVE', 'PASS', 'FAIL') || ''', ''05_stage5_search_semantic_view.sql''';

  -- 7. Semantic view answers a query (Stage 5)
  BEGIN
    actual := (SELECT COUNT_IF(RISK_CATEGORY = 'CRITICAL')::VARCHAR || ' CRITICAL suppliers' FROM SEMANTIC_VIEW(
                 DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.SUPPLY_CHAIN_RISK_SEMANTIC_VIEW
                 DIMENSIONS VW_SUPPLIER_RISK.VENDOR_ID, VW_SUPPLIER_RISK.RISK_CATEGORY));
  EXCEPTION WHEN OTHER THEN actual := 'missing';
  END;
  IF (actual <> '2 CRITICAL suppliers') THEN fails := fails + 1; END IF;
  rows_sql := rows_sql || ' UNION ALL SELECT 8, ''Semantic view query'', ''2 CRITICAL suppliers'', ''' || actual || ''', '''
           || IFF(actual = '2 CRITICAL suppliers', 'PASS', 'FAIL') || ''', ''05_stage5_search_semantic_view.sql''';

  -- 8. Agent (Stage 6)
  BEGIN
    SHOW AGENTS LIKE 'GNN_SUPPLY_RISK_AGENT' IN SCHEMA DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK;
    actual := (SELECT COUNT(*)::VARCHAR FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));
  EXCEPTION WHEN OTHER THEN actual := 'missing';
  END;
  IF (actual <> '1') THEN fails := fails + 1; END IF;
  rows_sql := rows_sql || ' UNION ALL SELECT 9, ''Agent GNN_SUPPLY_RISK_AGENT'', ''1'', ''' || actual || ''', '''
           || IFF(actual = '1', 'PASS', 'FAIL') || ''', ''06_stage6_agent.sql''';

  -- 9. Cortex cross-region inference (Stage 1) - CoCo in Snowsight and the agent need a region with the models
  BEGIN
    SHOW PARAMETERS LIKE 'CORTEX_ENABLED_CROSS_REGION' IN ACCOUNT;
    actual := (SELECT COALESCE(MAX("value"), 'missing') FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));
  EXCEPTION WHEN OTHER THEN actual := 'missing';
  END;
  IF (actual <> 'ANY_REGION') THEN fails := fails + 1; END IF;
  rows_sql := rows_sql || ' UNION ALL SELECT 10, ''Cortex cross-region inference (CoCo, agents)'', ''ANY_REGION'', ''' || actual || ''', '''
           || IFF(actual = 'ANY_REGION', 'PASS', 'FAIL') || ''', ''01_stage1_account.sql''';

  -- 10. PyPI mirror access (Stage 1) - the Lab 5 Streamlit app installs its packages from it
  BEGIN
    SHOW GRANTS TO ROLE DEMO_19865_ROLE;
    actual := (SELECT COUNT_IF("granted_on" = 'DATABASE_ROLE' AND "name" = 'SNOWFLAKE.PYPI_REPOSITORY_USER')::VARCHAR
               FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));
  EXCEPTION WHEN OTHER THEN actual := '0';
  END;
  IF (actual <> '1') THEN fails := fails + 1; END IF;
  rows_sql := rows_sql || ' UNION ALL SELECT 11, ''PyPI mirror access for Streamlit (Lab 5)'', ''1'', ''' || actual || ''', '''
           || IFF(actual = '1', 'PASS', 'FAIL') || ''', ''01_stage1_account.sql''';

  -- 11. Lab 5 dashboard (optional, created during Lab 5) - INFO only, never counts as a failure
  BEGIN
    SHOW STREAMLITS LIKE 'SUPPLY_RISK_DASHBOARD' IN SCHEMA DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK;
    actual := (SELECT COUNT(*)::VARCHAR FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));
  EXCEPTION WHEN OTHER THEN actual := '0';
  END;
  rows_sql := rows_sql || ' UNION ALL SELECT 12, ''Lab 5 dashboard SUPPLY_RISK_DASHBOARD (optional)'', ''created in Lab 5'', ''' || actual || ''', ''INFO'', ''labs/lab5_dashboard_with_coco.md''';

  -- 12. Git workspace: private to the user and not visible to SQL - confirmed by the trainee in the UI.
  rows_sql := rows_sql || ' UNION ALL SELECT 13, ''Git workspace gnn_training (check in the UI)'', ''visible in Workspaces'', ''-'', ''INFO'', ''00b_create_git_workspace.md''';

  -- OVERALL row first
  rows_sql := 'SELECT 1 AS N, ''OVERALL'' AS CHECK_NAME, ''READY'' AS EXPECTED, '''
           || IFF(fails = 0, 'READY', 'NOT READY') || ''' AS ACTUAL, '''
           || IFF(fails = 0, 'PASS - you can start the labs', 'FAIL - ' || fails || ' check(s) failed') || ''' AS RESULT, '''
           || IFF(fails = 0, 'Start with labs/README.md', 'Re-run the file in the FIX column of the first FAIL row') || ''' AS FIX'
           || rows_sql;
  res := (EXECUTE IMMEDIATE 'SELECT CHECK_NAME, EXPECTED, ACTUAL, RESULT, FIX FROM (' || rows_sql || ') ORDER BY N');
  RETURN TABLE(res);
END;
$$;
