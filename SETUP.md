# Setup Guide - step by step (Snowsight only)

Follow these steps **in order**. Each step says **where to click**, **what to run**, and **what you should see**.
Allow about 30 minutes. You only need a browser.

**Before you start**
- Sign in to your Snowflake account in Snowsight.
- Set your role to **ACCOUNTADMIN**: bottom-left, click your name (for example **ALPHATHIA**) > **Switch role** > **ACCOUNTADMIN**.

> **Why the role matters:** Snowsight uses the role in your **user menu** (bottom-left) to decide what you can
> see in dialogs such as *Create Git workspace*. If that role isn't ACCOUNTADMIN, the dialog says
> *"No API integration available"* even after Step 1.

### Do I create a new workspace? (read this first)

Snowsight has two buttons that look alike. Here's which one to use, and when:

| Step | Create a new workspace? | Button to click | Choose |
| --- | --- | --- | --- |
| **Step 1** (paste one script) | **No.** Use the **My Workspace** that's already there | **+ Add new** (grey button above the file list) | **SQL File** |
| **Step 2** (get the course files) | **Yes, exactly one** | **+** (small plus next to the *Workspaces / Databases* tabs) | **Git workspace** |
| Steps 3 onward | **No.** Use the `gnn_training` workspace from Step 2 | none, just open the files | |

- **Don't** choose *Private workspace* or *Shared workspace* at any point; the course doesn't use them.
- The `demo.ipynb` file you may see in My Workspace is Snowflake's own sample. Ignore it.
- If a Snowflake banner or pop-up appears (for example *"Your legacy worksheets have been moved"* or
  *Automations*), close it with **x** or **Close**. It doesn't affect the course.

### New to GitHub? You don't need to clone anything

You **don't** need a GitHub account, Git, or any downloads. Snowflake reads this course straight from
GitHub for you:

| What you might expect | What actually happens |
| --- | --- |
| "Clone the repository to my laptop" | **Not needed.** Step 1 tells Snowflake where the course is, and Snowflake fetches it itself |
| "Download the files and upload them" | **Not needed.** Step 2 shows every course file inside Snowsight |
| "Sign in to GitHub" | **Not needed.** The course repository is public |

The only thing you take from GitHub is **one block of text** in Step 1, copied from a plain-text page.

---

## Step 1 - Connect your account to the course repository (once, copy and paste)

The only step where you copy code by hand. **Don't create a new workspace for this step.**

> **You'll use two browser tabs:** one shows the code (Tab A), and Snowsight is where you paste and run it (Tab B).

**In Snowsight: open an empty SQL file**
1. In the left navigation, click **Workspaces**.
2. Check that the selector at the top of the file list says **My Workspace**. If it shows another name, click
   it and choose **My Workspace**.
3. Click the grey **+ Add new** button (just above the file list), then **SQL File**. Name it `bootstrap.sql`
   and press Enter. An empty editor tab opens.

**In a new browser tab: copy the code**

4. Open this address in a new browser tab (click it, or paste it into the address bar):

   **https://raw.githubusercontent.com/snowflakethia/sap_ws_202611/main/snowsight/00_bootstrap.sql**

   The page shows only the code, as plain text. Its first line starts with `-- ====`.
   Click anywhere on the text, press **Ctrl + A** (Mac: **Cmd + A**) to select all, then **Ctrl + C**
   (Mac: **Cmd + C**) to copy.

   *Page doesn't open, or your company network blocks it?* Use [Appendix A](#appendix-a---other-ways-to-copy-the-step-1-code).

**Back in Snowsight: paste and run**
5. Click inside the empty `bootstrap.sql` editor and paste: **Ctrl + V** (Mac: **Cmd + V**). You should see about
   45 lines, starting with `-- ====`.
6. At the top of the editor, click **Choose role** and select **ACCOUNTADMIN**. Leave **Choose warehouse** empty.
7. Click the small **arrow next to Run** > **Run All** (or press Ctrl/Cmd + Shift + Enter).
   Don't select any lines first; Run All runs everything.

**Checkpoint 1 - you should see:** in the results pane at the bottom, a table with **4 rows**, ending in
`s4custom_billofmaterials.csv`, `s4custom_materials.csv`, `s4custom_purchase_orders.csv` and `s4custom_vendors.csv`.

| If you see | Do this |
| --- | --- |
| `Insufficient privileges to operate on account` | Your role isn't ACCOUNTADMIN. Switch the role in the context bar and run again |
| `Repository ... not found` / `403` | Check your internet access; don't change the code |
| Only part of the code ran | You selected some lines before running. Click inside the editor, then use **Run All** |

---

## Step 2 - Create your Git workspace (the only new workspace you create)

This gives you every course file inside Snowsight, so you never copy code again.

1. Check your **user-menu** role (bottom-left, under your name) is **ACCOUNTADMIN**. If not: click your name >
   **Switch role** > **ACCOUNTADMIN**.
2. In the file panel, find the **Workspaces | Databases** tabs. Click the small **+** to the right of them.
   (Not the grey *+ Add new* button; that one adds files.)
3. Under **Create new**, click **Git workspace**. Don't choose *Private workspace* or *Shared workspace*.
4. Fill in the dialog exactly:

   | Field | Enter |
   | --- | --- |
   | Repository URL | `https://github.com/snowflakethia/sap_ws_202611.git` |
   | Workspace name | `gnn_training` (replace the suggested `sap_ws_202611`) |
   | API integration | `GNN_KIT_GITHUB` (pick it from the list) |
   | Authentication | **Public repository** |

5. Click **Create**. After a few seconds the new workspace opens, with the course folders on the left.

**Checkpoint 2 - you should see:**
- The selector at the top of the file list says **gnn_training**.
- The folders `config`, `data`, `docs`, `labs`, `scripts`, `snowsight`, `sql` and `workspace`, plus the
  `README.md` and `SETUP.md` files.

| If you see | Do this |
| --- | --- |
| **No API integration available** | Click **Cancel**. Do Step 1 first, then switch your **user-menu** role to ACCOUNTADMIN and open the dialog again |
| `GNN_KIT_GITHUB` isn't in the list | Same as above: Step 1 hasn't run, or your user-menu role isn't ACCOUNTADMIN |
| I created a *Private* or *Shared* workspace by mistake | Harmless. Ignore it, or delete it from the workspace selector's **...** menu, then do Step 2 again with **Git workspace** |
| I can't find the small **+** | Hover just right of the *Workspaces / Databases* tabs at the top of the file panel. If the panel is collapsed, click **Workspaces** in the left navigation first |
| No **Git workspace** option | Your account uses the older Worksheets UI. Use **Catalog > Database Explorer > TRAINING_KIT_REPO > PUBLIC > Git Repositories > GNN_KIT**, find each file and choose **Copy into worksheet** |

You can delete `bootstrap.sql` from **My Workspace** now. You don't need it again.

> **Switching between workspaces:** the selector at the top of the file list switches between **My Workspace**
> and **gnn_training**. From now on, always make sure it says **gnn_training**.

---

## How to run every remaining file

For Steps 3-9, repeat these five actions:

1. Make sure the selector at the top of the file list says **gnn_training**.
2. Click the **snowsight** folder to open it, then click the file (for example `01_stage1_account.sql`).
   It opens in an editor tab.
3. At the top of the editor, click **Choose role** > **ACCOUNTADMIN**. Leave the warehouse empty; the scripts
   set their own.
4. Click the **arrow next to Run** > **Run All**. Wait until it finishes; a spinner shows while it runs.
5. In the results pane at the bottom, look at the **last result** and compare it with the checkpoint below.
   Every row in the **RESULT** column must read **PASS**. **INFO** is fine where noted.

If a checkpoint doesn't match, **run the same file again**. Every file is safe to re-run.

---

## Step 3 - Account objects: `snowsight/01_stage1_account.sql`
Creates the course role, warehouse, compute pool and project database. About 1 minute.

**Checkpoint 3**

| CHECK_NAME | ACTUAL | RESULT |
| --- | --- | --- |
| S1-A role DEMO_19865_ROLE exists | `1` | PASS |
| S1-A warehouse size/auto_suspend/owner | `SMALL/300/DEMO_19865_ROLE` | PASS |
| S1-A compute pool family/nodes | `CPU_X64_M/1-1` | PASS |
| S1-B integrations | `DEMO_19865_PIP_INSTALLATION:true`, or `none` | PASS, or **INFO** on a trial account (that's expected) |
| S1-C key grants to DEMO_19865_ROLE | `4`, or `3` on a trial account | PASS |

## Step 4 - SAP data products: `snowsight/02_stage2_sap_data.sql`
Creates the 4 SAP data product databases and loads them. About 1 minute.

**Checkpoint 4:** every row PASS.
- `S2-A 4 SAP snapshot databases, kind STANDARD` = `4/4`
- Rows: vendors `50`, materials `26`, purchase_orders `120`, billofmaterials `23`, TOTAL `219`
- `S2-C vendor columns populated` = `50/50/50/50`

## Step 5 - Demo schema: `snowsight/03_stage3_demo_schema.sql`
Creates the demo tables, views and stages. Under 1 minute.

**Checkpoint 5:** every row PASS.
- `6 tables, iceberg=0`
- views `4`
- `compiled and ran`
- stages + file format `3 + 1`
- `DEMO_SECRETS_STAGE is empty` = `0`

## Step 6 - Demo data: `snowsight/04_stage4_demo_data.sql`
Loads the trade data, contracts and precomputed GNN results. About 1 minute.

**Checkpoint 6:** every row PASS.
- Rows: BOTTLENECKS `10`, CUSTOMER_CONTRACTS `12`, REGIONS `9`, RISK_SCORES `86`, SUPPLIER_LINKS `381`,
  TRADE `150`, TOTAL `648`
- `VW_RISK_SUMMARY SUPPLIERS` = `50/2/4/0.4060`, `PARTS` = `26/0/0/0.4768`
- `VW_SUPPLIER_RISK` `50`, `VW_MATERIAL_RISK` `26`, `VW_HIDDEN_DEPENDENCIES` `26`, EMBEDDING = `ARRAY`

## Step 7 - Search and semantic view: `snowsight/05_stage5_search_semantic_view.sql`
Builds the contract search index and the semantic view. 1-6 minutes, because it waits for the index.

**Checkpoint 7:** every row PASS.
- Search service = `CONTRACT_TEXT ACTIVE/ACTIVE`
- Semantic view exists = `1`
- Search "force majeure" = `3 results, first=SC-...`
- Semantic view structure = `4 tables, 9 facts, 26 dimensions`
- Semantic view query = `50 rows: CRITICAL 2, HIGH 4, MEDIUM 44`

If the search row says **WAIT**, wait a minute and run the file again.

## Step 8 - The agent: `snowsight/06_stage6_agent.sql`
Creates the Cortex Agent. Under 1 minute.

**Checkpoint 8a:** every row PASS.
- `1:GNN_SUPPLY_RISK_AGENT`
- tools `supply_chain_risk_analyst,contract_search`
- instructions `true/true`

**Checkpoint 8b (in the UI):**
1. In the left navigation, hover over **AI** > **Agent Studio**. On the **Agents** tab, click **GNN_SUPPLY_RISK_AGENT**, then click the **Preview** tab. Ask your questions there.
2. Ask: **Which suppliers are CRITICAL risk?**
3. You should see **Albemarle Corp** and **Epsilon Tech** (both AUS, GNN risk score about 0.61).

## Step 9 - Am I ready? `snowsight/08_readiness_check.sql`
Read-only; you can run it at any time.

**Checkpoint 9:**
- The first row reads **`OVERALL | READY | PASS - you can start the labs`**.
- Then 8 PASS rows, and 1 INFO row for the workspace, which you already checked in Step 2.

If it says **NOT READY**, look at the first FAIL row and run the file named in its **FIX** column.
Then run Step 9 again.

**You're ready. Start the labs:** [snowsight/labs/LAB1_explore_data.md](snowsight/labs/LAB1_explore_data.md).

---

## When the course is over - remove everything
1. In **gnn_training**, open `snowsight/99_remove_setup.sql`, set role **ACCOUNTADMIN**, then **Run All**.
   Expected: **6 rows**, every RESULT = **REMOVED**.
2. Delete the workspace: **Workspaces** (left navigation), open the workspace selector, click **...** next to
   **gnn_training** > **Delete**.

## Quick help

| Problem | Fix |
| --- | --- |
| *No API integration available* when creating the workspace | Run Step 1, then set your **user-menu** role (bottom-left) to ACCOUNTADMIN |
| `Git repository ... does not exist` | Step 1 hasn't been run in this account |
| `Insufficient privileges` / `does not exist or not authorized` | Set the role in the editor's context bar to **ACCOUNTADMIN** |
| A row says FAIL | Run the same file again. If it still fails, re-run the previous step, then this one |
| The agent says it has no access | Switch your user-menu role to ACCOUNTADMIN and ask again |
| Anything else | Run Step 9 and show the result to your trainer |

---

## Appendix A - Other ways to copy the Step 1 code

**You only need this if the plain-text page in Step 1 won't open.** That usually means a company network or
browser policy blocks `raw.githubusercontent.com`. Use **one** of these methods, then continue with Step 1, action 5.

### A1 - GitHub file page (when the plain-text page is blocked)
1. Open **https://github.com/snowflakethia/sap_ws_202611/blob/main/snowsight/00_bootstrap.sql**
2. Above the code, on the right of the grey bar that shows the file size, click the **Copy raw file** button
   (two overlapping squares). It briefly shows a tick.
3. **Don't** use Ctrl + A on this page. That selects the whole web page (menus, line numbers), not just the code.

### A2 - Copy from this page (when GitHub file pages are blocked too)
Hover over the grey box below. A **copy** button (two overlapping squares) appears in its top-right corner;
click it. If no button appears (for example on a tablet), drag to select the whole box, then press Ctrl/Cmd + C.

```sql
-- GNN Supply Chain Risk training - Step 1: connect this account to the course on GitHub
-- (same as snowsight/00_bootstrap.sql)
USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE API INTEGRATION GNN_KIT_GITHUB
    API_PROVIDER = git_https_api
    API_ALLOWED_PREFIXES = ('https://github.com/snowflakethia/')
    ENABLED = TRUE
    COMMENT = 'GNN Supply Chain Risk training - read access to the public GitHub repo';

CREATE DATABASE IF NOT EXISTS TRAINING_KIT_REPO
    COMMENT = 'GNN Supply Chain Risk training - GitHub repo clone and file staging';

CREATE GIT REPOSITORY IF NOT EXISTS TRAINING_KIT_REPO.PUBLIC.GNN_KIT
    API_INTEGRATION = GNN_KIT_GITHUB
    ORIGIN = 'https://github.com/snowflakethia/sap_ws_202611.git'
    COMMENT = 'GNN Supply Chain Risk training kit';

ALTER GIT REPOSITORY TRAINING_KIT_REPO.PUBLIC.GNN_KIT FETCH;

CREATE STAGE IF NOT EXISTS TRAINING_KIT_REPO.PUBLIC.KIT_FILES
    COMMENT = 'Data files copied from the Git repository before loading';

-- CHECKPOINT 1: expect exactly 4 CSV files.
LIST @TRAINING_KIT_REPO.PUBLIC.GNN_KIT/branches/main/data/sap/;
```

These are the same statements as `snowsight/00_bootstrap.sql`, without the explanatory header.
