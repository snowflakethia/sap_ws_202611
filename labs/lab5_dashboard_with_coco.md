# Lab 5 (optional) - Build a supply chain risk dashboard with one prompt

> [!CAUTION]
> **Disclaimer:** all data in this lab is **synthetic and for demonstration only**. Company names (for example
> Albemarle Corp, BYD Battery or Queensland Minerals) are used for illustration. The vendors, purchase orders,
> trade records, contracts, risk scores and predicted links are invented and **don't describe any real
> company, relationship or risk**. Don't use them for business decisions.

> **In Labs 1 to 4 you asked questions. In Lab 5 you hand the business a working app.** One prompt to Cortex Code
> (CoCo) in Snowsight turns 4 SAP data products, external signals, GNN predictions and supplier contracts into a
> 7-page dashboard: spend at risk, hidden Tier 2 bottlenecks, exposed products, contract coverage, and two pages
> that explain the business and technical architecture behind it.

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
| 1. Executive overview | How much of our spend is exposed, and what do we do first? | SAP purchase orders x GNN risk, bottlenecks, materials, semantic view |
| 2. Supplier risk explorer | Where does the risk sit, and is it financial or network risk? | SAP vendors (financial health) + GNN risk + region risk + spend |
| 3. Hidden Tier 2 dependencies | Who are we *really* depending on? | GNN predicted links + Tier 2 bottlenecks |
| 4. Materials & BOM exposure | Which finished products stop if a part runs out? | SAP materials + SAP BOM + material risk |
| 5. Contracts | Are we covered, and what do the contracts say? | Contracts + **Cortex Search** |
| 6. Business architecture | Why does this work, and what value does it create? | SAP (system of record) + SAP BDC Connect + Snowflake (system of context) |
| 7. Technical architecture | How was it built, and what does it depend on? | Every Snowflake object behind the app |

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
Build and deploy a Streamlit in Snowflake app for supply chain and procurement leaders, using only the data below.

APP
- Name: DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.SUPPLY_RISK_DASHBOARD, title "Supply Chain Risk Dashboard".
- Create it as role DEMO_19865_ROLE (USE ROLE DEMO_19865_ROLE), query warehouse DEMO_19865_WH.
- Single file streamlit_app.py. Use only streamlit, pandas, altair and snowflake.snowpark (get_active_session).
- Read-only: SELECT queries only. Cache query results with st.cache_data.
- Sidebar radio for navigation between 7 pages. On every page show st.warning: "Synthetic data, for
  demonstration only. Company names are used for illustration; no real company, relationship or risk is described."
- Test every SQL query before deploying. Fix any error yourself, then deploy and give me the app link.

DATA (exact names; SAP names are lowercase and must be double-quoted exactly as shown)
SAP data products (system of record):
- VENDORS = S4_ZVENDORINFO_DP_DELTA_SHARING_V1."s4_zvendorinfo_dp_srv:v1"."s4custom_vendors"
  (VENDOR_ID, NAME, COUNTRY_CODE, CITY, TIER, FINANCIAL_HEALTH_SCORE)
- MATERIALS = S4_ZMATERIALS_DP_DELTA_SHARING_V1."s4_zmaterials_dp_srv:v1"."s4custom_materials"
  (MATERIAL_ID, DESCRIPTION, MATERIAL_GROUP, UNIT_OF_MEASURE, CRITICALITY_SCORE, INVENTORY_DAYS)
- POS = S4_ZPURCHASEORDERS_DP_DELTA_SHARING_V1."s4_zpurchaseorders_dp_srv:v1"."s4custom_purchase_orders"
  (PO_ID, VENDOR_ID, MATERIAL_ID, QUANTITY, UNIT_PRICE, ORDER_DATE, DELIVERY_DATE, STATUS OPEN/CLOSED)
- BOM = S4_ZBILLOFMATERIALS_DP_DELTA_SHARING_V1."s4_zbillofmaterials_dp_srv:v1"."s4custom_billofmaterials"
  (BOM_ID, PARENT_MATERIAL_ID, CHILD_MATERIAL_ID, QUANTITY_PER_UNIT)
Snowflake context, schema DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK:
- VW_SUPPLIER_RISK (VENDOR_ID, VENDOR_NAME, COUNTRY_CODE, TIER, REGION_RISK, GNN_RISK_SCORE, RISK_CATEGORY, CONFIDENCE)
- VW_MATERIAL_RISK (MATERIAL_ID, DESCRIPTION, MATERIAL_GROUP, CRITICALITY_SCORE, GNN_RISK_SCORE, RISK_CATEGORY,
  NUM_SUPPLIERS, AVG_SUPPLIER_RISK)
- VW_HIDDEN_DEPENDENCIES (SOURCE_NAME, TARGET_NAME, PROBABILITY, EVIDENCE_STRENGTH): GNN-predicted Tier 2 links
- BOTTLENECKS_PREDICTIONS (NODE_ID = external supplier name, DEPENDENT_COUNT, IMPACT_SCORE, MITIGATION_STATUS)
- CUSTOMER_CONTRACTS (CONTRACT_ID, CONTRACT_TITLE, SUPPLIER_NAME, SUPPLIER_COUNTRY, MATERIAL_TYPE, CONTRACT_DATE,
  ANNUAL_VALUE_USD, CONTRACT_TEXT)
- Semantic view SUPPLY_CHAIN_RISK_SEMANTIC_VIEW. Query it like:
  SELECT RISK_CATEGORY, COUNT(*) FROM SEMANTIC_VIEW(DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.SUPPLY_CHAIN_RISK_SEMANTIC_VIEW
  DIMENSIONS VW_SUPPLIER_RISK.VENDOR_ID, VW_SUPPLIER_RISK.RISK_CATEGORY) GROUP BY 1
- Cortex Search service CONTRACT_SEARCH_SERVICE on CONTRACT_TEXT. Query it with
  SNOWFLAKE.CORTEX.SEARCH_PREVIEW('DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.CONTRACT_SEARCH_SERVICE',
  '{"query": "...", "columns": ["CONTRACT_ID","CONTRACT_TITLE","SUPPLIER_NAME","CONTRACT_TEXT"], "limit": 3}')
  and parse the JSON "results" array. Escape single quotes in the user's text.
Spend = QUANTITY * UNIT_PRICE from POS. Join suppliers on VENDOR_ID, materials on MATERIAL_ID.

PAGES
1. Executive overview: st.metric tiles for total PO spend, spend at risk (spend with HIGH or CRITICAL suppliers,
   and its % of total), unmitigated bottlenecks with DEPENDENT_COUNT >= 10, and materials with NUM_SUPPLIERS <= 1
   and CRITICALITY_SCORE >= 0.8. A bar chart of suppliers by risk category queried through the semantic view
   (say so in a caption), a donut of spend by risk category, and the top 5 actions for HIGH/CRITICAL suppliers.
2. Supplier risk explorer: filters for country, tier and risk category; st.map of suppliers by country (use a
   small hard-coded country-code to lat/lon lookup for AUS, CHL, CHN, COD, DEU, JPN, KOR, MEX, USA); average GNN risk
   by country; a scatter of SAP FINANCIAL_HEALTH_SCORE vs GNN_RISK_SCORE sized by spend; a detail table.
3. Hidden Tier 2 dependencies: probability slider (0.5-0.9, default 0.55); st.graphviz_chart network built as a
   DOT string from external supplier -> SAP supplier with probability labels; bar chart and table of bottlenecks.
4. Materials & BOM exposure: scatter of INVENTORY_DAYS vs CRITICALITY_SCORE coloured by number of suppliers; BOM
   joined to MATERIALS (parent and component names) and VW_MATERIAL_RISK, rolled up per finished product (number
   of components, highest component risk, single-source components).
5. Contracts: metrics (number of contracts, annual value, bottleneck suppliers with a contract); the contracts
   table; a text box that searches contracts with Cortex Search and shows each hit in an expander.
6. Business architecture: a graphviz diagram SAP (system of record: vendors, materials, POs, BOM) -> SAP BDC
   Connect (zero-copy data products) -> Snowflake (system of context: trade data, regional risk, contracts, GNN,
   semantic view) -> decisions, with a dashed "publish back" arrow to SAP. A table "business question / data
   combined / business value" for each page. Sections on why SAP data products matter (governed, SAP semantics,
   zero-copy, same names in production) and why the semantic layer matters (one definition of risk shared by the
   app and the Cortex Agent, verified queries). A note that this app was built from one prompt, which makes it a
   high-fidelity prototype for design-thinking sessions before a production build.
7. Technical architecture: a graphviz diagram of CoCo -> the Streamlit app -> warehouse, the 4 SAP data product
   databases, the views, the semantic view, Cortex Search, the Cortex Agent GNN_SUPPLY_RISK_AGENT and the GNN
   trained on Snowpark Container Services. A table "component / what it is / Snowflake feature" covering
   zero-copy data products, cross-database joins, views and RBAC, semantic views and verified queries, Cortex
   Search, Cortex Agents with cross-region inference, Snowpark Container Services, Streamlit in Snowflake and
   Cortex Code. A short "how this app was built" section.
```

**What happens next:** CoCo explores the tables, writes and runs test queries, writes `streamlit_app.py`, deploys
the app and returns a link. Approve its steps when asked. It typically takes **10-20 minutes**. While you wait,
read Step 4.

> **Why the prompt is so specific:** exact object names, columns, pages and rules leave CoCo nothing to guess. The
> same prompt then gives similar apps for every trainee. That's what *zero-shot* means here: no back-and-forth needed.

## Step 3 - Open the app and check it
1. Click the link CoCo returns. Or, in the left navigation, open **Apps** (in some accounts **Projects**) >
   **Streamlit** and click **Supply Chain Risk Dashboard**.
2. On **Executive overview**, compare the tiles with the **Expected numbers** table above.
3. Click through all 7 pages in the sidebar. Each one should load without a red error box.
4. On **Contracts**, search *can we walk away from the agreement early*. It should find contracts about
   termination, the same meaning-based search you ran in Lab 2.

**Checkpoint:** run `snowsight/08_readiness_check.sql` again. The row **Lab 5 dashboard SUPPLY_RISK_DASHBOARD**
should show `1`.

| If you see | Do this |
| --- | --- |
| A KPI doesn't match the table | Ask CoCo: *"The spend at risk should be $18.6M. Check the join between POS and VW_SUPPLIER_RISK and fix it."* |
| A page shows a red error | Paste the error into CoCo and ask it to fix the page and redeploy |
| CoCo says a model or feature isn't available | Check the readiness row **Cortex cross-region inference = ANY_REGION**. If it's missing, re-run `snowsight/01_stage1_account.sql` |
| No time, or CoCo isn't available | Use the fallback below |

**Fallback (2 minutes):** in `gnn_training`, open `snowsight/07_lab5_dashboard.sql`, set role **ACCOUNTADMIN**
and **Run All**. It deploys the tested reference app from the course repository (`labs/lab5_app/streamlit_app.py`),
with the same name and the same pages. Expected: **2 rows, both PASS**.

## Step 4 - Look behind the app
Open the app's code: in the app, click **Edit** (top-right). Or ask CoCo to *"show me the code of
SUPPLY_RISK_DASHBOARD"*. Then find:
- **The SAP data products**, queried with their quoted SAP names. That's the same code that would run on live SAP
  BDC data products.
- **`SEMANTIC_VIEW(...)`** on the Executive overview: the dashboard and the Lab 2 agent use the **same definition**
  of risk category.
- **`SEARCH_PREVIEW(...)`** on Contracts: the same Cortex Search service the agent used in Lab 2.
- **`get_active_session()`**: the app runs **inside Snowflake** as `DEMO_19865_ROLE`. No passwords, no server, no
  data leaving the platform.

## Step 5 - Iterate like a product team (pick one or two)
Ask CoCo, one prompt at a time, and watch the app change:
- *"On Executive overview, add a what-if: if the selected Tier 2 bottleneck stopped shipping, how much SAP spend
  is affected?"*
- *"On Supplier risk explorer, add a download button for the filtered table as CSV."*
- *"On Materials & BOM exposure, flag finished products that depend on a component with fewer than 30 inventory
  days."*

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
