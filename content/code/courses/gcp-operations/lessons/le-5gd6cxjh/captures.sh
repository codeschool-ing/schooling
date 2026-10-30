#!/usr/bin/env bash
# The terminal sessions quoted in lesson 24 of gcp-operations.
#
#   bash captures.sh     # after lab.sh tools (Terraform, functions-framework)
#
# The Terraform plan is local, with the fake token; no budget exists. The
# budget notifications are published by hand into the Pub/Sub emulator, in
# the format Google documents, as the lesson says; on Google Cloud, Billing
# publishes them. The function runs on this machine with the Functions
# Framework, and the emulator pushes to it through Docker's bridge address.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/gcp" || exit 1

block plan
export GOOGLE_OAUTH_ACCESS_TOKEN=fake
rm -rf tf/budget && mkdir -p tf/budget && cd tf/budget || exit 1
from_lesson "$HERE/budgets.md" tf/budget/main.tf > main.tf
quiet 'terraform init -input=false'
run 'terraform plan -input=false -no-color -var billing_account=000000-000000-000000 -var sandbox_folder=folders/100000000001 | grep -E "^  # |display_name|units|threshold_percent|spend_basis|Plan:"'
unset GOOGLE_OAUTH_ACCESS_TOKEN
cd "$HOME/gcp" || exit 1

block wire
emulators_up
student_env
rm -rf budget && mkdir budget
from_lesson "$HERE/wire.md" budget/main.py > budget/main.py
cd budget || exit 1
quiet 'pkill -f "[f]unctions-framework --target"'
START='functions-framework --target on_budget --port 8080 > ff.log 2>&1 &'
grep -qxF "$START" "$HERE/wire.md" || { echo "wire.md no longer starts the function this way"; exit 1; }
eval "$START"
FF=$!
for _ in $(seq 40); do curl -s -o /dev/null localhost:8080 && break; sleep 0.5; done
run 'docker network inspect bridge --format "{{(index .IPAM.Config 0).Gateway}}"'
run 'gcloud pubsub topics create budget-alerts ops-actions'
run 'gcloud pubsub subscriptions create budget-act --topic budget-alerts --push-endpoint http://172.17.0.1:8080/'
run 'gcloud pubsub subscriptions create ops-read --topic ops-actions'

block publish
pub() { run "gcloud pubsub topics publish budget-alerts --attribute budgetId=$1,billingAccountId=000000-000000-000000,schemaVersion=1.0 --message '{\"costAmount\": $2, \"budgetAmount\": $3, \"currencyCode\": \"USD\"}' > /dev/null"; sleep 2; }
pub b-shop 385.12 700
pub b-shop 566.40 700
pub b-shop 571.93 700
pub b-sandbox 40.85 40
pub b-shop 703.18 700
run 'cat ff.log'
run 'gcloud pubsub subscriptions pull ops-read --auto-ack --limit 10 --format "table(message.attributes.budget, message.attributes.action)"'
run 'cat seen.json'
kill $FF
emulators_down
