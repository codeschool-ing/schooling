#!/usr/bin/env bash
# Every number lesson 12 quotes, computed by a spreadsheet from the tables
# lesson 1 gives the student to paste, with lesson 2's Revenue column and
# lesson 7's table `Sales` over them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Run it from this
# directory, after `bash ../../lab.sh up`:
#
#   bash captures.sh
#
# Nothing here is a terminal the student sees: this course has no terminal.
# A chart draws numbers somebody computed, and these are those numbers: the
# Mix, Monthly and Trends sheets the lesson builds, each formula entered as
# printed and filled as the fill handle fills it, in LibreOffice Calc 24.2,
# and the product revenue the PivotChart draws, from Calc's own pivot table.
# How Excel draws a chart is not computed; the lesson describes it in words.
#
# Recorded on Ubuntu 24.04 with LibreOffice 24.2.7.2, TZ=America/Sao_Paulo,
# on 2026-10-10.
set -euo pipefail
export TZ=America/Sao_Paulo
cd "$(dirname "$0")"
exec bash ../../lab.sh run l12.py
