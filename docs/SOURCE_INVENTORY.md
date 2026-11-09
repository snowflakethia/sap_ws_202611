# Source Inventory - what was taken from F9A3UBGT

Extracted on 2026-11-08 from the source demo account (organization `F9A3UBGT`), read-only, using a
read-only demo role (`DEMO_READER_ROLE`). The extraction tooling is kept by the kit maintainer and
is not part of this repository.

## Included

| Source object | Kit file | Change from source |
| --- | --- | --- |
| Role `DEMO_19865_ROLE` | `sql/stage1_account/10_roles.sql` | None |
| Warehouse `DEMO_19865_WH` (Small) | `11_warehouse_compute_pool.sql` | None |
| Compute pool `DEMO_19865_POOL` (CPU_X64_M) | `11_warehouse_compute_pool.sql` | Created `INITIALLY_SUSPENDED` |
| Network rule `PIP_INSTALLATION` + EAI `DEMO_19865_PIP_INSTALLATION` | `12_network_rule_pypi.sql`, `12b_eai_pypi.sql` | Plain DDL instead of `EXECUTE IMMEDIATE`. The integration is **best effort**, because trial accounts reject external access |
| 4 SAP catalog-linked databases `S4_Z*_DP_DELTA_SHARING_V1` (Iceberg tables over SAP BDC) | `stage2_sap_snapshot/*` + `data/sap/*.csv` | **Snapshot** as standard tables, with the same names |
| `TRADE_DATA_EXTERNAL`, `REGIONS_EXTERNAL`, `CUSTOMER_CONTRACTS`, `RISK_SCORES_PREDICTIONS`, `BOTTLENECKS_PREDICTIONS` | `stage3_demo_schema/32_tables.sql` | `CUSTOMER_CONTRACTS` gets `CHANGE_TRACKING = TRUE` (for the search service) |
| `SUPPLIER_LINKS_PREDICTIONS` | `32_tables.sql` | **Standard** table; the source is Snowflake-managed Iceberg v3. Same columns and types |
| 4 views `VW_*` | `33_views.sql` | Demo table names fully qualified; logic unchanged |
| Stages `DATA_STAGE`, `MODELS_STAGE`, `DEMO_SECRETS_STAGE`; `CSV_FORMAT` | `31_stages_file_format.sql` | `DEMO_SECRETS_STAGE` ships **empty** |
| `CONTRACT_SEARCH_SERVICE` | `stage5_ai_services/50_cortex_search.sql` | None |
| `SUPPLY_CHAIN_RISK_SEMANTIC_VIEW` (9 facts, 26 dimensions, 2 verified queries) | `51_semantic_view.sql` | Name fully qualified; body verbatim |
| `GNN_SUPPLY_RISK_AGENT` | `stage6_agent/60_agent.sql` | Only the default version (`VERSION$2`) |
| Workspace `DEMO_SHARED_WORKSPACES.DEMO_19865_WORKSPACE.DEMO_19865` (7 of 8 files) | `stage7_workspace/*` + `workspace/**` | `Copy_to_Hana.ipynb` excluded; others sanitized (see below) |
| Role `DEMO_READER_ROLE` | `stage8_optional/80_reader_role.sql` | **Optional** |

## Data (checksums in `data/manifest.csv`)

| Table | Rows |
| --- | --- |
| `s4custom_vendors` / `s4custom_materials` / `s4custom_purchase_orders` / `s4custom_billofmaterials` | 50 / 26 / 120 / 23 (**219**) |
| `REGIONS_EXTERNAL` / `TRADE_DATA_EXTERNAL` / `CUSTOMER_CONTRACTS` | 9 / 150 / 12 |
| `RISK_SCORES_PREDICTIONS` / `SUPPLIER_LINKS_PREDICTIONS` / `BOTTLENECKS_PREDICTIONS` | 86 / 381 / 10 |
| Demo total | **648** |

Source view results used as expected values in the checks:
- `VW_SUPPLIER_RISK` 50 rows, `VW_MATERIAL_RISK` 26, `VW_HIDDEN_DEPENDENCIES` 26, `VW_RISK_SUMMARY` 2.
- Supplier risk categories: CRITICAL 2, HIGH 4, MEDIUM 44.

## Workspace file changes

| File | Change | Why |
| --- | --- | --- |
| `Notebooks/publish_to_BDC.ipynb` | OPTIONAL banner added; outputs cleared | Needs an SAP BDC zero-copy connector |
| `Notebooks/gnn_supply_chain_risk.ipynb` | SAP references changed from `"S4_Z*_DP"` to `"S4_Z*_DP_DELTA_SHARING_V1"`; outputs cleared | The `S4_Z*_DP` databases don't exist in F9A3UBGT, so the notebook could not run there as-is |
| `SQL/01_account_setup.sql` | HANA host replaced with `<HANA_HOST>` | Kept as a reference copy; the kit uses `sql/` instead |

## Deliberately excluded

| Source object | Reason |
| --- | --- |
| `GNN_SUPPLY_RISK_AGENT_AC370910U01`, `_AC376429U01`, `_AC386075U01`, `_PA378263U01`, `_TAC008656U01` | Agents built by trainees in earlier sessions (owned by `DEMO_READER_ROLE`, created 30 Jul - 28 Oct 2026). Replaced by Lab 3 |
| `SUPPLIER_LINKS_PREDICTIONS_ORG` (381 rows) | Duplicate of `SUPPLIER_LINKS_PREDICTIONS` from before the Iceberg conversion |
| `EVAL_DATASET_GNN_SUPPLY_RISK_AGENT_20260727_161218` (30 rows) | Output of an old agent evaluation run |
| `Notebooks/Copy_to_Hana.ipynb` | Not used by the demo: it copies 5 tables to an external SAP HANA Cloud instance, and none of those tables is in the kit (`SUPPLY_CHAIN_NODES`, `SUPPLY_CHAIN_NODES_ENRICHED`, `SUPPLY_CHAIN_EDGES`, `ALL_NODES`, `ALL_EDGES`; not visible to `DEMO_READER_ROLE`). The source copy also contains a **hard-coded HANA Cloud password**, which should be rotated and removed in F9A3UBGT |
| Network rule `HANA_CLOUD_ACCESS` + EAI `DEMO_19865_HANA_CLOUD_ACCESS` | Used only by `Copy_to_Hana.ipynb` |
| `DEMO_SECRETS_STAGE/env.txt` | Secret, read only by `Copy_to_Hana.ipynb`; never copied. The stage itself is recreated empty |
| `DATA_STAGE/data_stage/*.csv` (3 files) | Older copies of the prediction tables; the kit exports from the tables instead |
| The source user's personal database, `SNOWFLAKE` | Personal and system databases |
| Agent `VERSION$1` | Superseded by `VERSION$2` |

## Not visible to `DEMO_READER_ROLE` (may exist in F9A3UBGT)

The extract used a read-only role, so objects that role cannot see are not in the kit. Re-run the
extract with an owner role if you need them.

## Regenerated files

`sql/stage5_ai_services/51_semantic_view.sql` and `sql/stage6_agent/60_agent.sql` were generated from the
source semantic view DDL and agent specification. If the source demo changes, the maintainer re-extracts
them; don't edit them by hand.
