#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of gcp-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/gcplab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# Runs in the lab lesson 1 built (../../from-lessons.sh says how). grants.tf
# is written twice into a fresh ~/gcp/principals, as the student edits it:
# first from the first ```hcl fence of "outside-identities", then from the
# second. The emulator is not used.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson: nothing.
#
# NOTHING HERE REACHES GOOGLE.
#
# NOT PRODUCED HERE, and said so in the prose: granting a role, and Google's
# check that a principal exists, which need a Google account.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
SEC=$HERE/outside-identities.md

tf_dir principals
tf_file "$SEC" 1 grants.tf
block validate
run 'terraform validate -no-color'
tf_file "$SEC" 2 grants.tf
block plan
run "terraform plan -input=false -no-color | grep -E '^  # |^Plan:'"
