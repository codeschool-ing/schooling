#!/usr/bin/env bash
# Every number lesson 15 quotes, computed from the tables lesson 1 gives the
# student to paste.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Run it from this
# directory, after `bash ../../lab.sh up`:
#
#   bash captures.sh
#
# Nothing here is a terminal the student sees: this course has no terminal.
# NOT RUN: Power Pivot. It has no engine outside Excel, and this machine has
# no Excel (lab.sh says why). What a pivot table built on the data model shows
# is computed in plain Python by following the lesson's three relationships,
# each filtering from its one side to its many side, over the pasted rows. The
# lesson says so where it quotes a result. What a spreadsheet can check is
# checked in LibreOffice Calc 24.2: the length of the calendar
# (=DATE(2026,12,31)-DATE(2025,1,1)+1) and the grand total of lesson 2's
# Revenue column.
#
# Recorded on Ubuntu 24.04 with LibreOffice 24.2.7.2, TZ=America/Sao_Paulo,
# on 2026-10-10.
set -euo pipefail
export TZ=America/Sao_Paulo
cd "$(dirname "$0")"
exec bash ../../lab.sh run l15.py
