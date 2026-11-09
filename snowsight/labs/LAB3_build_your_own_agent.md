# Lab 3 - Build your own agent

**Goal:** create an agent yourself in the Snowsight UI, using the same semantic view and search service.
**Time:** 20 minutes. **Before you start:** `snowsight/08_readiness_check.sql` must say READY.

## Steps
1. Switch your role to **DEMO_19865_ROLE** (lower-left: your name > Switch role).
2. Go to **AI & ML > Agents** and select **Create agent**.
   - Database: `DEMO_19865_DB`, schema: `GNN_SUPPLY_CHAIN_RISK`
   - Agent object name: `MY_SUPPLY_RISK_AGENT`, display name: `My Supply Risk Agent`
   - Select **Create agent**.
3. Open the new agent and select **Edit**.
4. **Tools > Cortex Analyst > + Add:**
   - Semantic view: `DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.SUPPLY_CHAIN_RISK_SEMANTIC_VIEW`
   - Warehouse: `DEMO_19865_WH`
   - Name: `GNN_SUPPLY_CHAIN_RISK_AGENT`, description: `This dataset focuses on supply chain risk management`
5. **Tools > Cortex Search Services > + Add:**
   - Service: `DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.CONTRACT_SEARCH_SERVICE`
   - ID column: `CONTRACT_ID`, title column: `CONTRACT_TITLE`
   - Name: `GNN_CONTRACT_SEARCH_SERVICE`
6. **Orchestration:** leave the model on *auto*. Under response instructions, enter:
   `Answer briefly. Show supplier comparisons as a table.`
7. Select **Save**.
8. Ask your agent questions 1 and 3 from Lab 2, then compare its answers with `GNN_SUPPLY_RISK_AGENT`.

## Expected result
- **AI & ML > Agents** lists **2 agents**: `GNN_SUPPLY_RISK_AGENT` and `MY_SUPPLY_RISK_AGENT`.
- Your agent answers both questions: Albemarle Corp and Epsilon Tech for question 1, contract quotes for question 3.
- Its answers may be less structured than the main agent's, because you didn't give it orchestration
  instructions saying which tool to use when.

## Stuck?
1. Open `labs/lab3_solution_my_agent.sql` in `gnn_training`, then select **Run All**.
2. It creates the same agent with SQL. Expected last result: 2 rows (the 2 agents).

## Clean up (optional)
Switch back to **ACCOUNTADMIN** before running the remaining labs or the removal script, then run:

```sql
DROP AGENT IF EXISTS DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.MY_SUPPLY_RISK_AGENT;
```
