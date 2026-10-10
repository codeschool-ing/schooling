#!/usr/bin/env bash
# Every number lesson 6 quotes, computed by a spreadsheet from the export the
# lesson gives the student to paste and the Sales table of lesson 1.
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
# STAGED: the text 03/12/2024 in Old export!P6 is typed by l06.py as text,
# which is what the apostrophe the lesson asks for does. Calc here reads
# dates month first, as an Excel set to US English does; the lesson says what
# an Excel set to Brazilian Portuguese answers instead. TEXTBEFORE and
# TEXTAFTER are not in Calc 24.2, and l06.py prints what they return by their
# definition.
# Where Calc names an error differently (Err:502 where Excel shows #VALUE!),
# l06.py prints Calc's and the lesson names Excel's.
#
# Recorded on Ubuntu 24.04 with LibreOffice 24.2.7.2, TZ=America/Sao_Paulo,
# on 2026-10-10.
set -euo pipefail
export TZ=America/Sao_Paulo
cd "$(dirname "$0")"
exec bash ../../lab.sh run l06.py
