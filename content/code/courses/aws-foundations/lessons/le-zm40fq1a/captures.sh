#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of aws-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/awslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - the student types every command into one terminal, so a variable set in
#     one transcript is still there in the next; each block here runs in a
#     shell that starts from what the last one left;
#   - landing-zone.sh is written by running the ```sh fence of "by-hand" as it
#     stands, which is what pasting it does; it is removed again at the end;
#   - moto answers `controltower` with HTTP 500 after the CLI's own retries,
#     which take a few seconds.
#
# TWO COMMANDS READ THE PUBLIC PRICE LIST (AWSConfig and AWSCloudTrail), and
# download those two offers into the lab's cache the first time.
#
# NOT PRODUCED HERE, and said so in the prose: everything Control Tower does
# (moto has none of it), the trail, the log bucket, AWS Config and Identity
# Center, and every refusal the guardrail would cause in AWS.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
moto_fresh
STATE=$(mktemp)
cleanup() { rm -f "$STATE" ~/aws/landing-zone.sh; }
trap 'moto_stop; cleanup' EXIT

session() { # each argument one command at the prompt; state carries over
  local f; f=$(mktemp)
  {
    printf '. %q\n' "$STATE"
    for c in "$@"; do
      printf 'printf "%%s\\n" %q\n%s\n' "ana@laptop:~/aws\$ $c" "$c"
    done
    printf '{ declare -p $(compgen -v | grep -E "^[a-z][a-z_]*$"); declare -f; } > %q 2>/dev/null\n' "$STATE"
  } > "$f"
  bash "$f" 2>&1; rm -f "$f"
}

# ---- controls ------------------------------------------------------------------
block config-price
session 'python3 price.py AWSConfig 20260911124534 sa-east-1 SAE1-ConfigurationItemRecorded SAE1-ConfigRuleEvaluations'
block trail-price
session 'python3 price.py AWSCloudTrail 20260911124531 sa-east-1 SAE1-FreeEventsRecorded SAE1-PaidEventsRecorded SAE1-DataEventsRecorded' \
        'jq -r '"'"'.terms.OnDemand[][].priceDimensions[].description | select(test("paid event|data event recorded"))'"'"' ~/.cache/aws-prices/AWSCloudTrail-20260911124531-sa-east-1.json'

# ---- by-hand -------------------------------------------------------------------
block controltower
session 'aws controltower list-landing-zones'

sh_fences "$HERE/by-hand.md" 1 | bash || { echo "the landing-zone.sh fence failed"; exit 1; }
block run
session 'bash landing-zone.sh'

block check
session 'root=$(aws organizations list-roots --query "Roots[0].Id" --output text)' \
        'aws organizations list-organizational-units-for-parent --parent-id $root --query "OrganizationalUnits[].[Id,Name]" --output text' \
        'security=$(aws organizations list-organizational-units-for-parent --parent-id $root --query "OrganizationalUnits[?Name=='"'"'Security'"'"'].Id" --output text)' \
        'aws organizations list-accounts-for-parent --parent-id $security --query "Accounts[].[Id,Name]" --output text' \
        'aws organizations list-policies-for-target --target-id $security --filter SERVICE_CONTROL_POLICY --query "Policies[].Name" --output text' \
        'aws organizations list-delegated-administrators --query "DelegatedAdministrators[].[Id,Name]" --output text'
