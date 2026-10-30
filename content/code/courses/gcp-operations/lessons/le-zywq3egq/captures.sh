#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of gcp-operations.
#
#   bash captures.sh     # after lab.sh tools (Terraform)
#
# align.py is taken out of the lesson (from_lesson). The Terraform plans are
# computed locally by the google provider with GOOGLE_OAUTH_ACCESS_TOKEN=fake;
# nothing is created, and there is no Cloud Monitoring to create it in.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/gcp" || exit 1
from_lesson "$HERE/metrics.md" align.py > align.py

block align
run 'python3 align.py'

export GOOGLE_OAUTH_ACCESS_TOKEN=fake
rm -rf tf/monitoring && mkdir -p tf/monitoring && cd tf/monitoring || exit 1
from_lesson "$HERE/checks.md" tf/monitoring/main.tf > main.tf
from_lesson "$HERE/checks.md" tf/monitoring/dashboard.json > dashboard.json
quiet 'terraform init -input=false'
block plan
run 'terraform validate -no-color'
run 'terraform plan -input=false -no-color | grep -E "^  # |period|timeout|path|selected_regions|Plan:"'
