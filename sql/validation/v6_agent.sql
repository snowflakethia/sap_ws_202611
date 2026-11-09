-- =============================================================================
-- Validation - Stage 6 (agent). Read-only.
-- Check C (asking the agent questions) is done by a person in Snowsight; see SETUP_GUIDE.md.
-- =============================================================================
USE ROLE DEMO_19865_ROLE;
USE WAREHOUSE DEMO_19865_WH;

SHOW AGENTS IN SCHEMA DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK;
SET V_AGENTS = (SELECT COUNT(*) || ':' || COALESCE(LISTAGG("name", ','), '') FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));

DESCRIBE AGENT DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.GNN_SUPPLY_RISK_AGENT;
SET V_SPEC = (SELECT MAX("agent_spec") FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));

WITH s AS (SELECT PARSE_JSON($V_SPEC) AS J)
SELECT 'S6-A agents in schema' AS CHECK_NAME, '1:GNN_SUPPLY_RISK_AGENT' AS EXPECTED, $V_AGENTS AS ACTUAL,
       IFF($V_AGENTS = '1:GNN_SUPPLY_RISK_AGENT', 'PASS', 'INFO - extra agents present (e.g. from lab 3)') AS RESULT
UNION ALL
SELECT 'S6-B tools', 'supply_chain_risk_analyst,contract_search',
       J:tools[0]:tool_spec:name::VARCHAR || ',' || J:tools[1]:tool_spec:name::VARCHAR,
       IFF(J:tools[0]:tool_spec:name::VARCHAR || ',' || J:tools[1]:tool_spec:name::VARCHAR
           = 'supply_chain_risk_analyst,contract_search', 'PASS', 'FAIL') FROM s
UNION ALL
SELECT 'S6-B analyst tool -> semantic view + warehouse',
       'DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.SUPPLY_CHAIN_RISK_SEMANTIC_VIEW @ DEMO_19865_WH',
       J:tool_resources:supply_chain_risk_analyst:semantic_view::VARCHAR || ' @ '
           || J:tool_resources:supply_chain_risk_analyst:execution_environment:warehouse::VARCHAR,
       IFF(J:tool_resources:supply_chain_risk_analyst:semantic_view::VARCHAR = 'DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.SUPPLY_CHAIN_RISK_SEMANTIC_VIEW'
           AND J:tool_resources:supply_chain_risk_analyst:execution_environment:warehouse::VARCHAR = 'DEMO_19865_WH', 'PASS', 'FAIL') FROM s
UNION ALL
SELECT 'S6-B search tool -> service / max_results',
       'DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.CONTRACT_SEARCH_SERVICE / 4',
       J:tool_resources:contract_search:search_service::VARCHAR || ' / ' || J:tool_resources:contract_search:max_results::VARCHAR,
       IFF(J:tool_resources:contract_search:search_service::VARCHAR = 'DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.CONTRACT_SEARCH_SERVICE'
           AND J:tool_resources:contract_search:max_results::INT = 4, 'PASS', 'FAIL') FROM s
UNION ALL
SELECT 'S6-B instructions present (response/orchestration)', 'true/true',
       (J:instructions:response IS NOT NULL)::VARCHAR || '/' || (J:instructions:orchestration IS NOT NULL)::VARCHAR,
       IFF(J:instructions:response IS NOT NULL AND J:instructions:orchestration IS NOT NULL, 'PASS', 'FAIL') FROM s;
