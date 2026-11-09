-- =============================================================================
-- Validation - Stage 3 (demo schema, before data load). Read-only.
-- =============================================================================
USE ROLE DEMO_19865_ROLE;
USE WAREHOUSE DEMO_19865_WH;

SHOW TABLES IN SCHEMA DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK;
SET V_TABLES = (SELECT COUNT(*) || ' tables, iceberg=' || COUNT_IF("is_iceberg" = 'Y') FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));

SHOW VIEWS IN SCHEMA DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK;
SET V_VIEWS = (SELECT COUNT(*) FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));

-- Fails with "does not exist or not authorized" if the SAP snapshot names do not resolve.
SELECT * FROM DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.VW_SUPPLIER_RISK LIMIT 1;
SET V_VIEW_RUNS = 'compiled and ran';

SHOW STAGES IN SCHEMA DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK;
SET V_STAGES = (SELECT COUNT_IF("type" = 'INTERNAL') FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));

SHOW FILE FORMATS LIKE 'CSV_FORMAT' IN SCHEMA DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK;
SET V_FF = (SELECT COUNT(*) FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));

LIST @DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.DEMO_SECRETS_STAGE;
SET V_SECRETS = (SELECT COUNT(*) FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));

SELECT 'S3-A tables (all standard)' AS CHECK_NAME, '6 tables, iceberg=0' AS EXPECTED, $V_TABLES AS ACTUAL,
       IFF($V_TABLES = '6 tables, iceberg=0', 'PASS', 'FAIL') AS RESULT
UNION ALL
SELECT 'S3-B views', '4', $V_VIEWS::VARCHAR, IFF($V_VIEWS = 4, 'PASS', 'FAIL')
UNION ALL
SELECT 'S3-B VW_SUPPLIER_RISK resolves SAP snapshot names', 'compiled and ran', $V_VIEW_RUNS, 'PASS'
UNION ALL
SELECT 'S3-C internal stages + CSV_FORMAT', '3 + 1', $V_STAGES || ' + ' || $V_FF,
       IFF($V_STAGES = 3 AND $V_FF = 1, 'PASS', 'FAIL')
UNION ALL
SELECT 'S3-C DEMO_SECRETS_STAGE is empty', '0', $V_SECRETS::VARCHAR, IFF($V_SECRETS = 0, 'PASS', 'FAIL');
