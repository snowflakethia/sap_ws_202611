-- =============================================================================
-- Stage 6 - Cortex Agent GNN_SUPPLY_RISK_AGENT
-- Source: DESCRIBE AGENT on F9A3UBGT, default version VERSION$2 (generated from
-- extract/raw/agent_spec.json - do not hand-edit; re-run the extract instead).
-- Tools: supply_chain_risk_analyst (semantic view) + contract_search (Cortex Search).
-- Only the main agent is created. The 5 per-trainee copies in F9A3UBGT
-- (GNN_SUPPLY_RISK_AGENT_<userid>) are replaced by labs/lab3_build_your_own_agent.md.
-- =============================================================================
USE ROLE DEMO_19865_ROLE;
USE WAREHOUSE DEMO_19865_WH;
USE SCHEMA DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK;

CREATE OR REPLACE AGENT DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.GNN_SUPPLY_RISK_AGENT
    COMMENT = 'Analyzes supply chain risk using the SUPPLY_CHAIN_RISK_SEMANTIC_VIEW in DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK. Queries supplier risk scores, network topology, cascading failure scenarios, and risk factor breakdowns via Cortex Analyst. Searches supplier contract documents in CONTRACT_SEARCH_SERVICE for terms, SLA obligations, penalty clauses, and force majeure provisions. Use this agent for quantitative risk assessment, supplier comparison, network vulnerability analysis, and contract due diligence. Does not handle procurement workflows, order management, or logistics operations.'
    PROFILE = '{"display_name":"GNN_SUPPLY_RISK_AGENT"}'
    FROM SPECIFICATION
$$
{
  "instructions": {
    "response": "Be direct and analytical. Lead with the key finding or metric, then provide supporting detail. Use tables for multi-supplier comparisons. When reporting risk scores, always include the risk level classification and the top contributing factors. Flag critical risks (scores above threshold) prominently. Avoid hedging language — state findings clearly and note data limitations only when material. Use bullet points for action items or risk factor lists.",
    "orchestration": "Use the supply_chain_risk_analyst tool for any question about risk scores, supplier metrics, network topology, cascading failure analysis, or quantitative risk data. Use the contract_search tool when the user asks about specific contract terms, SLA obligations, penalty clauses, force majeure provisions, or supplier agreement details. When a question involves both risk data and contract context (e.g. \"which high-risk suppliers have expiring contracts?\"), query the analyst tool first for the risk data, then use contract_search to enrich with relevant contract details."
  },
  "tools": [
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "supply_chain_risk_analyst",
        "description": "Query supply chain risk data including supplier risk scores, network analysis, and risk factors"
      }
    },
    {
      "tool_spec": {
        "type": "cortex_search",
        "name": "contract_search",
        "description": "Search supplier contract documents for terms, clauses, and contract details"
      }
    }
  ],
  "tool_resources": {
    "supply_chain_risk_analyst": {
      "execution_environment": {
        "type": "warehouse",
        "warehouse": "DEMO_19865_WH"
      },
      "semantic_view": "DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.SUPPLY_CHAIN_RISK_SEMANTIC_VIEW"
    },
    "contract_search": {
      "search_service": "DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.CONTRACT_SEARCH_SERVICE",
      "id_column": "CONTRACT_ID",
      "title_column": "CONTRACT_TITLE",
      "max_results": 4
    }
  }
}
$$;
