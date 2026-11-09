-- =============================================================================
-- Stage 3.1 - Stages and file format
-- Source: workspace SQL/02_schema_setup.sql (sections 1 and 6), GET_DDL(CSV_FORMAT)
-- =============================================================================
USE ROLE DEMO_19865_ROLE;
USE WAREHOUSE DEMO_19865_WH;
USE SCHEMA DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK;

CREATE STAGE IF NOT EXISTS MODELS_STAGE
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = 'Stage for ML models and notebooks';

CREATE STAGE IF NOT EXISTS DATA_STAGE
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = 'Stage for data files';

-- Intentionally left EMPTY. Kept for parity with the source; nothing in the kit reads it.
-- Never upload real credentials here.
CREATE STAGE IF NOT EXISTS DEMO_SECRETS_STAGE
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = 'Stage for secret';

CREATE FILE FORMAT IF NOT EXISTS CSV_FORMAT
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    NULL_IF = ('NULL', 'null', '')
    EMPTY_FIELD_AS_NULL = TRUE;
