#!/usr/bin/env bash
# Every number lesson 3 quotes, computed by a spreadsheet from the tables
# lesson 1 gives the student to paste.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Run it from this
# directory, after `bash ../../lab.sh up`:
#
#   bash captures.sh
#
# Nothing here is a terminal the student sees: this course has no terminal.
# What it proves is that each formula the lesson prints, put into the cell the
# lesson names and filled down the way the fill handle fills it, answers the
# number the prose quotes. The spreadsheet is LibreOffice Calc 24.2 (lab.sh
# says why not Excel), with text comparisons set to ignore case as Excel's do.
# NOT CALC: `=4<=E2<10` and SUM over a column of TRUE and FALSE are computed by
# `formulas`, the Excel-compatible calculator lab.sh pins, because a logical
# value is a number in Calc and the two programs answer them differently.
# STAGED: the text `5 bags` typed into E110 is the lesson's own experiment.
#
# Recorded on Ubuntu 24.04 with LibreOffice 24.2.7.2, TZ=America/Sao_Paulo,
# on 2026-10-10.
set -euo pipefail
export TZ=America/Sao_Paulo
cd "$(dirname "$0")"
exec bash ../../lab.sh run l03.py
