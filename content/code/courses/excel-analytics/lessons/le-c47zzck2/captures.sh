#!/usr/bin/env bash
# Every number lesson 17 quotes: the dashboard's KPIs, its charts' values and
# the check formulas the lesson prints.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Run it from this
# directory, after `bash ../../lab.sh up`:
#
#   bash captures.sh
#
# Nothing here is a terminal the student sees: this course has no terminal.
# NOT RUN IN EXCEL: pivot tables over the data model, GETPIVOTDATA, slicers
# and timelines. The measures of lesson 16 (Revenue, Revenue LY, YoY %, Bags,
# Sales count) are computed in Python from the pasted sales for every slicer
# and timeline state the lesson describes. The SUMIFS, COUNTIFS and MAX
# formulas the lesson prints as checks are put, exactly as printed, into a
# LibreOffice Calc 24.2 workbook holding the pasted tables, with `Sales` made
# a table that carries lesson 2's Revenue column (lab.sh says why not Excel).
#
# Recorded on Ubuntu 24.04 with LibreOffice 24.2.7.2, TZ=America/Sao_Paulo,
# on 2026-10-10.
set -euo pipefail
export TZ=America/Sao_Paulo
cd "$(dirname "$0")"
exec bash ../../lab.sh run l17.py
