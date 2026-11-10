# Lab 5 (optional) - Build a supply chain risk dashboard with one prompt

> [!CAUTION]
> **Disclaimer:** all data in this lab is **synthetic and for demonstration only**. Company names (for example
> Albemarle Corp, BYD Battery or Queensland Minerals) are used for illustration. The vendors, purchase orders,
> trade records, contracts, risk scores and predicted links are invented and **don't describe any real
> company, relationship or risk**. Don't use them for business decisions.

> **In Labs 1 to 4 you asked questions. In Lab 5 you hand the business a working app.** One prompt to Cortex Code
> (CoCo) in Snowsight turns 4 SAP data products, external signals, GNN predictions and supplier contracts into a
> 6-page dashboard: spend at risk, hidden Tier 2 bottlenecks, exposed products, contract coverage, and two pages
> that explain the business and technical architecture behind it. Then you grow it, one prompt at a time.

> [!TIP]
> **Key takeaway: one prompt turns SAP data products into a governed, production-shaped app, fast enough to build live in a design-thinking session.**
> - **SAP stays the system of record; Snowflake adds the context.** The app joins 5 databases without copying SAP data.
> - **The semantic view and Cortex Search are reused.** The dashboard, the agent and analysts share one definition of risk.
> - **A prototype isn't throwaway.** It already runs on the production object names, roles and platform. Going live
>   means pointing it at live SAP BDC data products.

**Time:** 45-60 minutes (10-20 of them are CoCo building the app). **Before you start:**
`snowsight/08_readiness_check.sql` must say READY, including the row **Cortex cross-region inference = ANY_REGION**
(set in Stage 1, so CoCo can use a region where its models are available).
Labs 1 to 3 help you read the dashboard, but they aren't required: Lab 5 only needs the setup.

---

## What you'll build

| Page | Business question | Data it combines |
| --- | --- | --- |
| 1. Executive overview | How much of our spend is exposed? | SAP purchase orders x GNN risk, bottlenecks, materials, **semantic view** |
| 2. Suppliers | Who are the risky suppliers, and how much do we spend with them? | SAP vendors (financial health) + GNN risk + SAP spend |
| 3. Hidden Tier 2 | Who are we *really* depending on? | GNN predicted links + Tier 2 bottlenecks |
| 4. Materials & contracts | Which parts and products are exposed, and are we covered? | SAP materials + SAP BOM + material risk + contracts |
| 5. Business architecture | Why does this work, and what value does it create? | SAP (system of record) + SAP BDC Connect + Snowflake (system of context) |
| 6. Technical architecture | How was it built, and what does it depend on? | Every Snowflake object behind the app |

The prompt is deliberately **simple**: it gives CoCo the exact, tested SQL for every page and uses only built-in
Streamlit charts. That makes the first run very likely to work. You add the richer features (map, network
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
Build and deploy a simple Streamlit in Snowflake app. Keep it simple: correctness matters more than design.

APP SETUP
- Name: DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.SUPPLY_RISK_DASHBOARD, title "Supply Chain Risk Dashboard".
- Owner role DEMO_19865_ROLE, query warehouse DEMO_19865_WH.
- No package downloads: this account can't reach PyPI. Use only streamlit and pandas (already installed).
- Create exactly 3 files:
  1) streamlit_app.py
  2) pyproject.toml, exactly:
     [project]
     name = "supply-risk-dashboard"
     version = "0.1.0"
     requires-python = ">=3.11"
     dependencies = []
  3) environment.yml, exactly:
     name: app_environment
     channels:
       - snowflake
     dependencies:
       - streamlit
       - pandas
       - snowflake-snowpark-python
  Do not create requirements.txt. Do not add any other package or external access integration.
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
- Use only st.metric, st.bar_chart, st.dataframe, st.markdown, st.table, st.warning and a sidebar st.radio for
  6 pages. On every page show st.warning("Synthetic data, for demonstration only. No real company, relationship
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

PAGES
1. Executive overview: 4 st.metric tiles: total PO spend and spend at risk in $M with its % of total (SPEND),
   number of bottlenecks with DEPENDENT_COUNT >= 10 (BOTTLENECKS), number of materials with NUM_SUPPLIERS <= 1 and CRITICALITY_SCORE >= 0.8
   (MATERIALS). st.bar_chart of RISK_MIX with the caption "Queried through the semantic view".
2. Suppliers: st.dataframe of SUPPLIERS and st.bar_chart of SPEND by RISK_CATEGORY.
3. Hidden Tier 2: st.dataframe of LINKS and st.bar_chart of BOTTLENECKS (EXTERNAL_SUPPLIER vs DEPENDENT_COUNT),
   with the caption "Tier 2 suppliers are not in the SAP vendor master; a graph neural network predicts them".
4. Materials & contracts: st.dataframe of MATERIALS, BOM and CONTRACTS, each with a one-line st.markdown heading.
5. Business architecture: st.markdown text, no diagrams. Explain: SAP is the system of record (vendors,
   materials, purchase orders, bill of materials); SAP BDC Connect shares them with Snowflake as zero-copy data
   products; Snowflake is the system of context (trade data, regional risk, contracts, GNN predictions, semantic
   view). Then an st.table "Business question / Data combined / Business value" with one row per page 1-4.
   End with: "Built from one prompt: a high-fidelity prototype for design-thinking sessions before production."
6. Technical architecture: st.markdown text, no diagrams. An st.table "Component / What it is / Snowflake
   feature" with rows: SAP data products (4 databases, zero-copy sharing); views (VW_SUPPLIER_RISK,
   VW_MATERIAL_RISK, VW_HIDDEN_DEPENDENCIES); semantic view SUPPLY_CHAIN_RISK_SEMANTIC_VIEW; Cortex Search
   CONTRACT_SEARCH_SERVICE; Cortex Agent GNN_SUPPLY_RISK_AGENT; GNN model (Snowpark Container Services); this
   app (Streamlit in Snowflake, built by Cortex Code). Then 3 bullets on how it was built.

FINISH
- Run each SQL once to confirm it works, deploy the app, open it and check every page loads.
- If you see a package or dependency error, re-check the 3 files above, fix them and restart the app.
- Give me the app link.
```

**What happens next:** CoCo runs the queries, writes the 3 files, deploys the app and returns a link. Approve its
steps when asked. It typically takes **5-10 minutes**. While you wait,
read Step 4.

> **Why the prompt talks about packages and runtimes:** Streamlit in Snowflake has two runtimes. The
> **container runtime** (the default for new apps) reads `pyproject.toml` and downloads every package listed in it
> from PyPI, which a trial account can't reach. The **warehouse runtime** reads `environment.yml` and uses the
> Snowflake Anaconda channel. This app only needs packages that both runtimes already include, so the prompt asks
> for an **empty** `pyproject.toml` *and* an `environment.yml`: whichever runtime CoCo uses, nothing is downloaded.

> **Why the prompt is so specific:** the exact SQL, files and chart types leave CoCo nothing to guess. The
> same prompt then gives similar apps for every trainee. That's what *zero-shot* means here: no back-and-forth needed.

## Step 3 - Open the app and check it
1. Click the link CoCo returns. Or, in the left navigation, open **Apps** (in some accounts **Projects**) >
   **Streamlit** and click **Supply Chain Risk Dashboard**.
2. On **Executive overview**, compare the tiles with the **Expected numbers** table above.
3. Click through all 6 pages in the sidebar. Each one should load without a red error box.

**Checkpoint:** run `snowsight/08_readiness_check.sql` again. The row **Lab 5 dashboard SUPPLY_RISK_DASHBOARD**
should show `1`.

| If you see | Do this |
| --- | --- |
| A KPI doesn't match the table | Ask CoCo: *"Use the SPEND query from my prompt exactly as written; spend at risk should be $18.6M."* |
| *Installing dependencies failed because the pyproject.toml file does not exist* | The app is on the **container runtime** and has no `pyproject.toml`. Ask CoCo: *"Add a pyproject.toml with name, version, requires-python >=3.11 and an empty dependencies list, as in my original prompt, then restart the app."* |
| *Failed to retrieve packages from the package server. Have you enabled External Access Integration (EAI)?* (mentions `pypi.org`) | The app's `pyproject.toml` or `requirements.txt` **lists packages**, so the container tries to download them from PyPI. Ask CoCo: *"Empty the dependencies list in pyproject.toml, delete requirements.txt if it exists, and restart the app. Use only pre-installed packages."* Or move the app to the warehouse runtime: `ALTER STREAMLIT DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.SUPPLY_RISK_DASHBOARD SET RUNTIME_NAME = 'SYSTEM$WAREHOUSE_RUNTIME';` (needs the `environment.yml` from the prompt) |
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
- **Contract search (Cortex Search):** *"On Materials & contracts, add a text box that searches the contracts with
  SNOWFLAKE.CORTEX.SEARCH_PREVIEW('DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.CONTRACT_SEARCH_SERVICE', ...) using columns
  CONTRACT_ID, CONTRACT_TITLE, SUPPLIER_NAME and CONTRACT_TEXT, limit 3, and show each result in an expander.
  Escape single quotes in the search text."* Then search *can we walk away from the agreement early*.
- **Network diagram:** *"On Hidden Tier 2, add an st.graphviz_chart built as a DOT string from LINKS (external
  supplier -> SAP supplier, label = probability). Don't add any package."*
- **What-if:** *"On Executive overview, add a selectbox of bottlenecks and show how much SAP spend sits with the SAP
  suppliers linked to it in LINKS."*
- **Download:** *"On Suppliers, add a download button for the table as CSV."*

Each change takes minutes. This is the loop you'd run with business users in the room.

---

## Use it for design thinking: from idea to high-fidelity demo in one session

The prompt-to-app pattern changes what a workshop can produce. Instead of sticky notes and slides, the team leaves
with a **working prototype on governed, production-shaped data**.

| Design-thinking phase | What you do | What Snowflake gives you |
| --- | --- | --- |
| **Empathise** | Interview procurement, supply chain and finance: which decisions, which pain? | The Labs 1-2 data and agent, to explore their questions live |
| **Define** | Write 3-5 business questions (like the *What you'll build* table) | The semantic view, so everyone uses one definition of "risk" or "spend" |
| **Ideate** | Sketch pages and KPIs together | The Business architecture page as a shared picture of the value |
| **Prototype** | Turn the sketch into a prompt; CoCo builds the app in minutes | Streamlit in Snowflake on the real object names, roles and data products |
| **Test** | Users click through the app the same day; capture feedback | Follow-up prompts change the app while users watch |
| **Decide** | Keep, change or drop; agree what production needs | The Technical architecture page lists every dependency to productionise |

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
