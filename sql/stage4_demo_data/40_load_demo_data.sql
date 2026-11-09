-- =============================================================================
-- Stage 4 - Load demo data (precomputed GNN outputs + inputs)
-- =============================================================================
-- deploy.sh uploads data/demo/*.csv to @DATA_STAGE/training_kit/ first.
-- ARRAY / VARIANT columns were exported as JSON text and are restored with PARSE_JSON.
-- Expected rows: regions 9, trade 150, contracts 12, risk scores 86,
--                supplier links 381, bottlenecks 10 (total 648).
-- =============================================================================
USE ROLE DEMO_19865_ROLE;
USE WAREHOUSE DEMO_19865_WH;
USE SCHEMA DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK;

TRUNCATE TABLE REGIONS_EXTERNAL;
COPY INTO REGIONS_EXTERNAL
    FROM @DATA_STAGE/training_kit/regions_external.csv
    FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT) ON_ERROR = ABORT_STATEMENT FORCE = TRUE;

TRUNCATE TABLE TRADE_DATA_EXTERNAL;
COPY INTO TRADE_DATA_EXTERNAL
    FROM @DATA_STAGE/training_kit/trade_data_external.csv
    FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT) ON_ERROR = ABORT_STATEMENT FORCE = TRUE;

TRUNCATE TABLE CUSTOMER_CONTRACTS;
COPY INTO CUSTOMER_CONTRACTS
    FROM @DATA_STAGE/training_kit/customer_contracts.csv
    FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT) ON_ERROR = ABORT_STATEMENT FORCE = TRUE;

TRUNCATE TABLE RISK_SCORES_PREDICTIONS;
COPY INTO RISK_SCORES_PREDICTIONS
    (SCORE_ID, NODE_ID, NODE_TYPE, RISK_SCORE, RISK_CATEGORY, CONFIDENCE,
     EMBEDDING, CONTRIBUTING_FACTORS, MODEL_VERSION, CALCULATED_AT)
FROM (
    SELECT $1, $2, $3, $4, $5, $6,
           PARSE_JSON($7)::ARRAY, PARSE_JSON($8), $9, $10
    FROM @DATA_STAGE/training_kit/risk_scores_predictions.csv
)
FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT) ON_ERROR = ABORT_STATEMENT FORCE = TRUE;

TRUNCATE TABLE SUPPLIER_LINKS_PREDICTIONS;
COPY INTO SUPPLIER_LINKS_PREDICTIONS
    FROM @DATA_STAGE/training_kit/supplier_links_predictions.csv
    FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT) ON_ERROR = ABORT_STATEMENT FORCE = TRUE;

TRUNCATE TABLE BOTTLENECKS_PREDICTIONS;
COPY INTO BOTTLENECKS_PREDICTIONS
    (BOTTLENECK_ID, NODE_ID, NODE_TYPE, DEPENDENT_COUNT, DEPENDENT_NODES,
     IMPACT_SCORE, DESCRIPTION, MITIGATION_STATUS, IDENTIFIED_AT)
FROM (
    SELECT $1, $2, $3, $4, PARSE_JSON($5)::ARRAY, $6, $7, $8, $9
    FROM @DATA_STAGE/training_kit/bottlenecks_predictions.csv
)
FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT) ON_ERROR = ABORT_STATEMENT FORCE = TRUE;
