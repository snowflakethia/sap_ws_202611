# Lab 5 (optional) - Build a supply chain risk dashboard with one prompt

> [!CAUTION]
> **Disclaimer:** all data in this lab is **synthetic and for demonstration only**. Company names (for example
> Albemarle Corp, BYD Battery or Queensland Minerals) are used for illustration. The vendors, purchase orders,
> trade records, contracts, risk scores and predicted links are invented and **don't describe any real
> company, relationship or risk**. Don't use them for business decisions.

> **In Labs 1 to 4 you asked questions. In Lab 5 you hand the business a working app.** One prompt to Cortex Code
> (CoCo) in Snowsight turns 4 SAP data products, external signals, GNN predictions and supplier contracts into a
> 2-page dashboard: a supply chain risk story with spend at risk, hidden Tier 2 bottlenecks, exposed products, contract coverage, and two pages
> a technical architecture page. Then you grow it, one prompt at a time.

> [!TIP]
> **Key takeaway: one prompt turns SAP data products into a governed, production-shaped app, fast enough to build live in a design-thinking session.**
> - **SAP stays the system of record; Snowflake adds the context.** The app joins 5 databases without copying SAP data.
> - **The semantic view and Cortex Search are reused.** The dashboard, the agent and analysts share one definition of risk.
> - **A prototype isn't throwaway.** It already runs on the production object names, roles and platform. Going live
>   means pointing it at live SAP BDC data products.

**Time:** 45-60 minutes (5-10 of them are CoCo building the app). **Before you start:**
`snowsight/08_readiness_check.sql` must say READY, including the row **Cortex cross-region inference = ANY_REGION**
(set in Stage 1, so CoCo can use a region where its models are available).
Labs 1 to 3 help you read the dashboard, but they aren't required: Lab 5 only needs the setup.

---

## What you'll build

**Page 1: Supply Chain Risk Dashboard**, one story you read from top to bottom:

| Section | What the reader learns | Data it combines |
| --- | --- | --- |
| 1. The business and the challenge | Who we are, what SAP can and can't see, and the 4 questions we need answered | Context |
| 2. The headline | How much of our spend is exposed (each KPI explained) | SAP purchase orders x GNN risk, bottlenecks, materials |
| 3. Where the risk sits | Which suppliers, which regions | **Semantic view** + SAP vendors + GNN risk |
| 4. Why: the hidden Tier 2 suppliers | Who we are *really* depending on | GNN predicted links + bottlenecks |
| 5. What it hits | Which parts and products would stop | SAP materials + SAP BOM + material risk |
| 6. Are we covered | Which contracts exist | Supplier contracts |
| 7. What to do next | 3 actions | All of the above |
| 8. How SAP and Snowflake made this possible | System of record + SAP BDC Connect + system of context | Business architecture |

**Page 2: Technical Architecture**: how the app was built, the data flow, every Snowflake component it depends on,
and the SQL behind each section.

The prompt gives CoCo the exact, tested SQL for every section and uses only built-in Streamlit elements. That makes the first run very likely to work. You add the richer features (map, network
diagram, contract search) in Step 5.

**Expected numbers** (use them to check the app CoCo builds):

| KPI | Value |
| --- | --- |
| Total PO spend (SAP) | **$143.3M** |
| Spend at risk (HIGH + CRITICAL suppliers) | **$18.6M** (13%) |
| Suppliers by risk category | **CRITICAL 2, HIGH 4, MEDIUM 44** |
| Unmitigated Tier 2 bottlenecks (10+ dependents) | **9** (top: Tokyo Chemical Works and Bavaria Specialty Metals, 48 each) |
| Critical materials with 0 or 1 supplier | **3** (EV Battery Pack 85kWh, High-Voltage Harness, Nickel Sulfate Battery Grade) |
| Supplier contracts / annual value | **12 / $187.6M** |

---

## Step 1 - Open CoCo in Snowsight
1. Make sure your user-menu role (bottom-left) is **ACCOUNTADMIN**.
2. Open **Cortex Code (CoCo)**: click **CoCo** at the top of the left navigation (next to **Home**), or the blue
   sparkle button at the bottom-right of the screen.
3. Start a **new conversation**, so earlier chats don't influence the result.

## Step 2 - Paste the prompt
Copy the whole block below (hover over it and click the **copy** button at its top-right), paste it into CoCo and
press Enter. **Don't edit it the first time.** It's written so CoCo can build the app without asking you anything.

```text
Build and deploy a polished, story-driven Streamlit in Snowflake app for business leaders. Use only built-in
Streamlit features (no extra packages, no custom HTML or CSS). Correctness first, then look and feel.

APP SETUP
- Name: DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.SUPPLY_RISK_DASHBOARD, title "Supply Chain Risk Dashboard".
- Owner role DEMO_19865_ROLE, query warehouse DEMO_19865_WH.
- Runtime: container runtime (RUNTIME_NAME = 'SYSTEM$ST_CONTAINER_RUNTIME_PY3_11'). This account has no internet
  access, so packages must come from Snowflake's built-in PyPI mirror: create the app with
  ARTIFACT_REPOSITORIES = (snowflake.snowpark.pypi_shared_repository). Role DEMO_19865_ROLE already has access.
- Create exactly 3 files:
  1) streamlit_app.py
  2) pyproject.toml, exactly:
     [project]
     name = "supply-risk-dashboard"
     version = "0.1.0"
     requires-python = ">=3.11"
     dependencies = ["streamlit[snowflake]>=1.50", "pandas"]
  3) environment.yml (only used if the app runs on the warehouse runtime), exactly:
     name: app_environment
     channels:
       - snowflake
     dependencies:
       - streamlit
       - pandas
       - snowflake-snowpark-python
  Do not create requirements.txt. Do not add any other package or an external access integration.
- Start streamlit_app.py with:
     import streamlit as st
     import pandas as pd
     try:
         session = st.connection("snowflake").session()
     except Exception:
         from snowflake.snowpark.context import get_active_session
         session = get_active_session()
     @st.cache_data(ttl=600)
     def q(sql):
         return session.sql(sql).to_pandas()
- Layout: st.set_page_config(page_title="Supply Chain Risk", layout="wide"). Exactly 2 pages, as
  st.tabs(["Supply Chain Risk Dashboard", "Technical Architecture"]). No sidebar.
- Use only: st.title, st.subheader, st.markdown (with :red[...] / :orange[...] / :green[...] colour), st.caption,
  st.metric (with help=), st.columns, st.container(border=True), st.divider, st.info, st.success, st.warning,
  st.bar_chart, st.dataframe (hide_index=True), st.table and st.expander.
- At the top of both pages: st.warning("Synthetic data, for demonstration only. No real company, relationship
  or risk is described.").
- Use the SQL below exactly as written (it is tested). Don't write other queries.

SQL (SAP data product names are lowercase and double-quoted; keep them exactly)
SPEND = SELECT SUM(p.QUANTITY * p.UNIT_PRICE) AS TOTAL_SPEND,
  SUM(IFF(s.RISK_CATEGORY IN ('HIGH','CRITICAL'), p.QUANTITY * p.UNIT_PRICE, 0)) AS SPEND_AT_RISK
  FROM S4_ZPURCHASEORDERS_DP_DELTA_SHARING_V1."s4_zpurchaseorders_dp_srv:v1"."s4custom_purchase_orders" p
  JOIN DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.VW_SUPPLIER_RISK s ON s.VENDOR_ID = p.VENDOR_ID
RISK_MIX = SELECT RISK_CATEGORY, COUNT(*) AS SUPPLIERS FROM SEMANTIC_VIEW(
  DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.SUPPLY_CHAIN_RISK_SEMANTIC_VIEW
  DIMENSIONS VW_SUPPLIER_RISK.VENDOR_ID, VW_SUPPLIER_RISK.RISK_CATEGORY) GROUP BY 1 ORDER BY 1
SUPPLIERS = SELECT s.VENDOR_NAME, s.COUNTRY_CODE, s.TIER, s.RISK_CATEGORY, s.GNN_RISK_SCORE,
  v.FINANCIAL_HEALTH_SCORE, SUM(p.QUANTITY * p.UNIT_PRICE) AS SPEND
  FROM DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.VW_SUPPLIER_RISK s
  JOIN S4_ZVENDORINFO_DP_DELTA_SHARING_V1."s4_zvendorinfo_dp_srv:v1"."s4custom_vendors" v ON v.VENDOR_ID = s.VENDOR_ID
  LEFT JOIN S4_ZPURCHASEORDERS_DP_DELTA_SHARING_V1."s4_zpurchaseorders_dp_srv:v1"."s4custom_purchase_orders" p
    ON p.VENDOR_ID = s.VENDOR_ID
  GROUP BY ALL ORDER BY s.GNN_RISK_SCORE DESC NULLS LAST
BOTTLENECKS = SELECT NODE_ID AS EXTERNAL_SUPPLIER, DEPENDENT_COUNT, MITIGATION_STATUS
  FROM DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.BOTTLENECKS_PREDICTIONS ORDER BY DEPENDENT_COUNT DESC
LINKS = SELECT SOURCE_NAME AS EXTERNAL_SUPPLIER, TARGET_NAME AS SAP_SUPPLIER, PROBABILITY
  FROM DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.VW_HIDDEN_DEPENDENCIES ORDER BY PROBABILITY DESC
MATERIALS = SELECT r.MATERIAL_ID, r.DESCRIPTION, r.CRITICALITY_SCORE, r.NUM_SUPPLIERS, m.INVENTORY_DAYS
  FROM DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.VW_MATERIAL_RISK r
  JOIN S4_ZMATERIALS_DP_DELTA_SHARING_V1."s4_zmaterials_dp_srv:v1"."s4custom_materials" m ON m.MATERIAL_ID = r.MATERIAL_ID
  ORDER BY r.CRITICALITY_SCORE DESC, r.NUM_SUPPLIERS
BOM = SELECT p.DESCRIPTION AS FINISHED_PRODUCT, COUNT(*) AS COMPONENTS,
  COUNT_IF(COALESCE(r.NUM_SUPPLIERS, 0) <= 1) AS SINGLE_SOURCE_COMPONENTS
  FROM S4_ZBILLOFMATERIALS_DP_DELTA_SHARING_V1."s4_zbillofmaterials_dp_srv:v1"."s4custom_billofmaterials" b
  JOIN S4_ZMATERIALS_DP_DELTA_SHARING_V1."s4_zmaterials_dp_srv:v1"."s4custom_materials" p ON p.MATERIAL_ID = b.PARENT_MATERIAL_ID
  LEFT JOIN DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.VW_MATERIAL_RISK r ON r.MATERIAL_ID = b.CHILD_MATERIAL_ID
  GROUP BY 1 ORDER BY 3 DESC
CONTRACTS = SELECT CONTRACT_ID, CONTRACT_TITLE, SUPPLIER_NAME, MATERIAL_TYPE, ANNUAL_VALUE_USD
  FROM DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.CUSTOMER_CONTRACTS ORDER BY CONTRACT_ID

PAGE 1 - "Supply Chain Risk Dashboard": one scrolling story, top to bottom. Number each section heading.
Start every section with one plain-English sentence saying what the reader learns, and end it with a one-line
"So what" in st.info. Put the numbers inside st.container(border=True) cards.

0. Title "Supply Chain Risk Dashboard" and a caption "SAP data products on Snowflake, enriched with trade data,
   regional risk, contracts and a graph neural network (GNN)".
1. "The business and the challenge" (st.markdown, 3 short paragraphs):
   - Who we are: a manufacturer of 85 kWh EV battery packs. SAP S/4HANA is our system of record: 50 direct (Tier 1)
     suppliers in 9 countries, 26 materials (20 raw materials, 5 sub-assemblies, 1 finished battery pack) and
     120 purchase orders in 2023. SAP Business Data Cloud (BDC) shares these as data products with Snowflake, zero-copy.
   - The challenge: SAP only sees who WE buy from. It can't see who our suppliers buy from. Lithium, cobalt and
     graphite come from a few regions, and one hidden Tier 2 plant can quietly feed most of our supply base.
     A disruption there stops battery production, and we would only find out when a delivery fails.
   - Why this dashboard: to answer 4 questions before the next disruption: How much of our spend is exposed?
     Where does the risk sit? Who are we really depending on? Which products would stop?
2. "The headline" - 4 st.metric cards in st.columns(4), each with a help= definition:
   - "Total PO spend (2023)" = SPEND.TOTAL_SPEND in $M. help: "Value of all 2023 purchase orders in SAP
     (quantity x unit price) with our 50 Tier 1 suppliers."
   - "Spend at risk" = SPEND.SPEND_AT_RISK in $M, delta = its % of total, delta_color="inverse". help: "Part of that
     spend placed with suppliers the GNN rates HIGH or CRITICAL risk."
   - "Hidden Tier 2 bottlenecks" = rows of BOTTLENECKS with DEPENDENT_COUNT >= 10. help: "External suppliers, not in
     SAP, that 10 or more of our suppliers depend on."
   - "Single-source critical parts" = rows of MATERIALS with NUM_SUPPLIERS <= 1 and CRITICALITY_SCORE >= 0.8.
     help: "Critical materials with no or only one supplier."
   Then one st.markdown sentence that reads the numbers back, e.g. ":red[$18.6M (13%)] of our spend sits with
   high-risk suppliers, and 9 hidden suppliers each sit behind 10 or more of our suppliers."
3. "Where the risk sits": left column st.bar_chart of RISK_MIX (caption "Counted through the semantic view
   SUPPLY_CHAIN_RISK_SEMANTIC_VIEW, the same definitions the Cortex Agent uses"); right column st.dataframe of the
   HIGH and CRITICAL rows of SUPPLIERS (VENDOR_NAME, COUNTRY_CODE, RISK_CATEGORY, GNN_RISK_SCORE, SPEND).
   So what: "All high-risk suppliers are in Australia (lithium) or DR Congo (cobalt): a regional concentration."
   Put the full SUPPLIERS table in an st.expander "All 50 suppliers".
4. "Why: the hidden Tier 2 suppliers": st.bar_chart of BOTTLENECKS (x EXTERNAL_SUPPLIER, y DEPENDENT_COUNT) and the
   caption "None of these companies is in the SAP vendor master. The GNN found them from trade data (bills of
   lading)". Put LINKS in an st.expander "Predicted hidden links (GNN)".
   So what: name the top 2 bottlenecks and their DEPENDENT_COUNT out of 50 suppliers.
5. "What it hits: parts and products": st.dataframe of MATERIALS with NUM_SUPPLIERS <= 1, then st.dataframe of BOM.
   So what: "A single-source part can stop the whole battery pack."
6. "Are we covered: contracts": 2 st.metric cards (number of contracts, total ANNUAL_VALUE_USD in $M) and
   st.dataframe of CONTRACTS. So what: "Check force majeure and termination terms with the Tier 2 suppliers above."
7. "What to do next": st.success with 3 numbered actions: qualify a second source for the HIGH/CRITICAL suppliers;
   engage the top Tier 2 bottlenecks directly and add them to supplier monitoring; add buffer stock for the
   single-source critical parts.
8. "How SAP and Snowflake made this possible" (the business architecture): 3 st.columns cards:
   "SAP - system of record" (vendors, materials, purchase orders, bill of materials),
   "SAP BDC Connect - the bridge" (zero-copy data products, SAP semantics kept, no extracts),
   "Snowflake - system of context" (trade data, regional risk, contracts, GNN, semantic view, Cortex AI).
   Then an st.table "Business question / Data combined / Business value" with one row per sections 2-6.
   End with st.info("Built from one prompt: a high-fidelity prototype for design-thinking sessions, on the same
   data products and objects a production app would use.")

PAGE 2 - "Technical Architecture":
1. One paragraph: how the app was built (one Cortex Code prompt in Snowsight; runs inside Snowflake as
   DEMO_19865_ROLE on warehouse DEMO_19865_WH; no servers, credentials or data movement).
2. "Data flow" as a numbered st.markdown list: SAP S/4HANA -> SAP BDC Connect (zero-copy) -> 4 SAP data product
   databases -> views joining SAP + GNN outputs -> semantic view -> this app and the Cortex Agent.
3. st.table "Component / What it is / Snowflake feature" with rows: SAP data products (4 databases, zero-copy
   sharing); views VW_SUPPLIER_RISK, VW_MATERIAL_RISK, VW_HIDDEN_DEPENDENCIES; semantic view
   SUPPLY_CHAIN_RISK_SEMANTIC_VIEW (semantic views, verified queries); Cortex Search CONTRACT_SEARCH_SERVICE;
   Cortex Agent GNN_SUPPLY_RISK_AGENT; GNN model (Snowpark Container Services); this app (Streamlit in Snowflake,
   built by Cortex Code).
4. 3 st.metric cards: "Databases used" = 5, "Queries behind the dashboard" = 8, "Data copied out of Snowflake" = 0.
5. st.expander "The SQL behind each section" showing the 8 queries with st.code(..., language="sql").

FINISH
- Run each SQL once to confirm it works, then deploy the app.
- Make sure the app has the PyPI mirror attached:
    ALTER STREAMLIT DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.SUPPLY_RISK_DASHBOARD
      SET ARTIFACT_REPOSITORIES = (snowflake.snowpark.pypi_shared_repository);
- Open the app and check every page loads. If you see a package or Streamlit version error, re-check the
  3 files and the artifact repository above, fix them and restart the app.
- Give me the app link.
```

**What happens next:** CoCo runs the queries, writes the 3 files, deploys the app and returns a link. Approve its
steps when asked. It typically takes **5-10 minutes**. While you wait,
read Step 4.

> **Why the prompt talks about packages and runtimes:** new Streamlit apps run on the **container runtime**,
> which builds a fresh Python environment from `pyproject.toml` every time it starts. Streamlit itself must be listed
> there, and the packages are downloaded when the app starts. A trial account has no internet access, so the app uses
> Snowflake's **built-in PyPI mirror** (`SNOWFLAKE.SNOWPARK.PYPI_SHARED_REPOSITORY`), attached as an *artifact
> repository*. Setup already gave `DEMO_19865_ROLE` access to it. The `environment.yml` is only a safety net in case
> the app lands on the older warehouse runtime.

> **Why the prompt is so specific:** the exact SQL, files and chart types leave CoCo nothing to guess. The
> same prompt then gives similar apps for every trainee. That's what *zero-shot* means here: no back-and-forth needed.

## Step 3 - Open the app and check it
0. **Before you open the app the first time:** create a new SQL file (in `gnn_training` or My Workspace: **+ Add
   new > SQL File**), set role **ACCOUNTADMIN**, paste these 3 lines and **Run All**:

   ```sql
   USE ROLE ACCOUNTADMIN;
   ALTER GIT REPOSITORY TRAINING_KIT_REPO.PUBLIC.GNN_KIT FETCH;
   EXECUTE IMMEDIATE FROM @TRAINING_KIT_REPO.PUBLIC.GNN_KIT/branches/main/snowsight/07a_lab5_prepare_app.sql;
   ```

   **What it does:** fetches the latest course files from GitHub and runs `snowsight/07a_lab5_prepare_app.sql`, which
   attaches Snowflake's built-in PyPI mirror to the app so it can install Streamlit and starts first time.
   **Expected:** one row starting with **DONE**. Safe to run more than once.

   > **Why not open the file in `gnn_training`?** Your Git workspace shows the course files as they were when you
   > created it. Files added later (like this one) only appear after you pull the latest changes. The 3 lines above
   > always run the latest version, whatever your workspace shows.
1. Click the link CoCo returns. Or, in the left navigation, open **Apps** (in some accounts **Projects**) >
   **Streamlit** and click **Supply Chain Risk Dashboard**.
2. On **Executive overview**, compare the tiles with the **Expected numbers** table above.
3. Scroll the **Supply Chain Risk Dashboard** tab from top to bottom, then open the **Technical Architecture** tab.
   Both should load without a red error box. Hover over the **?** next to each headline number to read its definition.

**Checkpoint:** run `snowsight/08_readiness_check.sql` again. The row **Lab 5 dashboard SUPPLY_RISK_DASHBOARD**
should show `1`.

| If you see | Do this |
| --- | --- |
| A KPI doesn't match the table | Ask CoCo: *"Use the SPEND query from my prompt exactly as written; spend at risk should be $18.6M."* |
| *Failed to get the version of the Streamlit library ... ">=1.48.0"* | Streamlit isn't installed in the app's environment: `pyproject.toml` doesn't list it, or the PyPI mirror isn't attached. Ask CoCo: *"Set pyproject.toml dependencies to [\"streamlit[snowflake]>=1.50\", \"pandas\"] as in my prompt."* Then re-run the 3 lines in Step 3.0 and reload the app |
| *Failed to retrieve packages from the package server. Have you enabled External Access Integration (EAI)?* (mentions `pypi.org`) | The PyPI mirror isn't attached, so the app tries the public internet. Re-run the 3 lines in Step 3.0, then reload the app |
| *Installing dependencies failed because the pyproject.toml file does not exist* | Ask CoCo: *"Add the pyproject.toml exactly as in my original prompt and restart the app."* Then re-run the 3 lines in Step 3.0 |
| A page shows a red error | Paste the error into CoCo and ask it to fix the page and redeploy |
| CoCo says a model or feature isn't available | Check the readiness row **Cortex cross-region inference = ANY_REGION**. If it's missing, re-run `snowsight/01_stage1_account.sql` |
| No time, or CoCo isn't available | Use the fallback below |

**Fallback (2 minutes):** in `gnn_training`, open `snowsight/07_lab5_dashboard.sql`, set role **ACCOUNTADMIN**
and **Run All**. It deploys the tested reference app from the course repository (`labs/lab5_app/streamlit_app.py`),
with the same name and a richer 7-page design (map, network diagram, contract search), on the warehouse runtime. Expected: **3 rows, all PASS**.
Note: it **replaces** an app with the same name, including one CoCo built.

## Step 4 - Look behind the app
Open the app's code: in the app, click **Edit** (top-right). Or ask CoCo to *"show me the code of
SUPPLY_RISK_DASHBOARD"*. Then find:
- **The SAP data products**, queried with their quoted SAP names. That's the same code that would run on live SAP
  BDC data products.
- **`SEMANTIC_VIEW(...)`** on the Executive overview: the dashboard and the Lab 2 agent use the **same definition**
  of risk category.
- **`st.connection("snowflake").session()`**: the app runs **inside Snowflake** as `DEMO_19865_ROLE`. No passwords, no server, no
  data leaving the platform.

## Step 5 - Iterate like a product team (pick one or two)
Now add the richer features, **one prompt at a time**, and watch the app change. Small steps keep each change
reliable:
- **Contract search (Cortex Search):** *"In section 6 (Are we covered), add a text box that searches the contracts with
  SNOWFLAKE.CORTEX.SEARCH_PREVIEW('DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.CONTRACT_SEARCH_SERVICE', ...) using columns
  CONTRACT_ID, CONTRACT_TITLE, SUPPLIER_NAME and CONTRACT_TEXT, limit 3, and show each result in an expander.
  Escape single quotes in the search text."* Then search *can we walk away from the agreement early*.
- **Network diagram:** *"In section 4 (Why: the hidden Tier 2 suppliers), add an st.graphviz_chart built as a DOT string from LINKS (external
  supplier -> SAP supplier, label = probability). Don't add any package."*
- **What-if:** *"In section 2 (The headline), add a selectbox of bottlenecks and show how much SAP spend sits with the SAP
  suppliers linked to it in LINKS."*
- **Download:** *"In section 3, add a download button for the supplier table as CSV."*

Each change takes minutes. This is the loop you'd run with business users in the room.

---

## Use it for design thinking: from idea to high-fidelity demo in one session

The prompt-to-app pattern changes what a workshop can produce. Instead of sticky notes and slides, the team leaves
with a **working prototype on governed, production-shaped data**.

| Design-thinking phase | What you do | What Snowflake gives you |
| --- | --- | --- |
| **Empathise** | Interview procurement, supply chain and finance: which decisions, which pain? | The Labs 1-2 data and agent, to explore their questions live |
| **Define** | Write 3-5 business questions (like the *What you'll build* table) | The semantic view, so everyone uses one definition of "risk" or "spend" |
| **Ideate** | Sketch pages and KPIs together | Section 8 (how SAP and Snowflake made this possible) as a shared picture of the value |
| **Prototype** | Turn the sketch into a prompt; CoCo builds the app in minutes | Streamlit in Snowflake on the real object names, roles and data products |
| **Test** | Users click through the app the same day; capture feedback | Follow-up prompts change the app while users watch |
| **Decide** | Keep, change or drop; agree what production needs | The Technical Architecture page lists every dependency to productionise |

**Suggested 2-hour workshop:** 20 min problem framing, 20 min questions and KPIs, 15 min writing the prompt together,
20 min while CoCo builds (review the data with Lab 1 queries), 30 min user testing and follow-up prompts, 15 min
decision and next steps.

**Why it's high-fidelity, not a mock-up:** it runs on the same SAP data product names, semantic view, Cortex Search
service, roles and warehouse a production app would use. Moving to production means **replacing the snapshot
databases with live SAP BDC Connect data products, then hardening and governing the app**. You don't rebuild it.

---

## Discuss
1. Which page would your leadership open first, and which KPI would they challenge? How would you prove it?
2. The app and the Lab 2 agent read the same semantic view. Why does that matter when two teams report "spend at risk"?
3. What would you need to add before this app goes to production? Think about refresh, access, testing and ownership.

## Clean up (optional)
```sql
DROP STREAMLIT IF EXISTS DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.SUPPLY_RISK_DASHBOARD;
```
**What it does:** removes only the app. `snowsight/99_remove_setup.sql` also removes it, with everything else.
