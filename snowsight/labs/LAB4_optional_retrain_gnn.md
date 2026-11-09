# Lab 4 (optional) - Retrain the GNN

**Goal:** run the notebook that produced the risk-score tables, and see how a graph neural network scores suppliers.
**Time:** 45-60 minutes. **Before you start:** run `snowsight/08_readiness_check.sql`; it must say READY.

> **Not possible on trial accounts.** The notebook installs PyTorch Geometric from the internet (PyPI). That needs
> the external access integration `DEMO_19865_PIP_INSTALLATION`, which trial accounts can't create (Stage 1
> showed INFO). If you're on a trial account, read through the notebook instead of running it.

The environment already contains the precomputed results, so the agent works whether or not you do this lab.

## Steps
1. In `gnn_training`, open `workspace/Notebooks/gnn_supply_chain_risk.ipynb`.
2. Connect the notebook (top-right **Connect** button), then fill in:
   - Runtime: Container Runtime (CPU)
   - Compute pool: `DEMO_19865_POOL`
   - Query warehouse: `DEMO_19865_WH`
   - External access integrations: `DEMO_19865_PIP_INSTALLATION`
3. In the configuration cell, change `MODEL_VERSION = "v1.0.0"` to `MODEL_VERSION = "v1.1.0"`, so your results
   don't replace the precomputed ones.
4. Select **Run all**. The package installation cell takes several minutes.
5. Compare your run with the precomputed one. Create a new SQL file in the workspace and run:

```sql
USE ROLE DEMO_19865_ROLE;
USE WAREHOUSE DEMO_19865_WH;
SELECT MODEL_VERSION, NODE_TYPE, COUNT(*) AS NODES, ROUND(AVG(RISK_SCORE), 4) AS AVG_RISK
FROM DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.RISK_SCORES_PREDICTIONS
GROUP BY 1, 2 ORDER BY 1, 2;
```

## Expected result
- Rows for both `v1.0.0` (precomputed) and `v1.1.0` (yours).
- Your scores differ slightly from `v1.0.0`, because training starts from random weights.

## Reset to the precomputed results
The views and the agent read every model version. Delete your rows afterwards:

```sql
DELETE FROM DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.RISK_SCORES_PREDICTIONS    WHERE MODEL_VERSION <> 'v1.0.0';
DELETE FROM DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.SUPPLIER_LINKS_PREDICTIONS WHERE MODEL_VERSION <> 'v1.0.0';
```

Or re-run `snowsight/04_stage4_demo_data.sql`. Then run `snowsight/08_readiness_check.sql`; it should say READY.
