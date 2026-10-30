#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of gcp-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/gcplab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# Runs in the lab lesson 1 built (../../from-lessons.sh says how), against an
# empty emulator. provider.tf and hierarchy.tf are read out of the ```hcl
# fences of "the-estate-as-code", in that order, into a fresh ~/gcp/hierarchy.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson: Terraform
# colours its init and validate messages; the colour codes are removed, which
# is what a terminal does with them on the screen.
#
# ONE BLOCK REACHES GOOGLE ITSELF: `getproject` asks the real Resource Manager
# for a project with no credential, and quotes the refusal. Nothing else here
# leaves the machine except `terraform init`, which downloads the provider from
# registry.terraform.io into the cache the first time.
#
# NOT PRODUCED HERE, and said so in the prose: creating an organisation,
# folders or projects, which needs a Google account and an organisation.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
pubsub_fresh

block two-projects
run 'gcloud pubsub topics create orders --project planner-dev'
run 'gcloud pubsub topics create orders --project planner-prod'
run 'gcloud pubsub topics list --project planner-prod --format="value(name)"'
run 'gcloud pubsub topics list --format="value(name)"'

block getproject
run 'curl -sS https://cloudresourcemanager.googleapis.com/v3/projects/planner-dev'

# ---- the tree, as Terraform ----------------------------------------------------
rm -rf ~/gcp/hierarchy
sh_fences "$HERE/the-estate-as-code.md" 1 | bash -e || exit 1
cd ~/gcp/hierarchy && at '~/gcp/hierarchy'
tf_file "$HERE/the-estate-as-code.md" 1 provider.tf
tf_file "$HERE/the-estate-as-code.md" 2 hierarchy.tf

block init
run 'terraform init -input=false' | sed 's/\x1b\[[0-9;]*m//g'
run 'terraform validate' | sed 's/\x1b\[[0-9;]*m//g'
run "terraform plan -input=false -no-color | grep -E '^  # |^Plan:'"
run 'terraform plan -input=false -no-color -target=google_project.dev | sed -n "/# google_project.dev/,/^    }/p"'
