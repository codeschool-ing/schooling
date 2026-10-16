#!/usr/bin/env bash
# Every number lesson 4 quotes, computed from the tables lesson 1 gives the
# student to paste.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Run it from this
# directory, after `bash ../../lab.sh up`:
#
#   bash captures.sh
#
# Nothing here is a terminal the student sees: this course has no terminal.
# What it proves is that each formula the lesson prints, put into the cell the
# lesson names and filled down the way the fill handle fills it, answers the
# number the prose quotes.
# NOT CALC: every XLOOKUP. LibreOffice Calc 24.2 has no XLOOKUP, so those
# formulas are computed by `formulas`, the Excel-compatible calculator lab.sh
# pins, one cell at a time or a whole filled column at a time. VLOOKUP, INDEX
# and MATCH are computed by Calc, with text comparison set to ignore case as
# Excel's does, and the margin total is computed both ways and agrees.
# STAGED: the band table, the CER1K price table and the column inserted in
# Products are the lesson's own; the inserted column is an experiment the
# lesson undoes.
#
# Recorded on Ubuntu 24.04 with LibreOffice 24.2.7.2, TZ=America/Sao_Paulo,
# on 2026-10-10.
set -euo pipefail
export TZ=America/Sao_Paulo
cd "$(dirname "$0")"
exec bash ../../lab.sh run l04.py
