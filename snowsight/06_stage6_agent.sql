-- =============================================================================
-- STAGE 6 - Cortex Agent GNN_SUPPLY_RISK_AGENT
-- =============================================================================
-- Run All. Role: ACCOUNTADMIN. Takes under 1 minute.
--
-- CHECKPOINT 5, part 1 (expected result of the LAST statement - every row PASS):
--   S6-A agents in schema                         1:GNN_SUPPLY_RISK_AGENT
--   S6-B tools                                    supply_chain_risk_analyst,contract_search
--   S6-B analyst tool -> semantic view + warehouse ...SUPPLY_CHAIN_RISK_SEMANTIC_VIEW @ DEMO_19865_WH
--   S6-B search tool -> service / max_results     ...CONTRACT_SEARCH_SERVICE / 4
--   S6-B instructions present                     true/true
-- CHECKPOINT 5, part 2 (in the UI - see snowsight/README.md):
--   AI & ML > Agents > GNN_SUPPLY_RISK_AGENT, ask "Which suppliers are CRITICAL risk?"
--   Expected: Albemarle Corp and Epsilon Tech (both AUS, GNN risk score about 0.61).
-- =============================================================================
USE ROLE ACCOUNTADMIN;
ALTER GIT REPOSITORY TRAINING_KIT_REPO.PUBLIC.GNN_KIT FETCH;

EXECUTE IMMEDIATE FROM @TRAINING_KIT_REPO.PUBLIC.GNN_KIT/branches/main/sql/stage6_agent/60_agent.sql;

-- CHECKPOINT 5 (part 1)
EXECUTE IMMEDIATE FROM @TRAINING_KIT_REPO.PUBLIC.GNN_KIT/branches/main/sql/validation/v6_agent.sql;
