#!/usr/bin/env bash
# The terminal session quoted in lesson 10 of gcp-foundations, as a script that
# produces it. The student never sees this file.
#
#   PYTHON3_DIR=/opt/gcplab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# Runs in the lab lesson 1 built (../../from-lessons.sh says how). groups.tf
# is read out of the ```hcl fence of "groups" into a fresh ~/gcp/groups. The
# emulator is not used.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson: nothing.
#
# NOTHING HERE REACHES GOOGLE.
#
# NOT PRODUCED HERE, and said so in the prose: a directory, a verified domain,
# a group, GCDS, single sign-on and a workforce pool.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab

tf_dir groups
tf_file "$HERE/groups.md" 1 groups.tf
block plan
run 'terraform plan -input=false -no-color -out=plan.bin | grep "^Plan:"'
run "terraform show -json plan.bin | jq -c '.resource_changes[] | {address, after: (.change.after | {parent, display_name, group_key, preferred_member_key, roles} | with_entries(select(.value != null)))}'"
