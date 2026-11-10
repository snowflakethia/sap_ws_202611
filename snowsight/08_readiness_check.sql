-- =============================================================================
-- READINESS CHECK - am I ready to start the labs?
-- =============================================================================
-- Run All at any time. Read-only; changes nothing.
--
-- Expected result (last statement):
--   OVERALL   READY   PASS - you can start the labs
--   ... 9 PASS rows (Git repository, warehouse, SAP rows 219, demo rows 648, VW_RISK_SUMMARY,
--       Cortex Search ACTIVE/ACTIVE, semantic view 2 CRITICAL suppliers, agent 1, cross-region ANY_REGION)
--   ... 2 INFO rows (optional Lab 5 dashboard; Git workspace - confirm in the UI)
-- If OVERALL is NOT READY: re-run the file named in the FIX column of the first FAIL row,
-- then run this check again.
-- =============================================================================
USE ROLE ACCOUNTADMIN;
ALTER GIT REPOSITORY TRAINING_KIT_REPO.PUBLIC.GNN_KIT FETCH;

EXECUTE IMMEDIATE FROM @TRAINING_KIT_REPO.PUBLIC.GNN_KIT/branches/main/snowsight/sql/validation_readiness.sql;
