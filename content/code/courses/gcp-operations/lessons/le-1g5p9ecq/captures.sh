#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of gcp-operations.
#
#   bash captures.sh     # after lab.sh tools (Terraform)
#
# slo.py is taken out of the lesson. The Terraform plan is local, with the
# fake token; nothing is created.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/gcp" || exit 1
from_lesson "$HERE/budget.md" slo.py > slo.py
block slo
run 'python3 slo.py'

export GOOGLE_OAUTH_ACCESS_TOKEN=fake
rm -rf tf/slo && mkdir -p tf/slo && cd tf/slo || exit 1
from_lesson "$HERE/declared.md" tf/slo/main.tf > main.tf
quiet 'terraform init -input=false'
block plan
run 'terraform plan -input=false -no-color | grep -E "^  # |goal|rolling_period_days|threshold_value|duration|Plan:"'
