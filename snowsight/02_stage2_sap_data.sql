-- =============================================================================
-- STAGE 2 - SAP data products (snapshot): 4 databases, 4 tables, 219 rows
-- =============================================================================
-- Run All. Role: ACCOUNTADMIN. Takes about 1 minute.
--
-- CHECKPOINT 2 (expected result of the LAST statement - every row PASS):
--   S2-A 4 SAP snapshot databases, kind STANDARD   4/4
--   S2-B rows vendors 50 | materials 26 | purchase_orders 120 | billofmaterials 23
--   S2-B rows TOTAL                                219
--   S2-C vendor columns populated                  50/50/50/50
-- =============================================================================
USE ROLE ACCOUNTADMIN;
ALTER GIT REPOSITORY TRAINING_KIT_REPO.PUBLIC.GNN_KIT FETCH;

EXECUTE IMMEDIATE FROM @TRAINING_KIT_REPO.PUBLIC.GNN_KIT/branches/main/sql/stage2_sap_snapshot/20_sap_databases_schemas.sql;
EXECUTE IMMEDIATE FROM @TRAINING_KIT_REPO.PUBLIC.GNN_KIT/branches/main/sql/stage2_sap_snapshot/21_sap_tables.sql;

-- Git repositories can't be loaded directly, so the CSVs are copied to a stage first.
EXECUTE IMMEDIATE FROM @TRAINING_KIT_REPO.PUBLIC.GNN_KIT/branches/main/snowsight/sql/load_sap_from_git.sql;

-- CHECKPOINT 2
EXECUTE IMMEDIATE FROM @TRAINING_KIT_REPO.PUBLIC.GNN_KIT/branches/main/sql/validation/v2_sap_snapshot.sql;
