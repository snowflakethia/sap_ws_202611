# Troubleshooting

| Symptom | Stage | Cause | Fix |
| --- | --- | --- | --- |
| `S0-A` FAIL, role is not ACCOUNTADMIN | 0 | The connection's default role is different | Add `role = "ACCOUNTADMIN"` to the connection in `~/.snowflake/connections.toml`, or grant ACCOUNTADMIN to the user |
| `S0-B` FAIL, organization is F9A3UBGT | 0 | The connection points at the **source** account | Use the trainee account's connection. Never deploy into F9A3UBGT |
| `No active warehouse selected` | any | A stage ran before Stage 1 created `DEMO_19865_WH` | Run from Stage 1: `--from 1` |
| `Object 'S4_ZVENDORINFO_DP_DELTA_SHARING_V1...' does not exist` | 3 | Stage 2 didn't finish | `bash scripts/deploy.sh -c <conn> --stage 2`, then `--stage 3` |
| `invalid identifier` on `s4custom_*` | any | The quoted lowercase names were typed without quotes | Use `"s4_zvendorinfo_dp_srv:v1"."s4custom_vendors"` exactly, with the double quotes |
| COPY error `Number of columns in file does not match` | 2 / 4 | A CSV was edited or replaced | Restore it from the kit and compare its checksum with `data/manifest.csv` |
| `S4-A` counts doubled | 4 | The load was changed to remove `TRUNCATE` | Re-run `--stage 4` with the original `40_load_demo_data.sql` |
| `S5-A` shows `WAIT` / `INITIALIZING` | 5 | The search index is still building | Wait 1-2 minutes, then `bash scripts/validate.sh -c <conn> --stage 5` |
| Cortex Search fails: change tracking | 5 | `CUSTOMER_CONTRACTS` was created without change tracking | `ALTER TABLE DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.CUSTOMER_CONTRACTS SET CHANGE_TRACKING = TRUE;` then `--stage 5` |
| Cortex function / model not available | 5 / 6 | The account's region lacks the feature or the model | Enable cross-region inference: `ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';` (ACCOUNTADMIN) |
| `CREATE AGENT` syntax error | 6 | Older Snowflake release, or agents not enabled | Check that Snowsight > AI > Agent Studio exists in this account |
| Agent answers "no access" | 6 C | Snowsight session is using a role without access | Switch to `DEMO_19865_ROLE` or ACCOUNTADMIN in Snowsight |
| `WARNING: PyPI external access integration not created` / `External access is not supported for trial accounts` | 1 | Trial account | Expected; deployment continues. Only optional Lab 4 (GNN retraining) needs it. Use a paid account for Lab 4 |
| `Live version is not found` on PUT | 7 | The workspace has no editable version | `deploy.sh` runs `ALTER WORKSPACE ... ADD LIVE VERSION FROM LAST` first; run that manually, then re-run `--stage 7` |
| `Querying FACTS with DIMENSIONS ... not supported` | 5 | A hand-written `SEMANTIC_VIEW()` query mixes FACTS and DIMENSIONS | Query DIMENSIONS with METRICS, or DIMENSIONS only |
| `PUT ... snow://workspace` fails | 7 | The workspace wasn't created, or the CLI is too old | Check `SHOW WORKSPACES IN SCHEMA DEMO_SHARED_WORKSPACES.DEMO_19865_WORKSPACE;` and upgrade `snow` to the latest 3.x |
| Reader-role `DROP` succeeds in the Stage 8 C test | 8 | ACCOUNTADMIN is still active as a secondary role | Run `USE SECONDARY ROLES NONE;` after `USE ROLE DEMO_READER_ROLE`. Restore with `UNDROP TABLE ...` as ACCOUNTADMIN |
| `S7-B` shows 0 files | 7 | The upload went to `live` but COMMIT didn't run | `snow sql -c <conn> -q "ALTER WORKSPACE DEMO_SHARED_WORKSPACES.DEMO_19865_WORKSPACE.DEMO_19865 COMMIT"` |
| Compute pool creation fails | 1 | SPCS is not available in the account or region | Only Lab 4 needs the pool. Remove the pool statements from `11_warehouse_compute_pool.sql`; everything else still works |
| `Permission denied` running `./scripts/deploy.sh` | - | The script isn't marked executable | Run it as `bash scripts/deploy.sh ...` |

## Getting help

1. Run `bash scripts/validate.sh -c <conn> --stage all` and save the output.
2. Attach the latest file from `logs/`.
3. Include the stage number and the failing `CHECK_NAME` rows.
