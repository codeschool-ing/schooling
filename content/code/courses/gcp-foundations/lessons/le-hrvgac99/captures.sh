#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of gcp-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/gcplab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# Runs in the lab lesson 1 built (../../from-lessons.sh says how). dataset.tf
# is read out of the two ```hcl fences of "the-export" in turn, into a fresh
# ~/gcp/export-dataset; make_export.py out of the example in "a-month-of-rows",
# ask.py out of its ```python fence, and every .sql file out of the ```sql
# fences of "a-month-of-rows" and "who-spent-this". The emulator is not used.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson: THE MONTH OF
# BILLING ROWS IS INVENTED by make_export.py, and the prose says so: projects,
# usage, prices and credits. Its shape is a subset of the standard export's.
#
# NOTHING HERE REACHES GOOGLE.
#
# NOT PRODUCED HERE, and said so in the prose: the dataset, the export, and the
# BigQuery form of net.sql.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab

tf_dir export-dataset
tf_file "$HERE/the-export.md" 1 dataset.tf
block refused
run 'terraform plan -input=false -no-color 2>&1 | tail -6'
tf_file "$HERE/the-export.md" 2 dataset.tf
block planned
run 'terraform plan -input=false -no-color | grep -E "^Plan:|# google|location|dataset_id|role"'

rm -rf ~/gcp/export && mkdir -p ~/gcp/export && cd ~/gcp/export || exit 1
at '~/gcp/export'
example "$HERE/a-month-of-rows.md" make_export.py > make_export.py || exit 1
fences python "$HERE/a-month-of-rows.md" 1 > ask.py || exit 1
fences sql "$HERE/a-month-of-rows.md" 1 > month.sql || exit 1
fences sql "$HERE/a-month-of-rows.md" 2 > columns.sql || exit 1
fences sql "$HERE/who-spent-this.md" 1 > net.sql || exit 1
fences sql "$HERE/who-spent-this.md" 2 > teams.sql || exit 1
fences sql "$HERE/who-spent-this.md" 3 > forgotten.sql || exit 1
block month
run 'python3 make_export.py > october.jsonl'
run 'python3 ask.py month.sql'
block columns
run 'python3 ask.py columns.sql'
for q in net teams forgotten; do block $q; run "python3 ask.py $q.sql"; done
