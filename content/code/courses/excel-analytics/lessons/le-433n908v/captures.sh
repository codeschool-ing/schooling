#!/usr/bin/env bash
# Every number lesson 2 quotes, computed by a spreadsheet from the tables
# lesson 1 gives the student to paste.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Run it from this
# directory, after `bash ../../lab.sh up`:
#
#   bash captures.sh
#
# Nothing here is a terminal the student sees: this course has no terminal.
# What it proves is that each formula the lesson prints, put into the cell the
# lesson names and filled the way the fill handle fills it, answers the number
# the prose quotes. The spreadsheet is LibreOffice Calc 24.2 (lab.sh says why
# not Excel); lab/calcref.py spells another sheet's cells the way Calc reads
# them and makes text comparisons ignore case, as Excel's do.
# STAGED: the deleted row 50, the deleted column L and the 1044 typed over H50
# are the lesson's own experiments, each undone before the next.
# NOT RUN: the circular reference's warning and status bar are Excel's screen;
# Calc reports the same cell as Err:522, which the lesson does not quote.
#
# Recorded on Ubuntu 24.04 with LibreOffice 24.2.7.2, TZ=America/Sao_Paulo,
# on 2026-10-10.
set -euo pipefail
export TZ=America/Sao_Paulo
cd "$(dirname "$0")"
exec bash ../../lab.sh run l02.py
