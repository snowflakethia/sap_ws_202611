-- =============================================================================
-- STAGE 3 - Demo schema: 6 tables, 4 views, 3 stages, 1 file format
-- =============================================================================
-- Run All. Role: ACCOUNTADMIN (scripts switch to DEMO_19865_ROLE). Takes under 1 minute.
-- Not a checkpoint stage, but the last result must still be all PASS:
--   S3-A tables (all standard)                        6 tables, iceberg=0
--   S3-B views                                        4
--   S3-B VW_SUPPLIER_RISK resolves SAP snapshot names compiled and ran
--   S3-C internal stages + CSV_FORMAT                 3 + 1
--   S3-C DEMO_SECRETS_STAGE is empty                  0
-- =============================================================================
USE ROLE ACCOUNTADMIN;
ALTER GIT REPOSITORY TRAINING_KIT_REPO.PUBLIC.GNN_KIT FETCH;

EXECUTE IMMEDIATE FROM @TRAINING_KIT_REPO.PUBLIC.GNN_KIT/branches/main/sql/stage3_demo_schema/30_database_schema.sql;
EXECUTE IMMEDIATE FROM @TRAINING_KIT_REPO.PUBLIC.GNN_KIT/branches/main/sql/stage3_demo_schema/31_stages_file_format.sql;
EXECUTE IMMEDIATE FROM @TRAINING_KIT_REPO.PUBLIC.GNN_KIT/branches/main/sql/stage3_demo_schema/32_tables.sql;
EXECUTE IMMEDIATE FROM @TRAINING_KIT_REPO.PUBLIC.GNN_KIT/branches/main/sql/stage3_demo_schema/33_views.sql;

EXECUTE IMMEDIATE FROM @TRAINING_KIT_REPO.PUBLIC.GNN_KIT/branches/main/sql/validation/v3_demo_schema.sql;
