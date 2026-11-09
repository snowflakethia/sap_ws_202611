-- =============================================================================
-- Validation - Stage 2 (SAP snapshot). Read-only.
-- =============================================================================
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE DEMO_19865_WH;

SHOW DATABASES LIKE 'S4_Z%_DP_DELTA_SHARING_V1';
SET V_DBS = (SELECT COUNT_IF("kind" = 'STANDARD') || '/' || COUNT(*) FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));

WITH c AS (
    SELECT 'vendors' AS T, 50 AS EXPECTED, (SELECT COUNT(*) FROM S4_ZVENDORINFO_DP_DELTA_SHARING_V1."s4_zvendorinfo_dp_srv:v1"."s4custom_vendors") AS ACTUAL
    UNION ALL SELECT 'materials', 26, (SELECT COUNT(*) FROM S4_ZMATERIALS_DP_DELTA_SHARING_V1."s4_zmaterials_dp_srv:v1"."s4custom_materials")
    UNION ALL SELECT 'purchase_orders', 120, (SELECT COUNT(*) FROM S4_ZPURCHASEORDERS_DP_DELTA_SHARING_V1."s4_zpurchaseorders_dp_srv:v1"."s4custom_purchase_orders")
    UNION ALL SELECT 'billofmaterials', 23, (SELECT COUNT(*) FROM S4_ZBILLOFMATERIALS_DP_DELTA_SHARING_V1."s4_zbillofmaterials_dp_srv:v1"."s4custom_billofmaterials")
),
v AS (
    SELECT COUNT(*) AS N, COUNT(VENDOR_ID) AS IDS, COUNT(NAME) AS NAMES, COUNT(COUNTRY_CODE) AS CC, COUNT(TIER) AS TIERS
    FROM S4_ZVENDORINFO_DP_DELTA_SHARING_V1."s4_zvendorinfo_dp_srv:v1"."s4custom_vendors"
)
SELECT 'S2-A 4 SAP snapshot databases, kind STANDARD' AS CHECK_NAME, '4/4' AS EXPECTED, $V_DBS AS ACTUAL,
       IFF($V_DBS = '4/4', 'PASS', 'FAIL') AS RESULT
UNION ALL
SELECT 'S2-B rows ' || T, EXPECTED::VARCHAR, ACTUAL::VARCHAR, IFF(ACTUAL = EXPECTED, 'PASS', 'FAIL') FROM c
UNION ALL
SELECT 'S2-B rows TOTAL', '219', (SELECT SUM(ACTUAL) FROM c)::VARCHAR, IFF((SELECT SUM(ACTUAL) FROM c) = 219, 'PASS', 'FAIL')
UNION ALL
SELECT 'S2-C vendor columns populated (id/name/country/tier)', '50/50/50/50',
       IDS || '/' || NAMES || '/' || CC || '/' || TIERS,
       IFF(IDS = 50 AND NAMES = 50 AND CC = 50 AND TIERS = 50, 'PASS', 'FAIL') FROM v;
