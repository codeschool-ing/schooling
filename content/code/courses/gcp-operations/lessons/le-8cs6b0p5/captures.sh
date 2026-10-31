#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of gcp-operations.
#
#   bash captures.sh     # after lab.sh tools (Terraform)
#
# The Terraform plan is local, with the fake token. The organisation and
# project numbers are placeholders, as the lesson says; there
# is no organisation, and VPC Service Controls enforces nothing here.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/gcp" || exit 1
export GOOGLE_OAUTH_ACCESS_TOKEN=fake
rm -rf tf/vpcsc && mkdir -p tf/vpcsc && cd tf/vpcsc || exit 1
from_lesson "$HERE/perimeter.md" tf/vpcsc/main.tf > main.tf
quiet 'terraform init -input=false'
block plan
run 'terraform plan -input=false -no-color | grep -E "^  # |restricted_services|use_explicit_dry_run_spec|Plan:" '
