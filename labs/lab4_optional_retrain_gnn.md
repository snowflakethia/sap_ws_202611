# Lab 4 (optional) - Retrain the GNN

> **Disclaimer:** all data in this lab is **synthetic and for demonstration only**. Company names (for example
> Albemarle Corp, BYD Battery or Queensland Minerals) are used for illustration. The vendors, purchase orders,
> trade records, contracts, risk scores and predicted links are invented and **don't describe any real
> company, relationship or risk**. Don't use them for business decisions.

**Goal:** run the notebook that produced the prediction tables, and see how the risk scores are computed.
**Time:** 45-60 minutes (package install and CPU training). **Cost:** uses compute pool `DEMO_19865_POOL`
(CPU_X64_M, 1 node), which suspends itself after 10 minutes idle.

The environment already contains precomputed results, so the agent works without this lab.

## Before you start
- **Not possible on trial accounts.** The notebook installs PyTorch Geometric from PyPI, which needs the
  external access integration `DEMO_19865_PIP_INSTALLATION`. Trial accounts can't create external access
  integrations, so Stage 1 skips it there with a warning.
- The notebook **appends** results tagged `MODEL_VERSION = 'v1.0.0'` and deletes earlier rows with the
  same version first. Change `MODEL_VERSION` in the configuration cell (for example to `v1.1.0-<yourname>`)
  so you can compare your run with the precomputed one.

## Steps
1. Snowsight > Projects > Workspaces > `DEMO_19865` > `Notebooks/gnn_supply_chain_risk.ipynb`.
2. Connect the notebook to a Container Runtime service:
   - Compute pool: `DEMO_19865_POOL`
   - Query warehouse: `DEMO_19865_WH`
   - External access integrations: `DEMO_19865_PIP_INSTALLATION`
3. Run all cells. The package cell takes several minutes.
4. Compare your results with the precomputed run:

```sql
USE ROLE DEMO_19865_ROLE;
USE WAREHOUSE DEMO_19865_WH;
SELECT MODEL_VERSION, NODE_TYPE, COUNT(*) AS NODES, ROUND(AVG(RISK_SCORE), 4) AS AVG_RISK
FROM DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.RISK_SCORES_PREDICTIONS
GROUP BY 1, 2 ORDER BY 1, 2;
```

## Expected outcome
- Rows for both `v1.0.0` (precomputed) and your new model version.
- Scores will differ slightly between runs, because GNN training starts from random weights.

## Reset to the precomputed results
`VW_RISK_SUMMARY` and the agent read *all* model versions. To restore the original numbers, delete your rows:

```sql
DELETE FROM DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.RISK_SCORES_PREDICTIONS    WHERE MODEL_VERSION <> 'v1.0.0';
DELETE FROM DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.SUPPLIER_LINKS_PREDICTIONS WHERE MODEL_VERSION <> 'v1.0.0';
```

Or reload Stage 4: `bash scripts/deploy.sh -c <connection> --stage 4`.
