#!/usr/bin/env bash
# Every number lesson 10 quotes, computed by a spreadsheet from the tables
# lesson 1 gives the student to paste, with lesson 2's Revenue column and
# lesson 7's tables added first.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Run it from this
# directory, after `bash ../../lab.sh up`:
#
#   bash captures.sh
#
# Nothing here is a terminal the student sees: this course has no terminal.
# What it proves is that each pivot table the lesson builds, built by the
# spreadsheet's own pivot table (Calc's DataPilot) over the same range, shows
# the numbers the prose quotes, and that each of those numbers equals the
# SUMIFS, COUNTIFS or AVERAGEIFS the lesson prints beside it, in the same run.
# The spreadsheet is LibreOffice Calc 24.2 (lab.sh says why not Excel); its
# labels differ from Excel's (`Total Result`, `Q1`), its numbers do not.
# STAGED: the 15 bags typed over S1001's 14, and the misspelt channel typed
# into G4, are the lab's, as the lesson describes them; both are put back.
#
# Recorded on Ubuntu 24.04 with LibreOffice 24.2.7.2, TZ=America/Sao_Paulo,
# on 2026-10-10.
set -euo pipefail
export TZ=America/Sao_Paulo
cd "$(dirname "$0")"
exec bash ../../lab.sh run l10.py
