# Lab 2 - Ask the agent, then check its work

> **Disclaimer:** all data in this lab is **synthetic and for demonstration only**. Company names (for example
> Albemarle Corp, BYD Battery or Queensland Minerals) are used for illustration. The vendors, purchase orders,
> trade records, contracts, risk scores and predicted links are invented and **don't describe any real
> company, relationship or risk**. Don't use them for business decisions.

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

#### Look behind Q3: where do the contracts live, and how does Snowflake read them?

**The documents.** The 12 supplier contracts are full legal text: parties, recitals, numbered clauses, about
2,500 to 4,200 characters each. They're stored in an ordinary Snowflake table, one contract per row:

| What | Where |
| --- | --- |
| Table | `DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.CUSTOMER_CONTRACTS` |
| The document text | Column **`CONTRACT_TEXT`** |
| Labels next to it | `CONTRACT_ID`, `CONTRACT_TITLE`, `SUPPLIER_NAME`, `BUYER_NAME`, `MATERIAL_TYPE`, `ANNUAL_VALUE_USD`, ... |
| Search index over the text | `CONTRACT_SEARCH_SERVICE` (Cortex Search), refreshed every hour |
| Where it was loaded from | `data/demo/customer_contracts.csv` in this kit's GitHub repo (stage 4) |

Nothing in that text is a field. There is no "force majeure" column, and no SQL `WHERE` clause that can find
"the clause about what happens if a mine floods". That's what *unstructured* means, and it's the problem Cortex Search
solves.

**Try 1: read a contract yourself.** Go to **Catalog > Database Explorer > DEMO_19865_DB > GNN_SUPPLY_CHAIN_RISK >
Tables > CUSTOMER_CONTRACTS**, open **Data Preview**, and click a `CONTRACT_TEXT` cell. Or run this in a SQL file:

```sql
SELECT CONTRACT_ID, CONTRACT_TITLE, SUPPLIER_NAME, CONTRACT_TEXT
FROM DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.CUSTOMER_CONTRACTS
WHERE CONTRACT_ID = 'SC-2023-001';
```

**What it does:** shows the first contract the agent retrieved in Q3, in full.
**Why:** it's the same document the agent quoted, so you can check the agent's summary against the original.

**Try 2: run the agent's search yourself.** This sends the same search as the Q3 trace (*force majeure clause*,
4 results):

```sql
SELECT r.value:CONTRACT_ID::STRING    AS contract_id,
       r.value:CONTRACT_TITLE::STRING AS contract_title
FROM TABLE(FLATTEN(PARSE_JSON(SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
       'DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.CONTRACT_SEARCH_SERVICE',
       '{"query": "force majeure clause", "columns": ["CONTRACT_ID", "CONTRACT_TITLE"], "limit": 4}'
     )):results)) r;
```

**What it does:** `SEARCH_PREVIEW` queries the search service from SQL. It returns JSON, and `FLATTEN` turns the
results into one row each.
**Expected:** 4 rows: **SC-2023-001** Cobalt Supply Agreement, **SC-2023-012** Emergency Supply and Remediation,
**SC-2023-008** Graphite Products Supply, **SC-2023-002** Lithium Supply Agreement. These are the same passages the
agent read before writing its answer.

**Try 3: keywords vs meaning.** Ask a question the way a person would, using words the contracts never use:

```sql
-- Keyword search: does any contract contain the words "walk away"?
SELECT COUNT(*) AS keyword_matches
FROM DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.CUSTOMER_CONTRACTS
WHERE CONTRACT_TEXT ILIKE '%walk away%';

-- Cortex Search: same question, by meaning
SELECT r.value:CONTRACT_ID::STRING    AS contract_id,
       r.value:CONTRACT_TITLE::STRING AS contract_title
FROM TABLE(FLATTEN(PARSE_JSON(SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
       'DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.CONTRACT_SEARCH_SERVICE',
       '{"query": "can we walk away from the agreement early", "columns": ["CONTRACT_ID", "CONTRACT_TITLE"], "limit": 3}'
     )):results)) r;
```

**Expected:** the keyword query finds **0** contracts. Cortex Search still returns results, and in our test the top
one was **SC-2023-001**, whose section *8. TERM AND TERMINATION* is exactly what the question is about. It
understood that "walk away early" means *termination*, a word you never typed. (The ranking can vary slightly between
accounts, but the keyword count is always 0.)

**What Snowflake did for you.** One `CREATE CORTEX SEARCH SERVICE ... ON CONTRACT_TEXT` statement
(`sql/stage5_ai_services/50_search_service.sql`) was enough to:
- turn every contract into a searchable index of meaning (vector embeddings) as well as words, with no embedding
  model, vector database or search cluster to run yourself;
- keep it fresh: new or changed contracts are re-indexed automatically (`TARGET_LAG = '1 hour'`);
- keep it governed: the documents never leave Snowflake, and only roles granted access to the service can search it;
- return each passage with its `CONTRACT_ID` and `CONTRACT_TITLE`, so the agent can **cite its sources**.

> **In a real SAP BDC project,** contracts usually arrive as **PDF or scanned files**, not text. You'd upload them to
> a Snowflake stage, extract the text with **`AI_PARSE_DOCUMENT`** (which also reads scanned pages and tables) into a
> table like `CUSTOMER_CONTRACTS`, then create the same search service on top. This kit skips the PDF step and ships
> the extracted text, so setup takes minutes, but everything from the table onwards works exactly as it would in
> production.

### Q4. *Which external suppliers have the strongest predicted hidden links to our suppliers, and what do our contracts with them say about force majeure?*
**Why this question:** it needs a number (the GNN's predicted links, from `VW_HIDDEN_DEPENDENCIES`) **and**
a document (the contract), joined by **supplier name**. This is the agent's real value: one question,
two kinds of data.
**Expected answer:**
- The top predicted links (from the trace's SQL Results): **Queensland Minerals → BYD Battery (0.69)**,
  Queensland Minerals → SK On (0.63), **Jiangxi Graphite Ltd** → BYD Battery (0.62), Shanghai Battery Materials
  → BYD Battery (0.61) and Jiangxi Graphite Ltd → SK On (0.61).
- Then contract details: Jiangxi Graphite's **SC-2023-008** mentions force majeure, and Queensland Minerals has
  a Lithium Supply Agreement (**SC-2023-002**).
- Often a **bar chart** of the links as well. You didn't ask for one: the agent decided a chart would help.

**In the trace: watch the agent think in a loop.** This is the longest trace of the lab (about 45 seconds,
eight steps):

| # | Step | What the agent is doing |
| --- | --- | --- |
| 1 | LLM Planning | "I need numbers first": picks the analyst tool |
| 2 | SQL Execution | Gets the hidden links (under a second) |
| 3 | LLM Planning | Reads the rows, sees the supplier names, decides to look up *their* contracts |
| 4 | Cortex Search | Searches the contracts for those suppliers |
| 5 | Skill: chart_instructions | Loads its instructions for drawing charts |
| 6 | LLM Planning | Decides the result is easier to read as a chart |
| 7 | Chart Generation | Builds the chart |
| 8 | LLM Response Generation | Writes the final answer from everything above |

This is what makes it an **agent** and not a chatbot: it **plans, acts, looks at the result, and plans again**.
Step 4 couldn't have been written in advance, because the agent only knew which suppliers to search for after
step 2 returned them.

**Three things to click in this trace:**

1. **Chart Generation.** **Input > Input Chart Spec** is a small JSON recipe (`"mark": "bar"`, `SOURCE_NAME` on
   the y-axis), the *Vega-Lite* format that many charting tools use. Under it, **SQL Results** shows the exact rows
   the chart was drawn from. Even the picture is traceable to a query.
2. **Any LLM Planning step > Available Tools.** This is the agent's "menu": each tool with its parameters and a
   description (for `contract_search`: `columns`, `filter`, `limit`...). The LLM chooses tools **by reading those
   descriptions**, so a vague tool description gives you a confused agent. You'll write your own in Lab 3.
3. **LLM Response Generation > Response Instruction.** It starts *"Be direct and analytical. Lead with the key
   finding or metric..."*. That's not the AI's personality. It's the `response` instruction written in this
   agent's definition, which you can see in the **Configuration** tab. Tone, tables, bullet points and "flag
   critical risks prominently" are all settings you control.

### Q5. *Which materials have the highest GNN risk score?*
**Why this question:** it matches the semantic view's other verified query. It also shows that the agent covers
**parts** (from `VW_MATERIAL_RISK`), not just suppliers.
**Expected answer:** a ranked list led by materials such as *Battery Module 400V*, *High-Voltage Harness* and
*Silicon Anode Additive* (GNN risk score about 0.48).
**In the trace:** **Verified Query Used = true** (`... FROM __vw_material_risk ORDER BY gnn_risk_score DESC NULLS
LAST LIMIT 15`), as in Q2. Now look somewhere new: **where the time and the cost go.**

1. Compare the bars in the middle panel. **SQL Execution** takes under a second (about 0.8 s). The two **LLM**
   steps take about 15 seconds together. On data this size, the database is the fast part; most of the wait is
   the model reading and writing.
2. Click **LLM Response Generation**. The top of the panel shows the **Model Name** and the **token counts**. In our
   run: about **74,000 input tokens** and fewer than **900 output tokens**.

   A *token* is a chunk of text of about 4 characters, and it's how LLM usage is measured and billed. Why does a
   one-line question need 74,000 input tokens? Because each step sends the model **everything it needs**: the
   agent's instructions, the descriptions of every tool, the semantic view context, the SQL results and the
   conversation so far. The answer itself is small.

**Takeaway:** the model reads far more than it writes. Short, sharp instructions and tool descriptions, starting a
**New thread** for unrelated questions, and returning only the rows you need (note the `LIMIT 15`) all keep agents
fast and cheap. Your numbers will differ from ours, but the input-heavy pattern holds.

---

## Expected result
- 5 answers, with no errors and **Status = Success** on every SQL Execution and Cortex Search step.
- Q1, Q2, Q5: an **SQL Execution** step. Q1 shows **Verified Query Used = false**; Q2 and Q5 show **true**.
- Q3: a **Cortex Search** step, no SQL. Q4: **SQL Execution, then Cortex Search**, with LLM Planning between
  them, and usually a **Chart Generation** step.
- Q5: SQL Execution under a second; most of the time is in the LLM steps; input tokens far exceed output tokens.
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
4. In Q4, the agent drew a chart nobody asked for. Is that helpful or risky in a business report? Which line in
   the **Response Instruction** would you add or change to control it?
5. Q5 used about 74,000 input tokens to write fewer than 900. Name two changes to the agent that would cut that
   number without hurting answer quality.

**Next:** [Lab 3 - Build your own agent](LAB3_build_your_own_agent.md). You'll build one like this yourself, and
use the same traces to see how its behaviour changes.
