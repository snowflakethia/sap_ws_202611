# Lab 3 - Build your own agent

> **Disclaimer:** all data in this lab is **synthetic and for demonstration only**. Company names (for example
> Albemarle Corp, BYD Battery or Queensland Minerals) are used for illustration. The vendors, purchase orders,
> trade records, contracts, risk scores and predicted links are invented and **don't describe any real
> company, relationship or risk**. Don't use them for business decisions.

**Goal:** create an agent yourself in Snowsight, using the same semantic view and search service.
**Time:** 20 minutes. **Where:** Snowsight > AI > Agent Studio > **Create agent** (top-right).

In the original environment each trainee built a copy named `GNN_SUPPLY_RISK_AGENT_<userid>`.
You have your own account, so call yours `MY_SUPPLY_RISK_AGENT`.

## Steps

1. Switch role to `DEMO_19865_ROLE` (top-left role selector).
2. **Create agent**: database `DEMO_19865_DB`, schema `GNN_SUPPLY_CHAIN_RISK`,
   name `MY_SUPPLY_RISK_AGENT`, display name `My Supply Risk Agent`.
3. **Tools > Cortex Analyst > Add**
   - Semantic view: `DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.SUPPLY_CHAIN_RISK_SEMANTIC_VIEW`
   - Warehouse: `DEMO_19865_WH`
   - Name: `GNN_SUPPLY_CHAIN_RISK_AGENT`, description: "This dataset focuses on supply chain risk management"
4. **Tools > Cortex Search > Add**
   - Service: `DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.CONTRACT_SEARCH_SERVICE`
   - ID column `CONTRACT_ID`, title column `CONTRACT_TITLE`
   - Name: `GNN_CONTRACT_SEARCH_SERVICE`
5. **Orchestration**: leave the model on *auto*. Add a response instruction such as
   "Answer briefly. Show supplier comparisons as a table."
6. **Save**, then ask the questions from Lab 2 and compare with `GNN_SUPPLY_RISK_AGENT`.

## Expected outcome
- `SHOW AGENTS IN SCHEMA DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK;` returns 2 agents.
- Your agent answers the analyst and contract questions. Answers may be less structured than the
  main agent's, because it has no orchestration instructions telling it which tool to use when.

## Stuck?
Run `labs/lab3_solution_my_agent.sql`, which creates the same agent with SQL.

## Clean up
```sql
DROP AGENT DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.MY_SUPPLY_RISK_AGENT;
```
