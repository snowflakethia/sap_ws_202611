#!/usr/bin/env bash
# =============================================================================
# GNN Supply Chain Risk - training environment deployer (Snowflake CLI)
# =============================================================================
# Recreates the F9A3UBGT demo in a trainee account, one stage at a time.
# After each stage it runs the stage's validation SQL and PAUSES so a person can
# complete the 3-step check in docs/SETUP_GUIDE.md before continuing.
#
# Usage:
#   ./scripts/deploy.sh -c <connection> [--stage N|all] [--from N] [--yes]
#                       [--with-reader-role]
# Examples:
#   ./scripts/deploy.sh -c trainee01                 # all stages, pause after each
#   ./scripts/deploy.sh -c trainee01 --stage 4       # one stage only
#   ./scripts/deploy.sh -c trainee01 --from 5        # resume from stage 5
#   ./scripts/deploy.sh -c trainee01 --yes           # unattended (no pauses)
# =============================================================================
set -euo pipefail

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SQL_DIR="$KIT_DIR/sql"
WS_FQN="DEMO_SHARED_WORKSPACES.DEMO_19865_WORKSPACE.DEMO_19865"
DATA_STAGE="@DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK.DATA_STAGE/training_kit"

# Defaults, optionally overridden by config/config.env, then by flags.
CONNECTION=""; STAGE="all"; FROM=0; ASSUME_YES=0
WITH_READER_ROLE=0
[[ -f "$KIT_DIR/config/config.env" ]] && source "$KIT_DIR/config/config.env"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--connection)    CONNECTION="$2"; shift 2 ;;
    --stage)            STAGE="$2"; shift 2 ;;
    --from)             FROM="$2"; shift 2 ;;
    --yes|-y)           ASSUME_YES=1; shift ;;
    --with-reader-role) WITH_READER_ROLE=1; shift ;;
    -h|--help)          sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done

[[ -n "$CONNECTION" ]] || { echo "ERROR: pass -c <connection> (see 'snow connection list')" >&2; exit 2; }
command -v snow >/dev/null || { echo "ERROR: Snowflake CLI 'snow' not found on PATH" >&2; exit 2; }

mkdir -p "$KIT_DIR/logs"
LOG="$KIT_DIR/logs/deploy_${CONNECTION}_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG") 2>&1
echo "Log: $LOG"

run_sql_file() {  # $1 = path relative to sql/
  echo ">> snow sql -f sql/$1"
  snow sql -c "$CONNECTION" -f "$SQL_DIR/$1"
}

run_sql() {  # $1 = inline SQL
  snow sql -c "$CONNECTION" -q "$1"
}

put_files() {  # $1 = local glob, $2 = stage location
  local f
  for f in $1; do
    [[ -f "$f" ]] || { echo "ERROR: missing $f" >&2; exit 1; }
    echo ">> PUT $(basename "$f") -> $2"
    run_sql "USE ROLE ACCOUNTADMIN; PUT 'file://$f' '$2/' AUTO_COMPRESS = FALSE OVERWRITE = TRUE;" >/dev/null
  done
}

checkpoint() {  # $1 = stage number, $2 = validation file (or empty)
  echo
  echo "================ Stage $1 validation ================"
  [[ -n "$2" ]] && run_sql_file "validation/$2"
  echo
  echo "Complete the 3-step human validation for Stage $1 in docs/SETUP_GUIDE.md."
  echo "Every automated row above must read PASS (or INFO where noted)."
  if [[ "$ASSUME_YES" == 1 ]]; then return; fi
  read -r -p "Checks A, B and C match the expected outcome? Proceed [y/N] " answer
  [[ "$answer" =~ ^[Yy]$ ]] || { echo "Stopped after Stage $1. Resume with: --from $(( $1 + 1 ))"; exit 0; }
}

stage0() { run_sql_file stage0_prereqs/00_prereqs_check.sql; checkpoint 0 v0_prereqs.sql; }

stage1() {
  for f in 10_roles 11_warehouse_compute_pool 12_network_rule_pypi; do
    run_sql_file "stage1_account/$f.sql"
  done
  # Best effort: trial accounts reject external access integrations (only Lab 4 needs it).
  if ! run_sql_file stage1_account/12b_eai_pypi.sql; then
    echo "WARNING: PyPI external access integration not created (trial account?). Only optional Lab 4 needs it."
  fi
  run_sql_file stage1_account/13_cortex_grants.sql
  checkpoint 1 v1_account.sql
}

stage2() {
  run_sql_file stage2_sap_snapshot/20_sap_databases_schemas.sql
  run_sql_file stage2_sap_snapshot/21_sap_tables.sql
  put_files "$KIT_DIR/data/sap/*.csv" "@~/training_kit/sap"
  run_sql_file stage2_sap_snapshot/22_sap_load.sql
  checkpoint 2 v2_sap_snapshot.sql
}

stage3() {
  for f in 30_database_schema 31_stages_file_format 32_tables 33_views; do
    run_sql_file "stage3_demo_schema/$f.sql"
  done
  checkpoint 3 v3_demo_schema.sql
}

stage4() {
  put_files "$KIT_DIR/data/demo/*.csv" "$DATA_STAGE"
  run_sql_file stage4_demo_data/40_load_demo_data.sql
  checkpoint 4 v4_demo_data.sql
}

stage5() {
  run_sql_file stage5_ai_services/50_cortex_search.sql
  run_sql_file stage5_ai_services/51_semantic_view.sql
  echo "Waiting for the search index to build (up to ~5 minutes)..."
  local i state=""
  for i in $(seq 1 30); do
    state=$(snow sql -c "$CONNECTION" --format json -q \
      "SHOW CORTEX SEARCH SERVICES LIKE 'CONTRACT_SEARCH_SERVICE' IN SCHEMA DEMO_19865_DB.GNN_SUPPLY_CHAIN_RISK" \
      | python3 -c 'import json,sys; r=json.load(sys.stdin); print(r[0]["indexing_state"] if r else "MISSING")' || true)
    [[ "$state" == "ACTIVE" ]] && break
    sleep 10
  done
  echo "Search indexing state: ${state:-unknown}"
  checkpoint 5 v5_ai_services.sql
}

stage6() { run_sql_file stage6_agent/60_agent.sql; checkpoint 6 v6_agent.sql; }

stage7() {
  run_sql_file stage7_workspace/70_workspace_db_schema.sql
  run_sql_file stage7_workspace/71_workspace_create_grants.sql
  # A new (or just-committed) workspace has no editable live version; create one for the uploads.
  # Fails harmlessly if a live version already exists.
  run_sql "USE ROLE ACCOUNTADMIN; ALTER WORKSPACE $WS_FQN ADD LIVE VERSION FROM LAST;" >/dev/null 2>&1 \
    || echo "(live version already exists)"
  local d
  for d in SQL Notebooks Data; do
    put_files "$KIT_DIR/workspace/$d/*" "snow://workspace/$WS_FQN/versions/live/$d"
  done
  echo ">> ALTER WORKSPACE $WS_FQN COMMIT (publish uploaded files)"
  run_sql "USE ROLE ACCOUNTADMIN; ALTER WORKSPACE $WS_FQN COMMIT;"
  checkpoint 7 v7_workspace.sql
}

stage8() {
  [[ "$WITH_READER_ROLE" == 1 ]] && run_sql_file stage8_optional/80_reader_role.sql
  run_sql_file validation/v8_optional.sql
  checkpoint 8 v9_full_smoke_test.sql
}

if [[ "$STAGE" == "all" ]]; then
  for n in 0 1 2 3 4 5 6 7 8; do
    (( n < FROM )) && continue
    "stage$n"
  done
  echo; echo "Deployment complete. See docs/SETUP_GUIDE.md section 6 for the labs."
else
  [[ "$STAGE" =~ ^[0-8]$ ]] || { echo "ERROR: --stage must be 0-8 or all" >&2; exit 2; }
  "stage$STAGE"
fi
