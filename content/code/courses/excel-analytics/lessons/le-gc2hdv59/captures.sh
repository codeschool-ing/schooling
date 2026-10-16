#!/usr/bin/env bash
# Every number lesson 16 quotes, computed from the tables lesson 1 gives the
# student to paste.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Run it from this
# directory, after `bash ../../lab.sh up`:
#
#   bash captures.sh
#
# Nothing here is a terminal the student sees: this course has no terminal.
# NOT RUN: DAX. It has no engine outside Excel, and this machine has no Excel
# (lab.sh says why). Each measure the lesson defines is computed in plain
# Python the way the model evaluates it in a pivot cell: the cell's filters
# pick dimension rows, the relationships of lesson 15 carry them to Sales, and
# the expression runs over what is left; CALCULATE, ALL, TOTALYTD and
# SAMEPERIODLASTYEAR change that selection as DAX defines them. The lesson
# says so. What a spreadsheet can check is checked in LibreOffice Calc 24.2:
# the SUMIFS and COUNTIFS of section `checking`, over lesson 2's Revenue
# column, each of which must agree with a measure.
#
# Recorded on Ubuntu 24.04 with LibreOffice 24.2.7.2, TZ=America/Sao_Paulo,
# on 2026-10-10.
set -euo pipefail
export TZ=America/Sao_Paulo
cd "$(dirname "$0")"
exec bash ../../lab.sh run l16.py
