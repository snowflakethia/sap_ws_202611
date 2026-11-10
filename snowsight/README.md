# GNN Supply Chain Risk - Trainee Guide (Snowsight only)

> [!CAUTION]
> **Disclaimer:** all data in this lab is **synthetic and for demonstration only**. Company names (for example
> Albemarle Corp, BYD Battery or Queensland Minerals) are used for illustration. The vendors, purchase orders,
> trade records, contracts, risk scores and predicted links are invented and **don't describe any real
> company, relationship or risk**. Don't use them for business decisions.

Welcome! In this course you build a supply chain risk demo in your own Snowflake account, and then
explore it in four labs. Everything happens in **Snowsight** (the Snowflake web UI). You don't need to
install anything.

> **Prefer one page with every click?** Use the step-by-step guide in the main **[README](../README.md#setup-browser-only-about-30-minutes)**.

**What you'll build:**
- SAP S/4HANA supplier and material data.
- Risk scores from a graph neural network (GNN).
- A Cortex Search service over supplier contracts.
- A semantic view.
- A **Cortex Agent** that answers questions about supply chain risk.

| You need | Check |
| --- | --- |
| A Snowflake account you can sign in to | You reach the Snowsight home page |
| The **ACCOUNTADMIN** role | Lower-left: your name > Switch role > ACCOUNTADMIN |
| About 30 minutes for the setup | |

> **Golden rule:** run the files **in order**. At each **CHECKPOINT**, compare the last result with the
> expected table below before you continue. If a checkpoint doesn't match, re-run the same file once
> (every file is safe to re-run). If it still doesn't match, ask your trainer.

---

## Part 1 - Setup

### Step 0 - Connect Snowflake to the course repository (copy and paste, once)
1. In a new browser tab, open the plain-text file [https://raw.githubusercontent.com/snowflakethia/sap_ws_202611/main/snowsight/00_bootstrap.sql](https://raw.githubusercontent.com/snowflakethia/sap_ws_202611/main/snowsight/00_bootstrap.sql).
   Click on the page, press **Ctrl/Cmd + A** (select all), then **Ctrl/Cmd + C** (copy).
2. In Snowsight, click **Workspaces** in the left navigation. **Don't create a new workspace**: with **My Workspace** selected, click the grey **+ Add new** > **SQL File**.
   Paste the file, set the role to **ACCOUNTADMIN**, then select **Run All**.

**CHECKPOINT 0 - expected last result:** 4 rows listing
`data/sap/s4custom_billofmaterials.csv`, `s4custom_materials.csv`, `s4custom_purchase_orders.csv` and
`s4custom_vendors.csv`.

### Step 0b - Create your Git workspace
Follow [`00b_create_git_workspace.md`](00b_create_git_workspace.md). It takes 2 minutes.

**CHECKPOINT 0b - expected:**
- A workspace named **gnn_training**.
- Folders `snowsight/`, `sql/`, `data/`, `labs/` and `workspace/` in it.

From now on, open each file **inside `gnn_training`**, then select **Run All** with role **ACCOUNTADMIN**.

### Stage 1 - Account objects: `snowsight/01_stage1_account.sql` (about 1 minute)
**CHECKPOINT 1 - expected last result:**

| CHECK_NAME | ACTUAL | RESULT |
| --- | --- | --- |
| S1-A role DEMO_19865_ROLE exists | 1 | PASS |
| S1-A warehouse size/auto_suspend/owner | SMALL/300/DEMO_19865_ROLE | PASS |
| S1-A compute pool family/nodes | CPU_X64_M/1-1 | PASS |
| S1-B integrations | `DEMO_19865_PIP_INSTALLATION:true`, or `none` on a **trial** account | PASS, or **INFO** on trial (expected) |
| S1-C key grants to DEMO_19865_ROLE | 4 (3 on trial) | PASS |

### Stage 2 - SAP data: `snowsight/02_stage2_sap_data.sql` (about 1 minute)
**CHECKPOINT 2 - expected last result:** every row PASS.
- `S2-A 4 SAP snapshot databases, kind STANDARD` = `4/4`
- Rows: vendors **50**, materials **26**, purchase_orders **120**, billofmaterials **23**, TOTAL **219**
- `S2-C vendor columns populated` = `50/50/50/50`

### Stage 3 - Demo schema: `snowsight/03_stage3_demo_schema.sql` (under 1 minute)
Expected last result: every row PASS.
- `6 tables, iceberg=0`
- views `4`
- `compiled and ran`
- stages + file format `3 + 1`
- `DEMO_SECRETS_STAGE is empty` = `0`

### Stage 4 - Demo data: `snowsight/04_stage4_demo_data.sql` (about 1 minute)
**CHECKPOINT 3 - expected last result:** every row PASS.
- Table rows: BOTTLENECKS **10**, CUSTOMER_CONTRACTS **12**, REGIONS **9**, RISK_SCORES **86**,
  SUPPLIER_LINKS **381**, TRADE **150**, TOTAL **648**
- `VW_RISK_SUMMARY SUPPLIERS` = `50/2/4/0.4060`, `PARTS` = `26/0/0/0.4768`
  (total / critical / high / average risk score)
- `VW_SUPPLIER_RISK` **50**, `VW_MATERIAL_RISK` **26**, `VW_HIDDEN_DEPENDENCIES` **26**, EMBEDDING = `ARRAY`

### Stage 5 - Search and semantic view: `snowsight/05_stage5_search_semantic_view.sql` (1-6 minutes)
The file waits for the search index to finish building, so don't worry if it takes a few minutes.

**CHECKPOINT 4 - expected last result:** every row PASS.
- Search service = `CONTRACT_TEXT ACTIVE/ACTIVE`
- Semantic view exists = `1`
- Search "force majeure" = `3 results, first=SC-...`
- Semantic view structure = `4 tables, 9 facts, 26 dimensions`
- Semantic view query = `50 rows: CRITICAL 2, HIGH 4, MEDIUM 44`

If the search row shows **WAIT**, wait one minute and run the file again.

### Stage 6 - The agent: `snowsight/06_stage6_agent.sql` (under 1 minute)
**CHECKPOINT 5, part 1 - expected last result:** every row PASS.
- Agents = `1:GNN_SUPPLY_RISK_AGENT`
- Tools = `supply_chain_risk_analyst,contract_search`
- Instructions = `true/true`

**CHECKPOINT 5, part 2 - in the UI:**
1. In the left navigation, hover over **AI** > **Agent Studio**. On the **Agents** tab, click **GNN_SUPPLY_RISK_AGENT**, then click the **Preview** tab. Ask your questions there.
2. Ask: **Which suppliers are CRITICAL risk?**
3. Expected: a table naming **Albemarle Corp** and **Epsilon Tech** (both AUS, GNN risk score about 0.61).

### Step 7 - Am I ready? `snowsight/08_readiness_check.sql`
Run it any time; it changes nothing.

**Expected:** the first row reads **`OVERALL | READY | PASS - you can start the labs`**, followed by 8 PASS rows
and 1 INFO row (the workspace, which you already checked).

If it says **NOT READY**, find the first FAIL row and re-run the file named in its **FIX** column. Then run
the readiness check again.

---

## Part 2 - Labs

| Lab | File | Time | What you'll do |
| --- | --- | --- | --- |
| 1 | [labs/LAB1_explore_data.md](labs/LAB1_explore_data.md) | 15 min | Look at the SAP data, external signals and GNN results with SQL |
| 2 | [labs/LAB2_ask_the_agent.md](labs/LAB2_ask_the_agent.md) | 20 min | Ask the agent 5 questions and see which tool answers each one |
| 3 | [labs/LAB3_build_your_own_agent.md](labs/LAB3_build_your_own_agent.md) | 20 min | Build your own agent in the Snowsight UI |
| 4 (optional) | [labs/LAB4_optional_retrain_gnn.md](labs/LAB4_optional_retrain_gnn.md) | 45-60 min | Re-run the GNN notebook. **Not possible on trial accounts** |

---

## Part 3 - Remove the setup (when the course is over)
1. Open `snowsight/99_remove_setup.sql` in `gnn_training`, then select **Run All** with role ACCOUNTADMIN.
   **Expected last result:** 6 rows, every RESULT = **REMOVED**.
2. Delete the workspace: **Workspaces** (left navigation), open the workspace menu, select the **...** next to
   `gnn_training` > **Delete**.

This removes only what the course created. Nothing else in your account is touched.

---

## Help

| Problem | What to do |
| --- | --- |
| `Insufficient privileges` / `does not exist or not authorized` | Make sure the role (in the editor's context bar) is **ACCOUNTADMIN** |
| `Git repository ... does not exist` | Run Step 0 (`00_bootstrap.sql`) first |
| A checkpoint row says FAIL | Re-run the same file once. If it still fails, re-run the previous stage, then this one |
| Stage 1 shows INFO for integrations | Expected on trial accounts. Continue |
| Stage 5 search row says WAIT | The index is still building. Wait a minute and re-run Stage 5 |
| The agent says it has no access | Switch your Snowsight role to ACCOUNTADMIN and ask again |
| Anything else | Run `08_readiness_check.sql` and show the result to your trainer |
