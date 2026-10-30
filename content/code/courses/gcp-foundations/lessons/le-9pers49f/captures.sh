#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of gcp-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/gcplab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# Runs in the lab lesson 1 built (../../from-lessons.sh says how). roles.tf is
# written twice into a fresh ~/gcp/roles, as the student edits it: first from
# the first ```hcl fence of "custom-roles", then from the second. The emulator
# is not used.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson: nothing.
#
# NOTHING HERE REACHES GOOGLE.
#
# NOT PRODUCED HERE, and said so in the prose: `gcloud iam roles describe`,
# creating a role, and Google's check of a permission's support level, which
# need a Google account.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
SEC=$HERE/custom-roles.md

tf_dir roles
tf_file "$SEC" 1 roles.tf
block validate
run 'terraform validate -no-color'
tf_file "$SEC" 2 roles.tf
block plan
run "terraform plan -input=false -no-color | grep -E '^  # |      \\+ (name|role|role_id|permissions)|^Plan:'"
