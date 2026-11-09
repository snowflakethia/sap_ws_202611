# Lab 2 - Ask the agent

**Goal:** use `GNN_SUPPLY_RISK_AGENT`. It combines structured risk data (Cortex Analyst over the semantic view)
with unstructured supplier contracts (Cortex Search).
**Time:** 20 minutes. **Before you start:** `snowsight/08_readiness_check.sql` must say READY.

## Steps
1. Make sure your role is **ACCOUNTADMIN** (lower-left > Switch role).
2. Go to **AI & ML > Agents** and select **GNN_SUPPLY_RISK_AGENT**.
3. Ask the questions below one at a time. After each answer, expand the response details (the steps/"thinking"
   area) to see **which tool** was used, and the **SQL** or the **search results**.

| # | Ask exactly | Tool you should see | Expected answer |
| --- | --- | --- | --- |
| 1 | Which suppliers are CRITICAL risk? | `supply_chain_risk_analyst` | A table with **Albemarle Corp** and **Epsilon Tech** (both AUS, Tier 1, score about 0.61) |
| 2 | Which Tier 1 suppliers have a GNN risk score above 0.6? | `supply_chain_risk_analyst` | The **same 2 suppliers**. This question matches a *verified query* in the semantic view |
| 3 | What force majeure terms are in our supplier contracts? | `contract_search` | Quotes from contract text, with contract IDs and titles. 3 of the 12 contracts mention force majeure |
| 4 | For our HIGH and CRITICAL risk suppliers, what do their contracts say about supply obligations? | both, analyst first | The 6 HIGH/CRITICAL suppliers, then any matching contract details |
| 5 | Which materials have the highest GNN risk score? | `supply_chain_risk_analyst` | A ranked list of materials from `VW_MATERIAL_RISK` |

## Expected result
- 5 answers, with no error messages.
- Questions 1, 2 and 5 show generated SQL.
- Question 3 shows search results.
- Question 4 shows both.

## Discuss
1. Question 2 matches a verified query. Why does that make the answer more reliable?
2. In question 4, how does the agent match contracts to suppliers? What happens when a supplier has no contract?
3. What would you add to the agent's instructions to improve question 4?
