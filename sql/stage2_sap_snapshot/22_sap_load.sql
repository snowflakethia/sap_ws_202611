-- =============================================================================
-- Stage 2.2 - SAP data product snapshot: load
-- =============================================================================
-- deploy.sh uploads data/sap/*.csv to the user stage @~/training_kit/sap/ first.
-- TRUNCATE + COPY with FORCE makes the stage safe to re-run (no duplicates).
-- Expected rows: vendors 50, materials 26, purchase orders 120, BOM 23 (total 219).
-- =============================================================================
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE DEMO_19865_WH;

TRUNCATE TABLE S4_ZVENDORINFO_DP_DELTA_SHARING_V1."s4_zvendorinfo_dp_srv:v1"."s4custom_vendors";
COPY INTO S4_ZVENDORINFO_DP_DELTA_SHARING_V1."s4_zvendorinfo_dp_srv:v1"."s4custom_vendors"
    FROM @~/training_kit/sap/s4custom_vendors.csv
    FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"' NULL_IF = ('') EMPTY_FIELD_AS_NULL = TRUE) ON_ERROR = ABORT_STATEMENT FORCE = TRUE;

TRUNCATE TABLE S4_ZMATERIALS_DP_DELTA_SHARING_V1."s4_zmaterials_dp_srv:v1"."s4custom_materials";
COPY INTO S4_ZMATERIALS_DP_DELTA_SHARING_V1."s4_zmaterials_dp_srv:v1"."s4custom_materials"
    FROM @~/training_kit/sap/s4custom_materials.csv
    FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"' NULL_IF = ('') EMPTY_FIELD_AS_NULL = TRUE) ON_ERROR = ABORT_STATEMENT FORCE = TRUE;

TRUNCATE TABLE S4_ZPURCHASEORDERS_DP_DELTA_SHARING_V1."s4_zpurchaseorders_dp_srv:v1"."s4custom_purchase_orders";
COPY INTO S4_ZPURCHASEORDERS_DP_DELTA_SHARING_V1."s4_zpurchaseorders_dp_srv:v1"."s4custom_purchase_orders"
    FROM @~/training_kit/sap/s4custom_purchase_orders.csv
    FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"' NULL_IF = ('') EMPTY_FIELD_AS_NULL = TRUE) ON_ERROR = ABORT_STATEMENT FORCE = TRUE;

TRUNCATE TABLE S4_ZBILLOFMATERIALS_DP_DELTA_SHARING_V1."s4_zbillofmaterials_dp_srv:v1"."s4custom_billofmaterials";
COPY INTO S4_ZBILLOFMATERIALS_DP_DELTA_SHARING_V1."s4_zbillofmaterials_dp_srv:v1"."s4custom_billofmaterials"
    FROM @~/training_kit/sap/s4custom_billofmaterials.csv
    FILE_FORMAT = (TYPE = CSV SKIP_HEADER = 1 FIELD_OPTIONALLY_ENCLOSED_BY = '"' NULL_IF = ('') EMPTY_FIELD_AS_NULL = TRUE) ON_ERROR = ABORT_STATEMENT FORCE = TRUE;
