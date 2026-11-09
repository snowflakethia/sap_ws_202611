#!/usr/bin/env bash
# =============================================================================
# Remove everything the training kit created (sql/teardown/99_teardown.sql).
# Usage: ./scripts/teardown.sh -c <connection> [--yes]
# =============================================================================
set -euo pipefail

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONNECTION=""; ASSUME_YES=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--connection) CONNECTION="$2"; shift 2 ;;
    --yes|-y)        ASSUME_YES=1; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 2 ;;
  esac
done
[[ -n "$CONNECTION" ]] || { echo "ERROR: pass -c <connection>" >&2; exit 2; }

echo "Connection '$CONNECTION' resolves to:"
snow sql -c "$CONNECTION" -q "SELECT CURRENT_ORGANIZATION_NAME() AS ORG, CURRENT_ACCOUNT_NAME() AS ACCOUNT, CURRENT_USER() AS USER_NAME"
ORG=$(snow sql -c "$CONNECTION" --format json -q "SELECT CURRENT_ORGANIZATION_NAME() AS ORG" \
      | python3 -c 'import json,sys; print(json.load(sys.stdin)[0]["ORG"])')
if [[ "$ORG" == "F9A3UBGT" ]]; then
  echo "REFUSING: this is the SOURCE account (F9A3UBGT). Teardown is for trainee accounts only." >&2
  exit 1
fi

echo
echo "This drops DEMO_19865_DB, DEMO_SHARED_WORKSPACES, the 4 S4_Z*_DP_DELTA_SHARING_V1 databases,"
echo "DEMO_19865_WH, DEMO_19865_POOL, the DEMO_19865_* integrations and the DEMO_19865_ROLE / DEMO_READER_ROLE roles."
if [[ "$ASSUME_YES" != 1 ]]; then
  read -r -p "Type the connection name to confirm: " answer
  [[ "$answer" == "$CONNECTION" ]] || { echo "Cancelled."; exit 0; }
fi

snow sql -c "$CONNECTION" -f "$KIT_DIR/sql/teardown/99_teardown.sql"
