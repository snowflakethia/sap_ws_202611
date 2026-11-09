-- =============================================================================
-- Snowsight path - wait until the Cortex Search index is ACTIVE (max ~5 minutes)
-- Replaces the polling loop in scripts/deploy.sh (CLI path).
-- Returns a one-line status. If it reports TIMEOUT, wait a minute and re-run Stage 5.
-- =============================================================================
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE DEMO_19865_WH;

EXECUTE IMMEDIATE $$
DECLARE
  state VARCHAR DEFAULT 'MISSING';
  tries INTEGER DEFAULT 0;
BEGIN
  WHILE (tries < 30) DO
    SHOW CORTEX SEARCH SERVICES LIKE 'CONTRACT_SEARCH_SERVICE' IN SCHEMA DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK;
    SELECT COALESCE(MAX("indexing_state"), 'MISSING') INTO :state FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));
    IF (state = 'ACTIVE') THEN
      RETURN 'Search index ACTIVE after ' || (tries * 10) || ' seconds';
    END IF;
    CALL SYSTEM$WAIT(10);
    tries := tries + 1;
  END WHILE;
  RETURN 'TIMEOUT - indexing state is ' || state || '. Wait a minute, then re-run 05_stage5_search_semantic_view.sql';
END;
$$;
