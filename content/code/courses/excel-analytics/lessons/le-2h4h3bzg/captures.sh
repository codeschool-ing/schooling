#!/usr/bin/env bash
# Every number lesson 8 quotes, computed by a spreadsheet from the tables
# lesson 1 gives the student to paste, with lesson 2's Revenue column and
# lesson 7's tables added first.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Run it from this
# directory, after `bash ../../lab.sh up`:
#
#   bash captures.sh
#
# Nothing here is a terminal the student sees: this course has no terminal.
# What it proves is that each formula the lesson prints, put into a cell of a
# workbook holding the pasted tables, answers the number the prose quotes.
# A validation rule is tried by putting its formula beside the value the
# lesson names: TRUE is accepted, FALSE refused, as Excel reads a custom rule.
# The spreadsheet is LibreOffice Calc 24.2 (lab.sh says why not Excel); the
# Price rule uses XLOOKUP, which goes to the Excel-compatible calculator.
# STAGED: the trailing space typed into G4 is the lab's, as the lesson asks
# the student to type it and undo it.
#
# Recorded on Ubuntu 24.04 with LibreOffice 24.2.7.2, TZ=America/Sao_Paulo,
# on 2026-10-10.
set -euo pipefail
export TZ=America/Sao_Paulo
cd "$(dirname "$0")"
exec bash ../../lab.sh run l08.py
