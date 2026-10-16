#!/usr/bin/env bash
# Every number lesson 18 computes: the size of a sheet, what a file past the
# edge loses, and the same question asked of a database.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Run it from this
# directory, after `bash ../../lab.sh up`:
#
#   bash captures.sh
#
# Nothing here is a terminal the student sees: this course has no terminal.
# =ROWS(A:A) and =COLUMNS(1:1) are put, exactly as printed, into a LibreOffice
# Calc 24.2 workbook, whose grid is Excel's; the SUMIFS the lesson prints runs
# over the pasted tables with `Sales` made a table carrying lesson 2's Revenue
# column. The SQL query of section `where-next` is read out of the lesson and
# run in SQLite (Python's sqlite3) over the pasted sales. NOT COMPUTED: the
# public cases of section `errors-at-scale` and the .xls limits, which are
# documented facts the lesson states with their dates and sources.
#
# Recorded on Ubuntu 24.04 with LibreOffice 24.2.7.2, TZ=America/Sao_Paulo,
# on 2026-10-10.
set -euo pipefail
export TZ=America/Sao_Paulo
cd "$(dirname "$0")"
exec bash ../../lab.sh run l18.py
