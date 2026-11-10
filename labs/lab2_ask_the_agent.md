# Lab 2 - Ask the agent

> [!CAUTION]
> **Disclaimer:** all data in this lab is **synthetic and for demonstration only**. Company names (for example
> Albemarle Corp, BYD Battery or Queensland Minerals) are used for illustration. The vendors, purchase orders,
> trade records, contracts, risk scores and predicted links are invented and **don't describe any real
> company, relationship or risk**. Don't use them for business decisions.

**Goal:** use `GNN_SUPPLY_RISK_AGENT`, which combines structured risk data (Cortex Analyst over the
semantic view) with unstructured contracts (Cortex Search).
**Time:** 20 minutes. **Where:** Snowsight > AI > Agent Studio > Agents tab > `GNN_SUPPLY_RISK_AGENT`.

> [!TIP]
> **Key takeaway: one agent answers questions over numbers and contracts together, and every answer can be checked.**
> - **Cortex Analyst** turns questions into SQL over the semantic view; **Cortex Search** finds the relevant contract passages.
> - A **verified query** (question 2) means the answer was built from SQL a person approved in advance.
> - Don't trust the text alone: open the response details and read **the SQL and the sources** behind it.

## Questions to ask

| # | Question | Tool you should see used | What a good answer contains |
| --- | --- | --- | --- |
| 1 | Which suppliers are CRITICAL risk? | `supply_chain_risk_analyst` | A table with 2 suppliers, Albemarle Corp and Epsilon Tech (both AUS, Tier 1, GNN risk score about 0.61) |
| 2 | Which Tier 1 suppliers have a GNN risk score above 0.6? | `supply_chain_risk_analyst` | Uses the verified query; the same 2 suppliers as question 1 |
| 3 | What force majeure terms are in our supplier contracts? | `contract_search` | Quotes from contract text with contract IDs and titles; 3 of the 12 contracts mention force majeure |
| 4 | For our HIGH and CRITICAL risk suppliers, what do their contracts say about supply obligations? | both, analyst first | The 6 HIGH/CRITICAL suppliers first, then any matching contract details |
| 5 | Which materials have the highest GNN risk score? | `supply_chain_risk_analyst` | Ranked list of materials from `VW_MATERIAL_RISK` |

For each answer, open the response details and look at:
- **The SQL** generated for analyst questions. Does it query the view you expected?
- **The search results** for contract questions. Which contracts were returned?

## Questions to discuss
1. Question 2 is a *verified query* in the semantic view. How does that change the answer's reliability?
2. What would you add to the agent's orchestration instructions to improve question 4?
3. Contracts are matched to suppliers by name. What happens when a supplier has no contract in the data?
