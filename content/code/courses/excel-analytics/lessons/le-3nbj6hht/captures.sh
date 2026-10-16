#!/usr/bin/env bash
# Every number lesson 11 quotes, computed by a spreadsheet from the tables
# lesson 1 gives the student to paste, with lesson 2's Revenue column and
# lesson 7's table `Sales` over them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Run it from this
# directory, after `bash ../../lab.sh up`:
#
#   bash captures.sh
#
# Nothing here is a terminal the student sees: this course has no terminal.
# The pivot tables are LibreOffice Calc 24.2's own (DataPilot), each checked
# against the SUMIFS the lesson prints. Calc has no calculated fields, no
# calculated items, no slicers and no timelines: l11.py says, for each, how
# the number Excel shows was made from Calc's pivot instead.
#
# Recorded on Ubuntu 24.04 with LibreOffice 24.2.7.2, TZ=America/Sao_Paulo,
# on 2026-10-10.
set -euo pipefail
export TZ=America/Sao_Paulo
cd "$(dirname "$0")"
exec bash ../../lab.sh run l11.py
