#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of azure-operations, as a script that
# produces them. Its output is not committed; every transcript was copied from it.
#
#   bash lab.sh student && bash lab.sh tools   # once
#   bash captures.sh
#
# The emulator is started by the lesson's own fence (capture.sh, kusto_up), and
# kql.py and requests.kql are extracted from the lesson's own blocks, so what
# runs is what the student reads. The database is volatile: it lives in the
# container's memory and is gone when the container stops, which block down
# shows. No Log Analytics workspace exists anywhere here.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
student_env
kusto_up
cd "$HOME/azure/kusto" || exit 1

block running
run 'docker ps --format "{{.Names}}  {{.Status}}"'
run 'docker image ls --format "{{.Repository}}  {{.Size}}" | grep kustainer'

block db
run "python3 kql.py '.create database shop volatile'"
run "python3 kql.py 'print answer = 6 * 7'"

block load
from_lesson "$HERE/loading.md" requests.kql > requests.kql
run 'python3 kql.py < requests.kql'

block look
run "python3 kql.py 'AppRequests | count'"
run "python3 kql.py 'AppRequests | take 3'"

block size
run "python3 kql.py 'AppRequests | summarize rows = count(), MB = round(sum(estimate_data_size(*)) / 1e6, 2) by day = bin(TimeGenerated, 1d)'"

block down
quiet 'docker stop kusto'
run "python3 kql.py 'AppRequests | count'"
lab_down
