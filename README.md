# GNN Supply Chain Risk - Training Kit

This kit recreates the GNN Supply Chain Risk demo from Snowflake account **F9A3UBGT-DEFAULT** in any
new Snowflake account. It is intended for training: each trainee gets their own account and has ACCOUNTADMIN.

```bash
bash scripts/deploy.sh -c <trainee-connection>
```

The deployment runs in 9 stages. It pauses after each one for a 3-step human validation.

- **Setup guide:** [docs/SETUP_GUIDE.md](docs/SETUP_GUIDE.md), with prerequisites, stages, checks and expected outcomes
- **Troubleshooting:** [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
- **What was copied and what changed:** [docs/SOURCE_INVENTORY.md](docs/SOURCE_INVENTORY.md)
- **Labs:** [labs/](labs/)

| Folder | Contents |
| --- | --- |
| `scripts/` | `deploy.sh`, `validate.sh`, `teardown.sh`, `deploy_many.sh` |
| `sql/stageN_*` | Deployment SQL, numbered in run order |
| `sql/validation/` | Read-only checks, one file per stage (`v0`-`v9`) |
| `data/` | CSV snapshots (SAP 219 rows, demo 648 rows) and `manifest.csv` |
| `workspace/` | Files uploaded into the shared workspace (sanitized) |
| `labs/` | Trainee exercises |
| `config/` | Template only; the real `config.env` is git-ignored |
