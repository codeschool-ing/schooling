#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of gcp-operations.
#
#   bash captures.sh     # after lab.sh tools (Terraform)
#
# The Terraform plan is local, with the fake token; nothing is created, and
# no request is ever evaluated by Cloud Armor.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/gcp" || exit 1
export GOOGLE_OAUTH_ACCESS_TOKEN=fake
rm -rf tf/armor && mkdir -p tf/armor && cd tf/armor || exit 1
from_lesson "$HERE/policy.md" tf/armor/main.tf > main.tf
quiet 'terraform init -input=false'
block plan
run 'terraform plan -input=false -no-color | grep -E "^  # |priority |action |preview |Plan:"'
block bad
sed -i 's/deny(403)/deny(418)/' main.tf
run 'terraform validate -no-color 2>&1 | head -6'
run 'terraform plan -input=false -no-color 2>&1 | grep -E "Error|418|Plan:" | head -4'
