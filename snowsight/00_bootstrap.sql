-- =============================================================================
-- STEP 0 - Bootstrap: connect this Snowflake account to the training GitHub repo
-- =============================================================================
-- HOW TO RUN (the only file you copy by hand):
--   1. In a browser tab, open https://raw.githubusercontent.com/snowflakethia/sap_ws_202611/main/snowsight/00_bootstrap.sql
--      then press Ctrl/Cmd + A (select all) and Ctrl/Cmd + C (copy).
--   2. In Snowsight: Projects > Workspaces > + Add new > SQL File, paste, then Run All.
--      (Classic UI: Projects > Worksheets > + > SQL Worksheet.)
--   3. Role: ACCOUNTADMIN. No warehouse is needed.
--
-- What it creates (all removed again by 99_remove_setup.sql):
--   API integration GNN_KIT_GITHUB          - lets Snowflake read the public GitHub repo
--   Database TRAINING_KIT_REPO              - holds the repo clone and a file stage
--   Git repository TRAINING_KIT_REPO.PUBLIC.GNN_KIT
--   Stage TRAINING_KIT_REPO.PUBLIC.KIT_FILES - staging area for the SAP CSV files
--
-- CHECKPOINT 0 (expected result of the LAST statement):
--   4 rows: s4custom_billofmaterials.csv, s4custom_materials.csv,
--           s4custom_purchase_orders.csv, s4custom_vendors.csv
-- Safe to re-run: it re-fetches the latest version of the repo.
-- =============================================================================
USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE API INTEGRATION GNN_KIT_GITHUB
    API_PROVIDER = git_https_api
    API_ALLOWED_PREFIXES = ('https://github.com/snowflakethia/')
    ENABLED = TRUE
    COMMENT = 'GNN Supply Chain Risk training - read access to the public GitHub repo';

CREATE DATABASE IF NOT EXISTS TRAINING_KIT_REPO
    COMMENT = 'GNN Supply Chain Risk training - GitHub repo clone and file staging';

CREATE GIT REPOSITORY IF NOT EXISTS TRAINING_KIT_REPO.PUBLIC.GNN_KIT
    API_INTEGRATION = GNN_KIT_GITHUB
    ORIGIN = 'https://github.com/snowflakethia/sap_ws_202611.git'
    COMMENT = 'GNN Supply Chain Risk training kit';

ALTER GIT REPOSITORY TRAINING_KIT_REPO.PUBLIC.GNN_KIT FETCH;

CREATE STAGE IF NOT EXISTS TRAINING_KIT_REPO.PUBLIC.KIT_FILES
    COMMENT = 'Data files copied from the Git repository before loading';

-- CHECKPOINT 0: expect exactly 4 CSV files.
LIST @TRAINING_KIT_REPO.PUBLIC.GNN_KIT/branches/main/data/sap/;
