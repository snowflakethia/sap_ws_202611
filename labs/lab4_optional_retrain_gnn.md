# Lab 4 (optional) - Retrain the GNN: where do the risk scores come from?

> [!CAUTION]
> **Disclaimer:** all data in this lab is **synthetic and for demonstration only**. Company names (for example
> Albemarle Corp, BYD Battery or Queensland Minerals) are used for illustration. The vendors, purchase orders,
> trade records, contracts, risk scores and predicted links are invented and **don't describe any real
> company, relationship or risk**. Don't use them for business decisions.

> [!TIP]
> **Key takeaway: the risk scores aren't magic; they come from a GNN you can retrain on governed Snowflake data, without exporting it.**
> - The notebook trains PyTorch Geometric on **Snowpark Container Services**, next to the SAP and external data.
> - Results are versioned by **`MODEL_VERSION`**, so a new model can be compared with the current one before anyone relies on it.
> - GNN training starts from random weights, so **scores shift slightly between runs**. That's why model versions matter.

> **Every number the agent gave you came from a model that learned the shape of your supply network.** Not a
> spreadsheet, not a rule. A **graph neural network** looked at suppliers, parts, regions and shipments as one
> connected graph, and learned which links *should* exist but aren't recorded. In this lab you run that model
> yourself, inside Snowflake, and produce your own version of the scores.

**Time:** 45-60 minutes. **Before you start:** `snowsight/08_readiness_check.sql` must say READY.

> **Not possible on trial accounts.** The notebook installs PyTorch Geometric from the internet (PyPI). That needs
> the external access integration `DEMO_19865_PIP_INSTALLATION`, which trial accounts can't create (Stage 1 showed
> INFO). On a trial account, **read** the notebook instead. The section guide below explains each part.

The precomputed results are already loaded, so Labs 1-3 work whether or not you do this lab.

**What you'll learn**
- How a supply chain becomes a **heterogeneous graph**: different node types (suppliers, parts, external
  suppliers) and edge types (supplies, contains, ships to).
- What **GraphSAGE** does: each node learns from its neighbours' features (*message passing*).
- How **link prediction** finds hidden suppliers, and how the results are written back to Snowflake tables.
- How to run Python ML on **Snowpark Container Services** (a compute pool) next to your data.

---

## The notebook, section by section

| Section | What happens | Why it matters |
| --- | --- | --- |
| 1. Environment setup | Installs `torch`, `torch-geometric`, `torch-scatter`, `torch-sparse` | Needs internet access, hence the external access integration |
| 2. Load data | Reads the 4 SAP data products plus `TRADE_DATA_EXTERNAL` and `REGIONS_EXTERNAL` into pandas | The same tables you queried in Lab 1. The model trains on governed Snowflake data, without exporting it |
| 3. Build heterogeneous graph | Turns vendors, materials and external suppliers into **nodes**, and POs, BOM lines and shipments into **edges** | Graph structure is what lets the model see beyond Tier 1 |
| 4. Define GNN model | A **GraphSAGE** model, applied per edge type | Each node's embedding is built from its neighbours, so risk spreads through connections |
| 5. Model training | Self-supervised **link prediction**: hide some known edges and learn to predict them | Needs no labelled "risky" data, which most companies don't have |
| 6. Compute risk scores | Turns node embeddings into a 0-1 risk score and a category (LOW / MEDIUM / HIGH / CRITICAL) | Produces `RISK_SCORES_PREDICTIONS` |
| 7. Hidden dependencies and bottlenecks | Scores unrecorded external-supplier-to-vendor links, and finds companies many suppliers depend on | Produces `SUPPLIER_LINKS_PREDICTIONS` and `BOTTLENECKS_PREDICTIONS` |
| 8. Write results | Risk scores and links: deletes earlier rows **for the same `MODEL_VERSION`**, then appends. Bottlenecks: deletes **all** existing rows, then writes new ones | Explains why you set a new version in step 3, and why you reset afterwards |
| 9. Summary | Queries the output tables | A quick check that the write worked |

---

## Steps

1. **Open the notebook.** In **gnn_training**, open `workspace/Notebooks/gnn_supply_chain_risk.ipynb`.

2. **Connect it to compute.** Click **Connect** (top of the notebook) and set:

   | Setting | Value | Why |
   | --- | --- | --- |
   | Runtime | Container Runtime (CPU) | Runs Python in a container next to your data |
   | Compute pool | `DEMO_19865_POOL` | The CPU node created in Stage 1. It auto-suspends after 10 minutes idle |
   | Query warehouse | `DEMO_19865_WH` | Runs the SQL inside the notebook (reading and writing tables) |
   | External access integrations | `DEMO_19865_PIP_INSTALLATION` | Allows the package downloads in section 1 |

3. **Give your run its own version.** In the configuration cell (section 1), change `MODEL_VERSION = "v1.0.0"` to
   `MODEL_VERSION = "v1.1.0"`.
   *Why:* section 8 replaces rows with the **same** version. A new version keeps the precomputed `v1.0.0`
   results, so you can compare the two.

4. **Run it.** Click **Run all**. The package installation in section 1 takes several minutes; the rest is faster.

5. **Compare your run with the precomputed one.** Create a new SQL file in `gnn_training` and run:

```sql
USE ROLE DEMO_19865_ROLE;
USE WAREHOUSE DEMO_19865_WH;

SELECT MODEL_VERSION, NODE_TYPE, COUNT(*) AS NODES, ROUND(AVG(RISK_SCORE), 4) AS AVG_RISK
FROM DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.RISK_SCORES_PREDICTIONS
GROUP BY MODEL_VERSION, NODE_TYPE
ORDER BY MODEL_VERSION, NODE_TYPE;
```

**What it does:** counts the scored nodes and averages their risk score, per model version and node type
(SUPPLIER, PART, EXTERNAL_SUPPLIER).
**Why:** it's a quick way to see whether your model behaves like the original. You should get the same node counts
and averages that are similar but not identical.

---

## Expected result
- Rows for **`v1.0.0`** (precomputed) and **`v1.1.0`** (yours), with the same node types.
- Your averages differ slightly from `v1.0.0`, because training starts from **random weights**. Two runs of the
  same model on the same data won't give identical scores.

## Reset to the precomputed results (do this before you finish)
Your run changed what the views and the agent see:
- `RISK_SCORES_PREDICTIONS` and `SUPPLIER_LINKS_PREDICTIONS` now hold **both** versions, and the views read all rows.
- `BOTTLENECKS_PREDICTIONS` was **replaced**: section 8 deletes all existing bottlenecks before writing new ones.

To put back the original data used in Labs 1-3, open `snowsight/04_stage4_demo_data.sql` in **gnn_training** and
click **Run All**.

**What it does:** empties the 6 demo tables (`TRUNCATE`), then reloads them from the original CSV files in the
course repository (`COPY INTO`).
**Why:** it's the safest reset. One file, the same checkpoint as the setup, and it restores the bottlenecks
table that a version filter couldn't.
**Expected:** every row PASS, TOTAL **648**. Then run `snowsight/08_readiness_check.sql`; it should say **READY**.

## Discuss
1. The model is trained without any "this supplier is risky" labels. What does it actually learn, and why is that
   still useful for risk?
2. Your scores changed slightly between runs. How would you make a production model's output stable enough for
   business users?
3. The notebook ran next to the data instead of exporting it to a laptop. What does that mean for governance and
   for SAP data in particular?

**Next (optional):** [Lab 5 - Build a dashboard with one prompt](lab5_dashboard_with_coco.md). Turn everything you have seen into an app for the business.
