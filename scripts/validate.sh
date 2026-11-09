#!/usr/bin/env bash
# =============================================================================
# Run the validation SQL for one stage, or all stages, without deploying anything.
# Usage: ./scripts/validate.sh -c <connection> --stage N|all
# =============================================================================
set -euo pipefail

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONNECTION=""; STAGE="all"
while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--connection) CONNECTION="$2"; shift 2 ;;
    --stage)         STAGE="$2"; shift 2 ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done
[[ -n "$CONNECTION" ]] || { echo "ERROR: pass -c <connection>" >&2; exit 2; }

files=(v0_prereqs v1_account v2_sap_snapshot v3_demo_schema v4_demo_data v5_ai_services v6_agent v7_workspace v8_optional v9_full_smoke_test)
if [[ "$STAGE" == "all" ]]; then
  selected=("${files[@]:1}")   # stage 0 is a pre-deploy check
else
  [[ "$STAGE" =~ ^[0-9]$ ]] || { echo "ERROR: --stage must be 0-9 or all" >&2; exit 2; }
  selected=("${files[$STAGE]}")
fi

for v in "${selected[@]}"; do
  echo "================ $v ================"
  snow sql -c "$CONNECTION" -f "$KIT_DIR/sql/validation/$v.sql"
done
