#!/usr/bin/env bash
# The terminal sessions quoted in lesson 26 of gcp-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/gcplab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# Runs in the lab lesson 1 built (../../from-lessons.sh says how), against an
# empty emulator. ~/gcp/doors is made fresh with lesson 2's provider.tf,
# changed by the `sed` line of the ```sh fence of "one-request-three-ways";
# topics.tf is read out of its ```hcl fence.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson: nothing. The
# apply is real, against the emulator. The block `terraform` keeps the
# request and status lines of Terraform's debug log, and removes the
# timestamp and the provider's name from each, which the prose shows.
#
# NOTHING HERE REACHES GOOGLE.
#
# NOT PRODUCED HERE, and said so in the prose: the console, and the apply of
# the changed label, which the emulator refuses (lesson 3).
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
pubsub_fresh

tf_dir doors
sh_fences "$HERE/one-request-three-ways.md" 1 | grep '^sed ' | bash || exit 1
block gcloud
run 'gcloud pubsub topics create orders --log-http 2>&1 | grep -E "^(uri|method):"'
block curl
run 'curl -s -X PUT http://localhost:8085/v1/projects/planner-dev/topics/invoices'
tf_file "$HERE/one-request-three-ways.md" 1 topics.tf
block terraform
run 'TF_LOG=DEBUG terraform apply -input=false -no-color -auto-approve 2>&1 | grep -E "(PUT|GET|POST|DELETE|PATCH) /v1|HTTP/1.1 [0-9]{3}" | sed -E "s/^.*_x5: //"'
block list
run 'gcloud pubsub topics list --format="value(name.basename())"'

block delete
run 'gcloud pubsub topics delete shipments'
block refresh
run 'terraform plan -input=false -no-color -refresh-only 2>&1 | grep -E "has been deleted|^Plan|No changes"'
block recreate
run 'terraform plan -input=false -no-color | grep -E "^Plan|will be created"'
terraform apply -input=false -no-color -auto-approve > /dev/null 2>&1
block label
run "sed -i 's/team = \"planner\"/team = \"platform\"/' topics.tf"
run 'terraform plan -input=false -no-color | grep -E "^Plan|update in-place|\"team\""'
