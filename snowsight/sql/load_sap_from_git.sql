-- =============================================================================
-- Snowsight path - load the SAP snapshot CSVs from the Git repository
-- Same result as sql/stage2_sap_snapshot/22_sap_load.sql (CLI path), which reads @~ after PUT.
-- COPY INTO cannot read a Git repository directly, so COPY FILES stages the CSVs first.
-- TRUNCATE + COPY ... FORCE makes it safe to re-run.
-- =============================================================================
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE DEMO_19865_WH;

COPY FILES INTO @TRAINING_KIT_REPO.PUBLIC.KIT_FILES/sap/
    FROM @TRAINING_KIT_REPO.PUBLIC.GNN_KIT/branches/main/data/sap/;

TRUNCATE TABLE S4_ZVENDORINFO_DP_DELTA_SHARING_V1."s4_zvendorinfo_dp_srv:v1"."s4custom_vendors";
COPY INTO S4_ZVENDORINFO_DP_DELTA_SHARING_V1."s4_zvendorinfo_dp_srv:v1"."s4custom_vendors"
    FROM @TRAINING_KIT_REPO.PUBLIC.KIT_FILES/sap/s4custom_vendors.csv
    FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"' NULL_IF = ('') EMPTY_FIELD_AS_NULL = TRUE)
    ON_ERROR = ABORT_STATEMENT FORCE = TRUE;

TRUNCATE TABLE S4_ZMATERIALS_DP_DELTA_SHARING_V1."s4_zmaterials_dp_srv:v1"."s4custom_materials";
COPY INTO S4_ZMATERIALS_DP_DELTA_SHARING_V1."s4_zmaterials_dp_srv:v1"."s4custom_materials"
    FROM @TRAINING_KIT_REPO.PUBLIC.KIT_FILES/sap/s4custom_materials.csv
    FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"' NULL_IF = ('') EMPTY_FIELD_AS_NULL = TRUE)
    ON_ERROR = ABORT_STATEMENT FORCE = TRUE;

TRUNCATE TABLE S4_ZPURCHASEORDERS_DP_DELTA_SHARING_V1."s4_zpurchaseorders_dp_srv:v1"."s4custom_purchase_orders";
COPY INTO S4_ZPURCHASEORDERS_DP_DELTA_SHARING_V1."s4_zpurchaseorders_dp_srv:v1"."s4custom_purchase_orders"
    FROM @TRAINING_KIT_REPO.PUBLIC.KIT_FILES/sap/s4custom_purchase_orders.csv
    FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"' NULL_IF = ('') EMPTY_FIELD_AS_NULL = TRUE)
    ON_ERROR = ABORT_STATEMENT FORCE = TRUE;

TRUNCATE TABLE S4_ZBILLOFMATERIALS_DP_DELTA_SHARING_V1."s4_zbillofmaterials_dp_srv:v1"."s4custom_billofmaterials";
COPY INTO S4_ZBILLOFMATERIALS_DP_DELTA_SHARING_V1."s4_zbillofmaterials_dp_srv:v1"."s4custom_billofmaterials"
    FROM @TRAINING_KIT_REPO.PUBLIC.KIT_FILES/sap/s4custom_billofmaterials.csv
    FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"' NULL_IF = ('') EMPTY_FIELD_AS_NULL = TRUE)
    ON_ERROR = ABORT_STATEMENT FORCE = TRUE;
