#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of gcp-operations.
#
#   bash captures.sh     # after lab.sh tools (Terraform)
#
# logdemo.py is taken out of the lesson. The jq commands ask, of its lines, the
# questions the lesson says Cloud Logging would answer; they are not Cloud
# Logging and the lesson says so. The Terraform plan is local, with the fake
# token; nothing is created.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/gcp" || exit 1
from_lesson "$HERE/structured.md" logdemo.py > logdemo.py

block run
run 'python3 logdemo.py'
block as-entries
run "python3 logdemo.py | jq -c -R 'fromjson? // {textPayload: .}' | jq -c '{severity: (.severity // \"DEFAULT\"), message: (.message // .textPayload)}'"
block filter
run "python3 logdemo.py | jq -c -R 'fromjson?' | jq -c 'select(.severity == \"WARNING\" or .severity == \"ERROR\") | {severity, message, order_id}'"
run "python3 logdemo.py | jq -c -R 'fromjson?' | jq -r 'select(.httpRequest.status >= 200) | .\"logging.googleapis.com/trace\"'"

export GOOGLE_OAUTH_ACCESS_TOKEN=fake
rm -rf tf/logging && mkdir -p tf/logging && cd tf/logging || exit 1
from_lesson "$HERE/routing.md" tf/logging/main.tf > main.tf
quiet 'terraform init -input=false'
block plan
run 'terraform plan -input=false -no-color | grep -E "^  # |retention_days|writer_identity|Plan:"'
