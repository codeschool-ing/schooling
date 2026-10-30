#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of gcp-operations.
#
#   bash captures.sh     # after lab.sh tools (Terraform)
#
# genlogs.py is taken out of the lesson; jq counts its lines the way the
# lesson says a log-based counter would. The Terraform plans are local, with
# the fake token; nothing is created.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/gcp" || exit 1
from_lesson "$HERE/counters.md" genlogs.py > genlogs.py

block gen
run 'python3 genlogs.py > checkout.log'
run 'wc -l checkout.log'
block count
run "jq -r 'select(.message == \"payment retried\") | .timestamp[11:16]' checkout.log | sort | uniq -c"
run "jq -r 'select(.message == \"payment retried\") | .provider' checkout.log | sort | uniq -c"
block buckets
run "jq -r 'select(.message == \"order placed\") | .total_cents' checkout.log | sort -n | uniq -c"

export GOOGLE_OAUTH_ACCESS_TOKEN=fake
rm -rf tf/logmetrics && mkdir -p tf/logmetrics && cd tf/logmetrics || exit 1
from_lesson "$HERE/metrics.md" tf/logmetrics/main.tf > main.tf
from_lesson "$HERE/log-alerts.md" tf/logmetrics/alerts.tf > alerts.tf
quiet 'terraform init -input=false'
block plan
run 'terraform plan -input=false -no-color | grep -E "^  # |metric_kind|value_type|period|Plan:"'
