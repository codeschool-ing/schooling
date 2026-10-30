#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of gcp-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/gcplab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# Runs in the lab lesson 1 built (../../from-lessons.sh says how), against an
# empty emulator. iam.tf is read out of the ```hcl fence of
# "authoritative-or-additive" and deny.tf out of the one of
# "deny-and-inheritance", both into a fresh ~/gcp/policy: the plan of the
# first block is made with iam.tf alone, the second with both, as the student
# writes them.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson: nothing.
#
# NOTHING HERE REACHES GOOGLE. The policy in "allow-policies" is a file in
# Google's documented format, written for the course, and the prose says so.
#
# NOT PRODUCED HERE, and said so in the prose: reading or writing a real allow
# or deny policy, and Google's evaluation of a request.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
pubsub_fresh

block emulator-iam
run 'gcloud pubsub topics create orders'
run 'gcloud pubsub topics get-iam-policy orders'
run 'gcloud pubsub topics add-iam-policy-binding orders --member=group:planner-devs@example.com --role=roles/pubsub.publisher'

tf_dir policy
tf_file "$HERE/authoritative-or-additive.md" 1 iam.tf
block plan-iam
run "terraform plan -input=false -no-color | sed -n '/# google/,/^    }/p'"
tf_file "$HERE/deny-and-inheritance.md" 1 deny.tf
block plan-deny
run "terraform plan -input=false -no-color | sed -n '/# google_iam_deny_policy/,/^    }/p'"
