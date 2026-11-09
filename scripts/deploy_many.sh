#!/usr/bin/env bash
# =============================================================================
# Deploy the kit to many trainee accounts, unattended, one after another.
# connections.txt: one Snowflake CLI connection name per line (# for comments).
# Run the 3-step human validations afterwards with ./scripts/validate.sh per account,
# or spot-check a sample of accounts.
# Usage: ./scripts/deploy_many.sh connections.txt
# =============================================================================
set -uo pipefail

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIST="${1:?Usage: deploy_many.sh connections.txt}"
ok=(); failed=()

while IFS= read -r conn; do
  conn="${conn%%#*}"; conn="${conn//[[:space:]]/}"
  [[ -z "$conn" ]] && continue
  echo "################ $conn ################"
  if bash "$KIT_DIR/scripts/deploy.sh" -c "$conn" --yes; then ok+=("$conn"); else failed+=("$conn"); fi
done < "$LIST"

echo
echo "Succeeded (${#ok[@]}): ${ok[*]:-none}"
echo "Failed    (${#failed[@]}): ${failed[*]:-none}"
[[ ${#failed[@]} -eq 0 ]]
