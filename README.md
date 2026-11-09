# GNN Supply Chain Risk - Training Kit

> ## Trainees: start here -> [snowsight/README.md](snowsight/README.md)
> Everything is done in Snowsight; there's nothing to install.

This kit recreates the GNN Supply Chain Risk demo (SAP data products, GNN risk scores, Cortex Search,
a semantic view and a Cortex Agent) in any new Snowflake account. Each trainee gets their own account
and has ACCOUNTADMIN.

## Two ways to set up

| Path | For | Start with |
| --- | --- | --- |
| **Snowsight** | Trainees (browser only) | [snowsight/README.md](snowsight/README.md) |
| **Snowflake CLI** | Trainers preparing many accounts | [docs/SETUP_GUIDE.md](docs/SETUP_GUIDE.md): `bash scripts/deploy.sh -c <connection>` |

Both paths run the same scripts in `sql/` and are checked by the same validation scripts.

## Contents

| Folder | Contents |
| --- | --- |
| `snowsight/` | Trainee guide, numbered setup files to run in Snowsight, readiness check, removal script, labs |
| `sql/stageN_*` | Deployment SQL shared by both paths, numbered in run order |
| `sql/validation/` | Read-only checks, one file per stage (`v0`-`v9`) |
| `data/` | CSV snapshots (SAP 219 rows, demo 648 rows) and `manifest.csv` |
| `workspace/` | Notebooks and reference SQL (sanitized) |
| `labs/` | Lab guides for the CLI path, plus the lab 3 SQL solution |
| `scripts/` | CLI path: `deploy.sh`, `validate.sh`, `teardown.sh`, `deploy_many.sh` |
| `docs/` | Trainer setup guide, troubleshooting, source inventory |
| `config/` | CLI defaults template |
