-- =============================================================================
-- STAGE 4 - Demo data: inputs + precomputed GNN outputs (648 rows)
-- =============================================================================
-- Run All. Role: ACCOUNTADMIN (the load switches to DEMO_19865_ROLE). Takes about 1 minute.
--
-- CHECKPOINT 3 (expected result of the LAST statement - every row PASS):
--   S4-A rows: BOTTLENECKS 10, CUSTOMER_CONTRACTS 12, REGIONS 9, RISK_SCORES 86,
--              SUPPLIER_LINKS 381, TRADE 150, TOTAL 648
--   S4-B VW_RISK_SUMMARY SUPPLIERS   50/2/4/0.4060   (total/critical/high/avg score)
--   S4-B VW_RISK_SUMMARY PARTS       26/0/0/0.4768
--   S4-C VW_SUPPLIER_RISK 50, VW_MATERIAL_RISK 26, VW_HIDDEN_DEPENDENCIES 26, EMBEDDING = ARRAY
-- =============================================================================
USE ROLE ACCOUNTADMIN;
ALTER GIT REPOSITORY TRAINING_KIT_REPO.PUBLIC.GNN_KIT FETCH;
USE WAREHOUSE DEMO_19865_WH;

-- Stage the CSVs where the shared load script expects them (the CLI path uses PUT instead).
COPY FILES INTO @DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.DATA_STAGE/training_kit/
    FROM @TRAINING_KIT_REPO.PUBLIC.GNN_KIT/branches/main/data/demo/;

EXECUTE IMMEDIATE FROM @TRAINING_KIT_REPO.PUBLIC.GNN_KIT/branches/main/sql/stage4_demo_data/40_load_demo_data.sql;

-- CHECKPOINT 3
EXECUTE IMMEDIATE FROM @TRAINING_KIT_REPO.PUBLIC.GNN_KIT/branches/main/sql/validation/v4_demo_data.sql;
