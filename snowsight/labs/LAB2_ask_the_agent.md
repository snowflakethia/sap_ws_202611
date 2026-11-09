# Lab 2 - Ask the agent: one question, two kinds of data

> **Risk numbers live in tables. Obligations live in contracts. Your team usually needs both, and gets them from
> two different people a week apart.** Ask this agent *"which hidden supplier should worry us most, and what does
> our contract with them say about force majeure?"*. It writes SQL against the SAP-shaped data, searches the
> contract documents, and gives you one answer in seconds. In this lab you'll watch it decide *how* to answer.

**Time:** 20 minutes. **Before you start:** `snowsight/08_readiness_check.sql` must say READY.

**What you'll learn**
- What a **Cortex Agent** is: an LLM that plans an answer and calls *tools* to get facts.
- The difference between its two tools: **Cortex Analyst** (questions over structured data, through a
  **semantic view**) and **Cortex Search** (questions over unstructured text).
- How to check an AI answer: inspect the generated SQL and the retrieved documents.

---

## How this agent is built (2-minute read)

| Part | Object | What it does |
| --- | --- | --- |
| Agent | `GNN_SUPPLY_RISK_AGENT` | Reads your question, decides which tool(s) to call, and writes the final answer. Its *orchestration instructions* say: use the analyst tool for risk data, the search tool for contract terms, and for questions that need both, the analyst first |
| Tool 1 | `supply_chain_risk_analyst` (Cortex Analyst) | Turns your question into **SQL** over the semantic view `SUPPLY_CHAIN_RISK_SEMANTIC_VIEW`, runs it on `DEMO_19865_WH`, and returns the rows |
| Tool 2 | `contract_search` (Cortex Search) | Finds the **most relevant passages** in the 12 supplier contracts (`CONTRACT_SEARCH_SERVICE`, up to 4 results per search) |
| Semantic view | `SUPPLY_CHAIN_RISK_SEMANTIC_VIEW` | A business layer over the 4 risk views. It gives every column a description (for example, "GNN-derived risk score"), so the LLM writes correct SQL. It also holds 2 **verified queries**: questions with approved SQL answers |

> **Good to know:** the 12 contracts are with the **external, Tier 2 suppliers** you met in Lab 1 (for example
> Tokyo Chemical Works and Jiangxi Graphite Ltd), not with the 50 SAP vendors. Keep that in mind for question 4.

---

## Open the agent
1. Make sure your user-menu role (bottom-left) is **ACCOUNTADMIN**.
2. In the left navigation, open **AI & ML > Agents** (in some accounts: **AI > Agents**), then click
   **GNN_SUPPLY_RISK_AGENT**.
3. Ask each question below **exactly as written**. After each answer, expand the response details (the steps
   shown above or under the answer). Look for the **tool name**, plus the **SQL** (analyst) or the
   **contract passages** (search).

---

## The questions

### Q1. *Which suppliers are CRITICAL risk?*
**Tool you should see:** `supply_chain_risk_analyst`
**Why this question:** it's a pure structured-data question. The agent should turn "CRITICAL risk" into a
filter on `RISK_CATEGORY` in `VW_SUPPLIER_RISK`.
**Expected:** a table with **Albemarle Corp** and **Epsilon Tech** (both AUS, Tier 1, GNN risk score about 0.61).
**Look at the SQL:** find the `WHERE` clause. That's the agent's interpretation of your words.

### Q2. *Which Tier 1 suppliers have a GNN risk score above 0.6?*
**Tool you should see:** `supply_chain_risk_analyst`
**Why this question:** it matches one of the semantic view's **verified queries** word for word, so Cortex
Analyst can reuse pre-approved SQL instead of writing new SQL.
**Expected:** the **same 2 suppliers** as Q1.
**Takeaway:** verified queries are how a data team makes the answers to its most important questions
repeatable and trusted.

### Q3. *What force majeure terms are in our supplier contracts?*
**Tool you should see:** `contract_search`
**Why this question:** the answer lives in text, not in a column, so SQL can't answer it. Cortex Search finds
passages by **meaning**, not just keywords.
**Expected:** quotes from contract text, with contract IDs and titles. Contracts that mention force majeure
include **SC-2023-001** (Cobalt Supply Agreement), **SC-2023-008** (Graphite Products Supply) and
**SC-2023-012** (Emergency Supply and Remediation).

### Q4. *Which external suppliers have the strongest predicted hidden links to our suppliers, and what do our contracts with them say about force majeure?*
**Tools you should see:** **both**, analyst first, then search.
**Why this question:** it needs a number (the GNN's predicted links, from `VW_HIDDEN_DEPENDENCIES`) **and**
a document (the contract), joined by **supplier name**. This is the agent's real value: one question,
two kinds of data.
**Expected:**
- **Queensland Minerals** and **Jiangxi Graphite Ltd** at the top (predicted links to BYD Battery and SK On,
  probability about 0.62-0.70).
- Then contract details: Jiangxi Graphite's **SC-2023-008** mentions force majeure, and Queensland Minerals has
  a Lithium Supply Agreement (**SC-2023-002**).

### Q5. *Which materials have the highest GNN risk score?*
**Tool you should see:** `supply_chain_risk_analyst`
**Why this question:** it matches the semantic view's other verified query. It also shows that the agent covers
**parts** (from `VW_MATERIAL_RISK`), not just suppliers.
**Expected:** a ranked list led by materials such as *Battery Module 400V*, *High-Voltage Harness* and *Silicon
Anode Additive* (GNN risk score about 0.48).

---

## Expected result
- 5 answers, with no errors.
- Q1, Q2 and Q5 show **generated SQL**. Q3 shows **contract passages**. Q4 shows **both**, analyst first.
- The answers are written by an LLM, so the **wording and layout vary** from run to run and between trainees.
  The **facts** (names, scores, contract IDs) should match the expected values above.

## Discuss
1. In Q2, why does a *verified* query make the answer more trustworthy than one the LLM writes from scratch?
2. In Q4, the agent links risk data to contracts by supplier **name**. What could go wrong with name matching in
   real data, and how would you make it more robust?
3. Q4 follows the agent's instructions (analyst first, then search). Open the agent's settings: where would you
   change that behaviour?

**Next:** [Lab 3 - Build your own agent](LAB3_build_your_own_agent.md). You'll build one like this yourself.
