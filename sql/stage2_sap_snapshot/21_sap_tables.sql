-- =============================================================================
-- Stage 2.1 - SAP data product snapshot: tables
-- =============================================================================
-- Column names and types taken from DESCRIBE TABLE on the F9A3UBGT Iceberg tables.
-- Source VARCHAR(134217728) is the Iceberg string type; standard tables use VARCHAR.
-- =============================================================================
USE ROLE ACCOUNTADMIN;

CREATE TABLE IF NOT EXISTS S4_ZVENDORINFO_DP_DELTA_SHARING_V1."s4_zvendorinfo_dp_srv:v1"."s4custom_vendors" (
    VENDOR_ID              VARCHAR NOT NULL,
    NAME                   VARCHAR,
    COUNTRY_CODE           VARCHAR,
    CITY                   VARCHAR,
    PHONE                  VARCHAR,
    TIER                   NUMBER(20,0),
    FINANCIAL_HEALTH_SCORE NUMBER(38,19),
    PRIMARY KEY (VENDOR_ID) RELY
) COMMENT = 'SNAPSHOT of SAP s4custom_vendors (vendor master)';

CREATE TABLE IF NOT EXISTS S4_ZMATERIALS_DP_DELTA_SHARING_V1."s4_zmaterials_dp_srv:v1"."s4custom_materials" (
    MATERIAL_ID       VARCHAR NOT NULL,
    DESCRIPTION       VARCHAR,
    MATERIAL_GROUP    VARCHAR,
    UNIT_OF_MEASURE   VARCHAR,
    CRITICALITY_SCORE NUMBER(38,19),
    INVENTORY_DAYS    NUMBER(20,0),
    PRIMARY KEY (MATERIAL_ID) RELY
) COMMENT = 'SNAPSHOT of SAP s4custom_materials (material master)';

CREATE TABLE IF NOT EXISTS S4_ZPURCHASEORDERS_DP_DELTA_SHARING_V1."s4_zpurchaseorders_dp_srv:v1"."s4custom_purchase_orders" (
    PO_ID         VARCHAR NOT NULL,
    VENDOR_ID     VARCHAR,
    MATERIAL_ID   VARCHAR,
    QUANTITY      NUMBER(20,0),
    UNIT_PRICE    NUMBER(38,19),
    ORDER_DATE    DATE,
    DELIVERY_DATE DATE,
    STATUS        VARCHAR,
    PRIMARY KEY (PO_ID) RELY
) COMMENT = 'SNAPSHOT of SAP s4custom_purchase_orders';

CREATE TABLE IF NOT EXISTS S4_ZBILLOFMATERIALS_DP_DELTA_SHARING_V1."s4_zbillofmaterials_dp_srv:v1"."s4custom_billofmaterials" (
    BOM_ID             VARCHAR NOT NULL,
    PARENT_MATERIAL_ID VARCHAR,
    CHILD_MATERIAL_ID  VARCHAR,
    QUANTITY_PER_UNIT  NUMBER(38,19),
    PRIMARY KEY (BOM_ID) RELY
) COMMENT = 'SNAPSHOT of SAP s4custom_billofmaterials';

GRANT SELECT ON TABLE S4_ZVENDORINFO_DP_DELTA_SHARING_V1."s4_zvendorinfo_dp_srv:v1"."s4custom_vendors"                   TO ROLE DEMO_19865_ROLE;
GRANT SELECT ON TABLE S4_ZMATERIALS_DP_DELTA_SHARING_V1."s4_zmaterials_dp_srv:v1"."s4custom_materials"                   TO ROLE DEMO_19865_ROLE;
GRANT SELECT ON TABLE S4_ZPURCHASEORDERS_DP_DELTA_SHARING_V1."s4_zpurchaseorders_dp_srv:v1"."s4custom_purchase_orders"   TO ROLE DEMO_19865_ROLE;
GRANT SELECT ON TABLE S4_ZBILLOFMATERIALS_DP_DELTA_SHARING_V1."s4_zbillofmaterials_dp_srv:v1"."s4custom_billofmaterials" TO ROLE DEMO_19865_ROLE;
