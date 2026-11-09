# Lab 2 - Ask the agent, then check its work

> **Risk numbers live in tables. Obligations live in contracts. Your team usually needs both, and gets them from
> two different people a week apart.** Ask this agent *"which hidden supplier should worry us most, and what does
> our contract with them say about force majeure?"* and you get one answer in seconds.
>
> But a fast answer is only useful if you can **trust** it. So in this lab you won't just read answers. You'll
> open the agent's **traces** and see each step behind them: the plan it made, the tool it picked, and the
> **exact SQL it ran** against your SAP data. No black box: every number can be traced back to a query you can
> read, copy and re-run.

**Time:** 25 minutes. **Before you start:** `snowsight/08_readiness_check.sql` must say READY.

**What you'll learn**
- What a **Cortex Agent** is: an LLM that plans an answer and calls *tools* to get facts.
- The difference between its two tools: **Cortex Analyst** (questions over structured data, through a
  **semantic view**) and **Cortex Search** (questions over unstructured text).
- How to **audit** an AI answer: read the generated SQL in **Show Traces**, and tell whether it used
  pre-approved (verified) SQL.

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

## Step 1 - Open the agent
1. Make sure your user-menu role (bottom-left) is **ACCOUNTADMIN**.
2. In the left navigation, hover over **AI** and click **Agent Studio**.
3. Stay on the **Agents** tab. You should see one row: **GNN_SUPPLY_RISK_AGENT**, last updated by
   `DEMO_19865_ROLE`, with **ADDED TO COWORK = No**.
4. Click **GNN_SUPPLY_RISK_AGENT**. The agent page opens on the **Overview** tab (usage charts, no chat box).
5. **Click the Preview tab** (the last tab in the row *Overview | Configuration | Access | Evaluations |
   Observability | Preview*). **This is where you ask your questions:** type in the box
   *"Enter a message to test your agent"* at the bottom and press Enter.

   > **Don't click Publish or Add to Snowflake CoWork.** Preview lets you chat with the agent without changing it.
   > The *Snowflake CoWork* app only lists agents that have been added to it, and this one hasn't (the column
   > says *No*), so use Agent Studio for these labs.

## Step 2 - Open the traces (this is where you see the SQL)
The answer in the chat shows *what* the agent concluded. The traces show *how* it got there. Above the
conversation, on the right, is a toolbar: **New thread | Show Traces | Show inspector | Preview in Snowflake CoWork**.

1. After the agent answers, click **Show Traces**. A **Traces** screen opens with three panels:
   your conversation on the left, **Thread details** in the middle, and step details on the right.
2. In **Thread details**, each question you asked is one **Agent (n)** row, with the time it took. Click the
   arrow **>** on the newest row (the bottom one) to expand it. You'll see the agent's steps, for example:

   | Step | What it means |
   | --- | --- |
   | **LLM Planning** | The agent reads your question and picks a tool |
   | **SQL Execution** | Cortex Analyst wrote SQL and ran it. **This is the one you want** |
   | **LLM Response Generation** | The agent turns the rows into the written answer |

3. Click **SQL Execution**. The right-hand panel shows:

   | Field | What to look for |
   | --- | --- |
   | **Analyst Tool Name for Semantic Model** | `supply_chain_risk_analyst`: proof the analyst tool was used |
   | **Semantic Model** | `DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.SUPPLY_CHAIN_RISK_SEMANTIC_VIEW` |
   | **Verified Query Used** | `true` = Cortex Analyst reused a **pre-approved** query. Blank or `false` = it wrote new SQL |
   | **Status** | `Success` |
   | **Input > SQL Query** | The SQL as written against the semantic view (short and readable) |
   | **Output > Final SQL** | The SQL that actually ran on Snowflake (expanded into real table and column names) |
   | **Query ID** | Copy it to find the same query in **Monitoring > Query History** |

4. Click **Hide traces** (top-right) to return to the chat. Ask the next question, then open the traces again.

> **Try it yourself:** copy the **Final SQL**, paste it into a SQL worksheet and run it. You'll get the same rows
> the agent used. That's what "auditable AI" means: the answer is backed by a query anyone can re-run.

> **Tip:** click **New thread** before each question. Then the agent answers it fresh, without using earlier
> questions as context, and each question gets its own short trace.

---

## Step 3 - The questions
Ask each question **exactly as written**, then open **Show Traces** and check the clues below.

### Q1. *Which suppliers are CRITICAL risk?*
**Why this question:** it's a pure structured-data question. The agent should turn "CRITICAL risk" into a
filter on `RISK_CATEGORY` in `VW_SUPPLIER_RISK`.
**Expected answer:** **Albemarle Corp** and **Epsilon Tech** (both AUS, Tier 1, GNN risk score about 0.61).
**In the trace:** an **SQL Execution** step. Open **Input > SQL Query** and find the `WHERE` clause, something
like `risk_category = 'CRITICAL'`. That one line is the agent's interpretation of your words.

### Q2. *Which Tier 1 suppliers have a GNN risk score above 0.6?*
**Why this question:** it matches one of the semantic view's **verified queries** word for word, so Cortex
Analyst can reuse pre-approved SQL instead of writing new SQL.
**Expected answer:** the **same 2 suppliers** as Q1.
**In the trace:** **Verified Query Used = true**. Compare it with Q1, which the LLM wrote from scratch.
**Takeaway:** verified queries are how a data team makes the answers to its most important questions
repeatable and trusted.

### Q3. *What force majeure terms are in our supplier contracts?*
**Why this question:** the answer lives in text, not in a column, so SQL can't answer it. Cortex Search finds
passages by **meaning**, not just keywords.
**Expected answer:** quotes from contract text, with contract IDs and titles. Contracts that mention force
majeure include **SC-2023-001** (Cobalt Supply Agreement), **SC-2023-008** (Graphite Products Supply) and
**SC-2023-012** (Emergency Supply and Remediation).
**In the trace:** **no SQL Execution step**. You'll see a search step for `contract_search` instead. Click it
to see the passages it retrieved: the agent's answer should only quote what's there.

### Q4. *Which external suppliers have the strongest predicted hidden links to our suppliers, and what do our contracts with them say about force majeure?*
**Why this question:** it needs a number (the GNN's predicted links, from `VW_HIDDEN_DEPENDENCIES`) **and**
a document (the contract), joined by **supplier name**. This is the agent's real value: one question,
two kinds of data.
**Expected answer:**
- **Queensland Minerals** and **Jiangxi Graphite Ltd** at the top (predicted links to BYD Battery and SK On,
  probability about 0.62-0.70).
- Then contract details: Jiangxi Graphite's **SC-2023-008** mentions force majeure, and Queensland Minerals has
  a Lithium Supply Agreement (**SC-2023-002**).

**In the trace:** **both** tools, in order. First an **SQL Execution** step (the hidden links), then a search step
(the contracts). That order is the agent's orchestration instructions at work.

### Q5. *Which materials have the highest GNN risk score?*
**Why this question:** it matches the semantic view's other verified query. It also shows that the agent covers
**parts** (from `VW_MATERIAL_RISK`), not just suppliers.
**Expected answer:** a ranked list led by materials such as *Battery Module 400V*, *High-Voltage Harness* and
*Silicon Anode Additive* (GNN risk score about 0.48).
**In the trace:** **Verified Query Used = true**, and the SQL Query reads
`SELECT ... FROM __vw_material_risk ORDER BY gnn_risk_score DESC NULLS LAST LIMIT 15`.

---

## Expected result
- 5 answers, with no errors and **Status = Success** on every SQL Execution step.
- Q1, Q2, Q5: an **SQL Execution** step. Q2 and Q5 show **Verified Query Used = true**.
- Q3: a search step, no SQL. Q4: **both**, SQL first.
- The answers are written by an LLM, so the **wording and layout vary** from run to run and between trainees.
  The **facts** (names, scores, contract IDs) should match the expected values above. The SQL is where you check
  them.

## Discuss
1. Compare the traces for Q1 and Q2. Why is an answer with **Verified Query Used = true** more trustworthy than
   one the LLM writes from scratch? Which questions in *your* business deserve a verified query?
2. Look at **Input > SQL Query** and **Output > Final SQL** for the same question. Why does the semantic view
   let the LLM write the short version, and who benefits from that?
3. In Q4, the agent links risk data to contracts by supplier **name**. What could go wrong with name matching in
   real data, and how would you make it more robust?
4. Q4 follows the agent's instructions (analyst first, then search). Open the **Configuration** tab: where would
   you change that behaviour?

**Next:** [Lab 3 - Build your own agent](LAB3_build_your_own_agent.md). You'll build one like this yourself, and
use the same traces to see how its behaviour changes.
