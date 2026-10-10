#!/usr/bin/env bash
# Every number lesson 1 quotes, computed by a spreadsheet from the tables the
# lesson gives the student to paste.
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
# STAGED: the text "14" typed into E2 is the lab's, to show a number stored as
# text; the lesson describes it rather than asking the student to do it first.
#
# Recorded on Ubuntu 24.04 with LibreOffice 24.2.7.2, TZ=America/Sao_Paulo,
# on 2026-10-10.
set -euo pipefail
export TZ=America/Sao_Paulo
cd "$(dirname "$0")"
exec bash ../../lab.sh run l01.py
