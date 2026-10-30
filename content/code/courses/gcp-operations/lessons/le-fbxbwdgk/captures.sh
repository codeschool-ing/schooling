#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of gcp-operations.
#
#   bash captures.sh     # after lab.sh tools (Terraform)
#
# pages.py is taken out of the lesson; its notifications are generated, as it
# says. The Terraform plan is local, with the fake token; nothing is created.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/gcp" || exit 1
from_lesson "$HERE/fatigue.md" pages.py > pages.py
block pages
run 'python3 pages.py'

export GOOGLE_OAUTH_ACCESS_TOKEN=fake
rm -rf tf/alerting && mkdir -p tf/alerting && cd tf/alerting || exit 1
from_lesson "$HERE/policies.md" tf/alerting/main.tf > main.tf
quiet 'terraform init -input=false'
block plan
run 'terraform plan -input=false -no-color | grep -E "^  # |duration|evaluation_missing_data|severity|type  |Plan:"'
