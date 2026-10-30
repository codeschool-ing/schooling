#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of gcp-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/gcplab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# Runs in the lab lesson 1 built (../../from-lessons.sh says how), against an
# empty emulator. budget.tf is read out of the ```hcl fence of "budgets" into
# a fresh ~/gcp/budget; on_budget.py out of the example in "alerts-that-act".
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson: THE BUDGET
# NOTIFICATIONS ARE WRITTEN BY THIS SCRIPT, in the format Google's billing
# documentation gives, and published with gcloud in Google's place; the prose
# says so. Their numbers are an invented month.
#
# NOTHING HERE REACHES GOOGLE.
#
# NOT PRODUCED HERE, and said so in the prose: a budget, Google publishing to
# the topic, and the unlink the last message asks for.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
pubsub_fresh

tf_dir budget
tf_file "$HERE/budgets.md" 1 budget.tf
block plan
run 'terraform plan -input=false -no-color -out=plan.bin | grep "^Plan:"'
run "terraform show -json plan.bin | jq -c '.resource_changes[0].change.after.threshold_rules[]'"

cd ~/gcp && at '~/gcp'
example "$HERE/alerts-that-act.md" on_budget.py > ~/gcp/on_budget.py || exit 1
ATTR='--attribute=billingAccountId=012345-6789AB-CDEF01,budgetId=planner-monthly,schemaVersion=1.0'
msg() { # SPENT [THRESHOLD]
  printf '{"budgetDisplayName": "planner monthly", %s"costAmount": %s, "costIntervalStart": "2026-11-01T07:00:00Z", "budgetAmount": 300.0, "budgetAmountType": "SPECIFIED_AMOUNT", "currencyCode": "USD"}' \
    "${2:+\"alertThresholdExceeded\": $2, }" "$1"
}
block topic
run 'gcloud pubsub topics create budget-alerts'
run 'gcloud pubsub subscriptions create budget-alerts-sub --topic=budget-alerts'
block publish
run "gcloud pubsub topics publish budget-alerts $ATTR --message='$(msg 84.17)'"
block act
run 'python3 on_budget.py'
run "gcloud pubsub topics publish budget-alerts $ATTR --message='$(msg 273.40 0.9)'"
run 'python3 on_budget.py'
run "gcloud pubsub topics publish budget-alerts $ATTR --message='$(msg 318.92 1.0)'"
run 'python3 on_budget.py'
