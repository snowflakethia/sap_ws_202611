-- =============================================================================
-- Lab 3 reference solution - create your own agent with SQL
-- Modelled on the agents trainees built in F9A3UBGT (GNN_SUPPLY_RISK_AGENT_<userid>):
-- automatic model selection, the semantic view as an analyst tool, and the
-- contract search service. Run this only if you could not finish the Snowsight steps.
-- =============================================================================
USE ROLE DEMO_19865_ROLE;
USE WAREHOUSE DEMO_19865_WH;
USE SCHEMA DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK;

CREATE OR REPLACE AGENT DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.MY_SUPPLY_RISK_AGENT
    COMMENT = 'Lab 3 - trainee-built supply chain risk agent'
    PROFILE = '{"display_name": "My Supply Risk Agent"}'
    FROM SPECIFICATION
$$
models:
  orchestration: auto
instructions:
  response: "Answer briefly. Show supplier comparisons as a table."
  sample_questions:
    - question: "Which suppliers have a CRITICAL risk category?"
    - question: "Which contracts mention force majeure?"
tools:
  - tool_spec:
      type: cortex_analyst_text_to_sql
      name: GNN_SUPPLY_CHAIN_RISK_AGENT
      description: "This dataset focuses on supply chain risk management"
  - tool_spec:
      type: cortex_search
      name: GNN_CONTRACT_SEARCH_SERVICE
      description: "Contract search service analyzing contract details using CONTRACT_TEXT attribute (unstructured data)"
tool_resources:
  GNN_SUPPLY_CHAIN_RISK_AGENT:
    semantic_view: DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.SUPPLY_CHAIN_RISK_SEMANTIC_VIEW
    execution_environment:
      type: warehouse
      warehouse: DEMO_19865_WH
  GNN_CONTRACT_SEARCH_SERVICE:
    search_service: DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.CONTRACT_SEARCH_SERVICE
    id_column: CONTRACT_ID
    title_column: CONTRACT_TITLE
    max_results: 4
$$;

SHOW AGENTS IN SCHEMA DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK;
-- Expected: 2 rows - GNN_SUPPLY_RISK_AGENT and MY_SUPPLY_RISK_AGENT.
-- Clean up when finished: DROP AGENT DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.MY_SUPPLY_RISK_AGENT;
