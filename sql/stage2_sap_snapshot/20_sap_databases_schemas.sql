-- =============================================================================
-- Stage 2.0 - SAP data product snapshot: databases and schemas
-- =============================================================================
-- In F9A3UBGT these are CATALOG-LINKED databases over SAP BDC Delta Sharing.
-- A training account has no SAP BDC connection, so they are recreated as STANDARD
-- databases with the SAME database / schema / table names. The demo views,
-- semantic view and agent therefore work without any edits.
-- Schema and table names are lowercase and contain ':' - they MUST stay quoted.
-- =============================================================================
USE ROLE ACCOUNTADMIN;

CREATE DATABASE IF NOT EXISTS S4_ZVENDORINFO_DP_DELTA_SHARING_V1
    COMMENT = 'SNAPSHOT of SAP BDC data product s4_zvendorinfo_dp (training kit)';
CREATE DATABASE IF NOT EXISTS S4_ZMATERIALS_DP_DELTA_SHARING_V1
    COMMENT = 'SNAPSHOT of SAP BDC data product s4_zmaterials_dp (training kit)';
CREATE DATABASE IF NOT EXISTS S4_ZPURCHASEORDERS_DP_DELTA_SHARING_V1
    COMMENT = 'SNAPSHOT of SAP BDC data product s4_zpurchaseorders_dp (training kit)';
CREATE DATABASE IF NOT EXISTS S4_ZBILLOFMATERIALS_DP_DELTA_SHARING_V1
    COMMENT = 'SNAPSHOT of SAP BDC data product s4_zbillofmaterials_dp (training kit)';

CREATE SCHEMA IF NOT EXISTS S4_ZVENDORINFO_DP_DELTA_SHARING_V1."s4_zvendorinfo_dp_srv:v1";
CREATE SCHEMA IF NOT EXISTS S4_ZMATERIALS_DP_DELTA_SHARING_V1."s4_zmaterials_dp_srv:v1";
CREATE SCHEMA IF NOT EXISTS S4_ZPURCHASEORDERS_DP_DELTA_SHARING_V1."s4_zpurchaseorders_dp_srv:v1";
CREATE SCHEMA IF NOT EXISTS S4_ZBILLOFMATERIALS_DP_DELTA_SHARING_V1."s4_zbillofmaterials_dp_srv:v1";

-- The project role reads these through the demo views (read-only, like the source).
GRANT USAGE ON DATABASE S4_ZVENDORINFO_DP_DELTA_SHARING_V1     TO ROLE DEMO_19865_ROLE;
GRANT USAGE ON DATABASE S4_ZMATERIALS_DP_DELTA_SHARING_V1      TO ROLE DEMO_19865_ROLE;
GRANT USAGE ON DATABASE S4_ZPURCHASEORDERS_DP_DELTA_SHARING_V1 TO ROLE DEMO_19865_ROLE;
GRANT USAGE ON DATABASE S4_ZBILLOFMATERIALS_DP_DELTA_SHARING_V1 TO ROLE DEMO_19865_ROLE;

GRANT USAGE ON SCHEMA S4_ZVENDORINFO_DP_DELTA_SHARING_V1."s4_zvendorinfo_dp_srv:v1"           TO ROLE DEMO_19865_ROLE;
GRANT USAGE ON SCHEMA S4_ZMATERIALS_DP_DELTA_SHARING_V1."s4_zmaterials_dp_srv:v1"             TO ROLE DEMO_19865_ROLE;
GRANT USAGE ON SCHEMA S4_ZPURCHASEORDERS_DP_DELTA_SHARING_V1."s4_zpurchaseorders_dp_srv:v1"   TO ROLE DEMO_19865_ROLE;
GRANT USAGE ON SCHEMA S4_ZBILLOFMATERIALS_DP_DELTA_SHARING_V1."s4_zbillofmaterials_dp_srv:v1" TO ROLE DEMO_19865_ROLE;
