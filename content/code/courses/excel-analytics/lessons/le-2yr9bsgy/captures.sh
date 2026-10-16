#!/usr/bin/env bash
# Every number lesson 7 quotes, computed by a spreadsheet from the tables
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
# STAGED: Sales!H Revenue is lesson 2's and is added first. The three tables
# are Calc database ranges, which read structured references as Excel's
# tables do; l07.py says the three places Calc and Excel differ (the [@Bags]
# short form, a range that does not grow by itself, and XLOOKUP, which comes
# from the Excel-compatible calculator lab.sh pins). The sale S1109 is the
# lesson's, typed in and deleted again as the lesson asks.
#
# Recorded on Ubuntu 24.04 with LibreOffice 24.2.7.2, TZ=America/Sao_Paulo,
# on 2026-10-10.
set -euo pipefail
export TZ=America/Sao_Paulo
cd "$(dirname "$0")"
exec bash ../../lab.sh run l07.py
