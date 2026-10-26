#!/usr/bin/env bash
# L4: prove OpenTofu state encryption end to end on the local backend (no cloud).
#   1. an unencrypted state exists
#   2. adopt encryption with an "unencrypted" fallback -> state is rewritten encrypted
#   3. enforce encryption -> a wrong passphrase, or unencrypted state, is refused
# Usage: ./demo.sh        (needs tofu >= 1.10 and jq)
set -euo pipefail

TOFU=${TOFU:-tofu}
here=$(cd "$(dirname "$0")" && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
export TF_VAR_passphrase="lab-passphrase-0123456789"
marker="this-text-must-not-appear-in-an-encrypted-state"

use_step() { cp "$here/$1/main.tf" "$work/main.tf"; "$TOFU" -chdir="$work" init -input=false -upgrade=false >/dev/null; }
fail() { echo "FAIL: $*" >&2; exit 1; }

echo "== step 1: unencrypted state"
use_step step1-unencrypted
"$TOFU" -chdir="$work" apply -auto-approve -input=false >/dev/null
grep -q "$marker" "$work/terraform.tfstate" || fail "expected the marker in plain state"
echo "plain state holds the marker, as expected"

echo "== step 2: adopt encryption with an unencrypted fallback"
use_step step2-migrate
"$TOFU" -chdir="$work" apply -auto-approve -input=false >/dev/null
if grep -q "$marker" "$work/terraform.tfstate"; then fail "marker still readable after migration"; fi
jq -e '.encrypted_data and .meta' "$work/terraform.tfstate" >/dev/null || fail "state is not an encrypted envelope"
echo "state is now an AES-GCM envelope; the marker is gone"

echo "== step 3: enforce encryption"
use_step step3-enforced
"$TOFU" -chdir="$work" plan -input=false -detailed-exitcode >/dev/null || fail "plan with the right key must succeed with no changes"
if TF_VAR_passphrase="a-different-passphrase-123" "$TOFU" -chdir="$work" plan -input=false >/dev/null 2>&1; then
  fail "a wrong passphrase must not be able to read the state"
fi
echo "right key: no changes; wrong key: refused"
"$TOFU" -chdir="$work" destroy -auto-approve -input=false >/dev/null
echo "OK"
