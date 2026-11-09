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

### Four ideas that make this trustworthy

**1. Cortex Analyst: you ask in English, it answers in SQL.**
Cortex Analyst turns a business question into SQL, runs it on your warehouse, and returns real rows. It doesn't
guess numbers: every figure in the answer comes from a query you can read in the trace.

**2. The semantic view: the dictionary the AI reads first.**
A raw SAP column called `LIFNR` means nothing to an LLM. The semantic view gives each table and column a business
name, a description and synonyms ("GNN-derived risk score", "vendor", "supplier"), so the AI writes SQL in
business terms. That's why the trace shows two versions of the SQL:
- **Input > SQL Query** uses the semantic view's *logical* names, for example `FROM __vw_supplier_risk`. Snowflake
  puts two underscores in front of logical table names so they can't clash with real ones.
- **Output > Final SQL** is the same query rewritten against the real tables. That's what actually ran.

**3. Verified queries: answers your data team has signed off.**
A verified query is a business question paired with SQL that a person has checked and approved, stored in the
semantic view. In Snowflake's words, Cortex Analyst "leverages relevant SQL queries from the repository when
answering similar questions". In the trace:
- **Verified Query Used = true**: the answer was built from approved SQL. Same question, same logic, every time.
- **Verified Query Used = false**: the LLM wrote the SQL itself, from the semantic view. It's usually right, but it's
  the version you should read before you trust it.

Your most important business questions ("top-risk suppliers", "single-source parts") are the ones to verify.
This semantic view has two.

**4. Cortex Search: finding the right paragraph, not just the right word.**
Contracts are text, so SQL can't read them. Cortex Search is Snowflake's managed search engine for text. Every
search combines three techniques:
- **vector search**, which finds passages with the same *meaning* (a search for "force majeure" can also match
  wording like "events beyond the parties' reasonable control");
- **keyword search**, which finds exact words, contract IDs and names;
- **semantic reranking**, which puts the most relevant passages first.

The agent then writes its answer **only from the passages it retrieved**, a pattern called *retrieval-augmented
generation* (RAG). The trace shows you exactly which passages those were.

*Sources: Snowflake documentation, "Cortex Analyst Verified Query Repository"
(docs.snowflake.com/en/user-guide/views-semantic/verified-query-repository) and "Cortex Search"
(docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-search/cortex-search-overview).*

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
   | **Semantic Context** | (Sometimes shown, on the first question of a thread) the agent loads the semantic view's descriptions |
   | **LLM Planning** | The agent reads your question and picks a tool |
   | **SQL Execution** | Cortex Analyst wrote SQL and ran it. **Click this for data questions** |
   | **Cortex Search** | The agent searched the contracts. **Click this for document questions** |
   | **LLM Response Generation** | The agent turns the rows or passages into the written answer |

3. Click **SQL Execution**. The right-hand panel shows:

   | Field | What to look for |
   | --- | --- |
   | **Analyst Tool Name for Semantic Model** | `supply_chain_risk_analyst`: proof the analyst tool was used |
   | **Semantic Model** | `DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.SUPPLY_CHAIN_RISK_SEMANTIC_VIEW` |
   | **Verified Query Used** | `true` = Cortex Analyst reused a **pre-approved** query. Blank or `false` = it wrote new SQL |
   | **Status** | `Success` |
   | **Input > SQL Query** | The SQL as written against the semantic view (short and readable) |
   | **Output > Final SQL** | The SQL that actually ran on Snowflake (expanded into real table and column names) |
   | **Output > SQL Results** | The rows the query returned: the raw facts behind the written answer |
   | **Query ID** | Copy it to find the same query in **Monitoring > Query History** |

   For a **Cortex Search** step, the right-hand panel instead shows **Input > Query** (the search text the agent
   chose), **Parameters** (`Limit` = how many passages, `Columns` = which fields come back) and **Output > Results**
   (the contract text it retrieved).

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
**In the trace:** an **SQL Execution** step with **Verified Query Used = false**: no approved query matched, so
the LLM wrote this SQL itself. Open **Input > SQL Query** and find the filter:

```sql
SELECT vendor_id, vendor_name, country_code, tier, risk_category, gnn_risk_score, ...
FROM __vw_supplier_risk
WHERE risk_category ILIKE 'CRITICAL'
ORDER BY gnn_risk_score DESC NULLS LAST
```

That `WHERE` line is the AI's interpretation of your words "CRITICAL risk". It's correct here, and you could check
it because the SQL is right in front of you.

### Q2. *Which Tier 1 suppliers have a GNN risk score above 0.6?*
**Why this question:** it matches one of the semantic view's **verified queries** word for word, so Cortex
Analyst can reuse pre-approved SQL instead of writing new SQL.
**Expected answer:** the **same 2 suppliers** as Q1.
**In the trace:** **Verified Query Used = true**, and the SQL Query is the approved one:
`... FROM __vw_supplier_risk WHERE tier = 1 AND gnn_risk_score > 0.6 ORDER BY gnn_risk_score DESC NULLS LAST`.
Put the Q1 and Q2 traces side by side: same suppliers, but Q2's logic was **signed off by a person in advance**.
**Takeaway:** verified queries are how a data team makes the answers to its most important questions
repeatable and trusted: when someone asks a matching question, Cortex Analyst starts from the approved SQL instead
of writing its own.

### Q3. *What force majeure terms are in our supplier contracts?*
**Why this question:** the answer lives in text, not in a column, so SQL can't answer it. Cortex Search finds
passages by **meaning**, not just keywords.
**Expected answer:** quotes from contract text, with contract IDs and titles. Contracts that mention force
majeure include **SC-2023-001** (Cobalt Supply Agreement), **SC-2023-008** (Graphite Products Supply) and
**SC-2023-012** (Emergency Supply and Remediation).
**In the trace:** **no SQL Execution step**. Instead there's a **Cortex Search** step. Click it:
- **Input > Query** reads *force majeure clause*. The agent turned your question into a short search phrase.
- **Parameters**: `Limit = 4` (the 4 best passages), `Columns = CONTRACT_ID, CONTRACT_TITLE`.
- **Output > Results** shows the contract text it found, starting with *SUPPLY AGREEMENT NO. SC-2023-001*
  (Freeport Cobalt and Congo Cobalt Mines).

Compare the Results with the written answer: every contract the agent mentions should appear in the Results. That's
RAG working as intended. The answer is grounded in your documents, not in the LLM's memory.

### Q4. *Which external suppliers have the strongest predicted hidden links to our suppliers, and what do our contracts with them say about force majeure?*
**Why this question:** it needs a number (the GNN's predicted links, from `VW_HIDDEN_DEPENDENCIES`) **and**
a document (the contract), joined by **supplier name**. This is the agent's real value: one question,
two kinds of data.
**Expected answer:**
- **Queensland Minerals** and **Jiangxi Graphite Ltd** at the top (predicted links to BYD Battery and SK On,
  probability about 0.62-0.70).
- Then contract details: Jiangxi Graphite's **SC-2023-008** mentions force majeure, and Queensland Minerals has
  a Lithium Supply Agreement (**SC-2023-002**).

**In the trace:** **both** tools, in order. First an **SQL Execution** step (the hidden links), then a
**Cortex Search** step (the contracts). That order is the agent's orchestration instructions at work.

### Q5. *Which materials have the highest GNN risk score?*
**Why this question:** it matches the semantic view's other verified query. It also shows that the agent covers
**parts** (from `VW_MATERIAL_RISK`), not just suppliers.
**Expected answer:** a ranked list led by materials such as *Battery Module 400V*, *High-Voltage Harness* and
*Silicon Anode Additive* (GNN risk score about 0.48).
**In the trace:** **Verified Query Used = true**, and the SQL Query reads
`SELECT ... FROM __vw_material_risk ORDER BY gnn_risk_score DESC NULLS LAST LIMIT 15`.

---

## Expected result
- 5 answers, with no errors and **Status = Success** on every SQL Execution and Cortex Search step.
- Q1, Q2, Q5: an **SQL Execution** step. Q1 shows **Verified Query Used = false**; Q2 and Q5 show **true**.
- Q3: a **Cortex Search** step, no SQL. Q4: **both**, SQL Execution first.
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
