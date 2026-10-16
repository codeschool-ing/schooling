#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of aws-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/awslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# Runs in the lab lesson 1 built (../../from-lessons.sh says how), against an
# empty, seeded moto, which this lesson only asks for Data Exports and the
# older CUR API. Everything the student writes is read out of the lesson:
# export.json from the ```sh fence of "data-exports", make_cur.py and ask.py
# from the examples in "a-month-of-lines", team.sql and remainder.sql from the
# ```sh fence of "who-spent-what".
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - a 500 from moto is printed whole by the AWS command line, five lines of
#     HTML; the commands that meet one pipe their output through `grep ERROR`,
#     and the prose shows that pipe;
#   - the files are written into a scratch directory that the prompt shows as
#     ~/aws, so that a run leaves nothing behind in the lab.
#
# NOTHING HERE REACHES AWS. cur.csv is made-up data, written by make_cur.py,
# and the prose says so wherever it quotes a number from it.
#
# NOT PRODUCED HERE, and said so in the prose: a real export, its delivery to
# S3, Athena and QuickSight. All need an AWS account with a bill.
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
moto_fresh
WORK=$(mktemp -d)
cd "$WORK" || exit 1
trap 'moto_stop; rm -rf "$WORK"' EXIT
sh_fences "$HERE/data-exports.md" 1 | bash -e || exit 1
sh_fences "$HERE/who-spent-what.md" 1 | bash -e || exit 1
example "$HERE/a-month-of-lines.md" make_cur.py > make_cur.py || exit 1
example "$HERE/a-month-of-lines.md" ask.py > ask.py || exit 1

block export
run 'aws bcm-data-exports create-export --export file://export.json 2>&1 | grep ERROR'
run 'aws cur describe-report-definitions 2>&1 | grep ERROR'

block make
run 'python3 make_cur.py'
run 'head -4 cur.csv'

block accounts
run 'python3 ask.py "SELECT line_item_usage_account_id AS account, sum(line_item_unblended_cost) AS dollars FROM cur GROUP BY account ORDER BY dollars DESC"'
run 'python3 ask.py "SELECT line_item_line_item_type AS type, count(*) AS lines, sum(line_item_unblended_cost) AS dollars FROM cur GROUP BY type ORDER BY dollars DESC"'

block team
run 'python3 ask.py team.sql'

block remainder
run 'python3 ask.py remainder.sql'

block share
run "python3 ask.py \"SELECT line_item_usage_account_id AS account, sum(line_item_unblended_cost) AS usage, sum(CASE WHEN json_extract(resource_tags, '\$.user_team') IS NULL THEN line_item_unblended_cost ELSE 0 END) AS untagged FROM cur WHERE line_item_line_item_type = 'Usage' GROUP BY account\""
