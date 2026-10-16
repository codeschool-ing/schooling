#!/usr/bin/env bash
# Every number lesson 5 quotes, computed by a spreadsheet from the tables
# lesson 1 gives the student to paste, plus the Revenue column lesson 2 adds.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Run it from this
# directory, after `bash ../../lab.sh up`:
#
#   bash captures.sh
#
# Nothing here is a terminal the student sees: this course has no terminal.
# What it proves is that each formula the lesson prints, put into a cell of a
# workbook holding the pasted tables, answers the number the prose quotes.
# The spreadsheet is LibreOffice Calc 24.2 (lab.sh says why not Excel).
# STAGED: Sales!H `Revenue` is lesson 2's, and l05.py adds it the way lesson 2
# tells the student to (H2 =E2*F2, filled down to H109) before computing.
# Where Calc and Excel name an error differently (a mismatched range is
# Err:502 in Calc and #VALUE! in Excel), l05.py prints Calc's and the lesson
# names Excel's.
#
# Recorded on Ubuntu 24.04 with LibreOffice 24.2.7.2, TZ=America/Sao_Paulo,
# on 2026-10-10.
set -euo pipefail
export TZ=America/Sao_Paulo
cd "$(dirname "$0")"
exec bash ../../lab.sh run l05.py
