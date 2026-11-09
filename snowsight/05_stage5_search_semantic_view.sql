-- =============================================================================
-- STAGE 5 - Cortex Search service + semantic view
-- =============================================================================
-- Run All. Role: ACCOUNTADMIN. Takes 1-6 minutes (it waits for the search index).
--
-- CHECKPOINT 4 (expected result of the LAST statement - every row PASS):
--   S5-A search service column + indexing/serving state   CONTRACT_TEXT ACTIVE/ACTIVE
--   S5-A semantic view exists                             1
--   S5-B search "force majeure" returns contracts         3 results, first=SC-...
--   S5-C semantic view structure                          4 tables, 9 facts, 26 dimensions
--   S5-C semantic view query                              50 rows: CRITICAL 2, HIGH 4, MEDIUM 44
-- If S5-A shows WAIT, wait a minute and run only the last line again.
-- =============================================================================
USE ROLE ACCOUNTADMIN;
ALTER GIT REPOSITORY TRAINING_KIT_REPO.PUBLIC.GNN_KIT FETCH;

EXECUTE IMMEDIATE FROM @TRAINING_KIT_REPO.PUBLIC.GNN_KIT/branches/main/sql/stage5_ai_services/50_cortex_search.sql;
EXECUTE IMMEDIATE FROM @TRAINING_KIT_REPO.PUBLIC.GNN_KIT/branches/main/sql/stage5_ai_services/51_semantic_view.sql;
EXECUTE IMMEDIATE FROM @TRAINING_KIT_REPO.PUBLIC.GNN_KIT/branches/main/snowsight/sql/wait_for_search.sql;

-- CHECKPOINT 4
EXECUTE IMMEDIATE FROM @TRAINING_KIT_REPO.PUBLIC.GNN_KIT/branches/main/sql/validation/v5_ai_services.sql;
