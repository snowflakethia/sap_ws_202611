# Lab 3 - Build your own agent: what makes an agent good?

> **In Lab 2 the agent seemed to "just know" when to query data and when to read contracts. It doesn't.** That
> behaviour comes from a few lines of configuration that someone wrote. In this lab you build an agent from the
> same parts, without those lines, and ask it the same questions. The difference you see is the difference
> between a demo and a production agent.

**Time:** 20 minutes. **Before you start:** `snowsight/08_readiness_check.sql` must say READY.

**What you'll learn**
- The building blocks of a Cortex Agent: **tools**, **tool resources**, and **instructions**.
- How to connect a semantic view (Cortex Analyst) and a search service (Cortex Search) to an agent.
- Why **orchestration instructions** matter, by comparing your agent with the tuned one.

---

## Steps

1. **Switch your user-menu role to `DEMO_19865_ROLE`** (bottom-left: your name > Switch role).
   *Why:* the agent is created in the demo schema, which this role owns. Agents use the privileges of the role
   that runs them, and this role can read the semantic view and the search service.

2. **Create the agent.** In the left navigation, hover over **AI** > **Agent Studio**, then click the blue
   **Create agent** button (top-right):
   - Database `DEMO_19865_DB`, schema `GNN_SUPPLY_CHAIN_RISK`
   - Agent object name `MY_SUPPLY_RISK_AGENT`, display name `My Supply Risk Agent`
   - Click **Create agent**, then open the new agent and click **Edit**.

   *Why:* an agent is a Snowflake object, like a table. It lives in a schema, has an owner, and can be granted
   to other roles.

3. **Add tool 1: Cortex Analyst** (**Tools > Cortex Analyst > + Add**):

   | Field | Value | What it means |
   | --- | --- | --- |
   | Semantic view | `DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.SUPPLY_CHAIN_RISK_SEMANTIC_VIEW` | The business layer the agent writes SQL against |
   | Warehouse | `DEMO_19865_WH` | The compute that runs the generated SQL |
   | Name | `GNN_SUPPLY_CHAIN_RISK_AGENT` | How the agent refers to this tool internally |
   | Description | `This dataset focuses on supply chain risk management` | **The agent reads this to decide when to use the tool**, so write it for the LLM, not for people |

4. **Add tool 2: Cortex Search** (**Tools > Cortex Search Services > + Add**):

   | Field | Value | What it means |
   | --- | --- | --- |
   | Search service | `DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.CONTRACT_SEARCH_SERVICE` | The index over the 12 supplier contracts |
   | ID column | `CONTRACT_ID` | Lets the agent cite *which* contract a passage came from |
   | Title column | `CONTRACT_TITLE` | A readable label for each citation |
   | Name | `GNN_CONTRACT_SEARCH_SERVICE` | Internal tool name |

5. **Orchestration:** leave the model on **auto** (Snowflake picks a suitable model). Under **response
   instructions**, enter:
   `Answer briefly. Show supplier comparisons as a table.`
   **Leave the orchestration instructions empty.** That's the experiment.
   *Why:* response instructions control **how answers look**. Orchestration instructions control **which tool to
   use, when, and in what order**. The main agent has both; yours has only the first.

6. Click **Save**.

7. **Run the experiment.** Open each agent's **Preview** tab (AI > Agent Studio > click the agent > **Preview**). Ask your agent these two questions from Lab 2, then ask `GNN_SUPPLY_RISK_AGENT` the
   same ones and compare:
   - *Which suppliers are CRITICAL risk?*
   - *Which external suppliers have the strongest predicted hidden links to our suppliers, and what do our
     contracts with them say about force majeure?*

---

## Expected result
- **AI > Agent Studio** (**Agents** tab) lists **2 agents**: `GNN_SUPPLY_RISK_AGENT` and `MY_SUPPLY_RISK_AGENT`.
- **Question 1:** both agents name **Albemarle Corp** and **Epsilon Tech**. A simple, single-tool question
  doesn't need instructions.
- **Question 2:** your agent may call only one tool, call them in a different order, or give a less complete
  answer. The main agent follows its instruction: *analyst first, then search*. Results vary because LLMs
  aren't deterministic, so compare the **steps** each agent took, not just the final text.

## What to take away
| Setting | Controls | Main agent | Your agent |
| --- | --- | --- | --- |
| Tool descriptions | *Whether* a tool looks relevant | Specific ("Query supply chain risk data including supplier risk scores...") | Generic |
| Orchestration instructions | *Which* tool, *when*, *in what order* | Yes | **None** |
| Response instructions | *How* the answer is formatted | Yes (lead with the key finding, use tables, flag critical risks) | Short |

## Stuck?
1. In **gnn_training**, open `labs/lab3_solution_my_agent.sql` and click **Run All**.
2. *What it does:* `CREATE OR REPLACE AGENT ... FROM SPECIFICATION $$ ... $$` creates the same agent from a YAML
   specification: the model, instructions, tools and tool resources, written as code instead of clicked in the UI.
3. *Expected last result:* **2 rows** (the 2 agents).
4. *Why it's useful:* specifications in SQL can be version-controlled and deployed like any other code. That's
   how the main agent was created in this course (`sql/stage6_agent/60_agent.sql`).

## Clean up (optional)
Switch your user-menu role back to **ACCOUNTADMIN**, then run:

```sql
DROP AGENT IF EXISTS DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.MY_SUPPLY_RISK_AGENT;
```

**What it does:** deletes your agent. `IF EXISTS` means it doesn't fail if the agent was already removed.
The main agent and all data are untouched.

**Next (optional):** [Lab 4 - Retrain the GNN](LAB4_optional_retrain_gnn.md). See where the risk scores come from.
