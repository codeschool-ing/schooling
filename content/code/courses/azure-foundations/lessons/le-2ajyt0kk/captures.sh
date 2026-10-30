#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of azure-foundations, as a script
# that produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/azlab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# The files the student saves are read out of the lesson: budget.bicep from the
# ```bicep fence of "budgets", main.tf from the ```hcl fence of "two-checkers".
# The two `sed` lines that make broken copies are typed in the transcript.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - ~/azure/cost is removed before the run, and Microsoft's provider is put
#     into Terraform's plugin cache first, by an init nobody sees in a scratch
#     directory, because that is where lesson 2 left it for a student.
#
# NOTHING HERE REACHES AZURE. `terraform init` reads the provider from the
# cache and asks HashiCorp's registry which versions exist.
#
# NOT PRODUCED HERE, and said so in the prose: deploying the budget, any alert
# being sent, action groups, and everything in "cost-analysis", which reads a
# real billing account.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
rm -rf ~/azure/cost
WARM=$(mktemp -d)
put hcl "$HERE/two-checkers.md" 1 "$WARM/main.tf"
(cd "$WARM" && terraform init -input=false > /dev/null 2>&1) || { echo "could not warm the cache"; exit 1; }
rm -rf "$WARM"

# ---- budgets ------------------------------------------------------------------
. <(sh_fences "$HERE/budgets.md" 1)
at '~/azure/cost'
put bicep "$HERE/budgets.md" 1 budget.bicep
block budget
run 'az bicep build --file budget.bicep --stdout | jq -c '"'"'."$schema", (.resources[0] | {type, apiVersion, alerts: [.properties.notifications | to_entries[] | {(.key): "\(.value.thresholdType) > \(.value.threshold)%"}]})'"'"''

# ---- two-checkers ---------------------------------------------------------------
block bicep-typos
run "sed \"s/'Forecasted'/'Forecast'/\" budget.bicep > typo.bicep"
run 'az bicep build --file typo.bicep --stdout > /dev/null'
run "sed \"s/amount: 50/amount: '50'/\" budget.bicep > text.bicep"
run 'az bicep build --file text.bicep --stdout > /dev/null'

. <(sh_fences "$HERE/two-checkers.md" 1)
at '~/azure/cost/tf'
put hcl "$HERE/two-checkers.md" 1 main.tf
block tf
run 'terraform init -input=false'
run 'terraform validate'
run "sed -i 's/\"Forecasted\"/\"Forecast\"/' main.tf"
run 'terraform validate'
run "sed -i 's/\"Forecast\"/\"Forecasted\"/' main.tf"
run 'terraform validate'
