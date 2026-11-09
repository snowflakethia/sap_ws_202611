-- =============================================================================
-- Validation - Stage 5 (Cortex Search + semantic view). Read-only.
-- Search indexing can take a few minutes: re-run until S5-A shows ACTIVE/ACTIVE.
-- =============================================================================
USE ROLE DEMO_19865_ROLE;
USE WAREHOUSE DEMO_19865_WH;
USE SCHEMA DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK;

SHOW CORTEX SEARCH SERVICES LIKE 'CONTRACT_SEARCH_SERVICE' IN SCHEMA DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK;
SET V_SEARCH = (SELECT MAX("search_column" || ' ' || "indexing_state" || '/' || "serving_state")
                FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));

SHOW SEMANTIC VIEWS LIKE 'SUPPLY_CHAIN_RISK_SEMANTIC_VIEW' IN SCHEMA DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK;
SET V_SV = (SELECT COUNT(*) FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));

DESCRIBE SEMANTIC VIEW DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.SUPPLY_CHAIN_RISK_SEMANTIC_VIEW;
SET V_SV_PARTS = (SELECT COUNT_IF("object_kind" = 'TABLE' AND "property" = 'BASE_TABLE_NAME') || ' tables, '
                      || COUNT_IF("object_kind" = 'FACT' AND "property" = 'DATA_TYPE') || ' facts, '
                      || COUNT_IF("object_kind" = 'DIMENSION' AND "property" = 'DATA_TYPE') || ' dimensions'
                  FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));

WITH hits AS (
    SELECT PARSE_JSON(SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
        'DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.CONTRACT_SEARCH_SERVICE',
        '{"query": "force majeure", "columns": ["CONTRACT_ID", "CONTRACT_TITLE"], "limit": 3}'
    )):results AS R
),
sv AS (
    SELECT * FROM SEMANTIC_VIEW(
        DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.SUPPLY_CHAIN_RISK_SEMANTIC_VIEW
        DIMENSIONS VW_SUPPLIER_RISK.VENDOR_ID, VW_SUPPLIER_RISK.RISK_CATEGORY
    )
)
SELECT 'S5-A search service column + indexing/serving state' AS CHECK_NAME, 'CONTRACT_TEXT ACTIVE/ACTIVE' AS EXPECTED,
       COALESCE($V_SEARCH, 'missing') AS ACTUAL,
       IFF($V_SEARCH = 'CONTRACT_TEXT ACTIVE/ACTIVE', 'PASS', 'WAIT - re-run in a few minutes') AS RESULT
UNION ALL
SELECT 'S5-A semantic view exists', '1', $V_SV::VARCHAR, IFF($V_SV = 1, 'PASS', 'FAIL')
UNION ALL
SELECT 'S5-B search "force majeure" returns contracts', '1-3 results with CONTRACT_ID',
       ARRAY_SIZE(R) || ' results, first=' || COALESCE(R[0]:CONTRACT_ID::VARCHAR, 'none'),
       IFF(ARRAY_SIZE(R) BETWEEN 1 AND 3 AND R[0]:CONTRACT_ID IS NOT NULL, 'PASS', 'FAIL') FROM hits
UNION ALL
SELECT 'S5-C semantic view structure', '4 tables, 9 facts, 26 dimensions', $V_SV_PARTS,
       IFF($V_SV_PARTS = '4 tables, 9 facts, 26 dimensions', 'PASS', 'FAIL')
UNION ALL
SELECT 'S5-C semantic view query (rows by supplier RISK_CATEGORY)', '50 rows: CRITICAL 2, HIGH 4, MEDIUM 44',
       COUNT(*) || ' rows: CRITICAL ' || COUNT_IF(RISK_CATEGORY = 'CRITICAL') || ', HIGH ' || COUNT_IF(RISK_CATEGORY = 'HIGH')
           || ', MEDIUM ' || COUNT_IF(RISK_CATEGORY = 'MEDIUM'),
       IFF(COUNT(*) = 50 AND COUNT_IF(RISK_CATEGORY = 'CRITICAL') = 2 AND COUNT_IF(RISK_CATEGORY = 'HIGH') = 4, 'PASS', 'FAIL')
FROM sv;
