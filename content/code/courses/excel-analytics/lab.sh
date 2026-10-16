#!/usr/bin/env bash
# The machine every number in excel-analytics was computed on.
#
# THE STUDENT NEVER SEES THIS FILE. The student's lab is Excel on their own
# computer, which lesson 1 section `the-lab` sets up; the data they work on is
# pasted from lesson 1 section `your-data`; every formula they type is printed
# in the lesson that uses it.
#
# NOT REACHABLE, AND THEREFORE NOT RUN: Microsoft Excel, Power Query and Power
# Pivot. This machine is Linux and Excel is not sold for it. So:
#
#   lessons 1-12   every formula a lesson prints is put, exactly as printed, in
#                  a cell of a LibreOffice Calc workbook holding the pasted
#                  tables, and the number the lesson quotes is the one Calc
#                  answered (lab/engine.py). Calc 24.2 lacks XLOOKUP and XMATCH;
#                  those formulas are computed by `formulas`, an Excel-compatible
#                  calculator in Python, pinned below.
#   pivot tables   computed by Calc's own pivot table (DataPilot) over the same
#                  range, and checked against SUMIFS.
#   lessons 13-16  Power Query and DAX have no engine outside Excel. What their
#                  steps produce on the course's data is computed in Python by
#                  lab/lNN.py, step by step, and the lessons say that nothing
#                  in them was run in Excel.
#
#   bash lab.sh up               the virtual environment, once
#   bash lab.sh run lNN.py       one lesson's numbers (what captures.sh calls)
#   bash lab.sh check            the data in lesson 1 against lab/data.py
#
# Recorded on Ubuntu 24.04, LibreOffice 24.2.7.2 (the distribution's), Python
# 3.12 with formulas 1.3.4 and openpyxl 3.1.5, TZ=America/Sao_Paulo.
set -euo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
VENV=${XLAB_VENV:-/tmp/claude-0/xlvenv}
export TZ=America/Sao_Paulo

case "${1:-}" in
  up)
    command -v soffice >/dev/null || { echo "needs LibreOffice: apt-get install libreoffice-calc python3-uno" >&2; exit 1; }
    /usr/bin/python3 -c 'import uno' || { echo "needs python3-uno" >&2; exit 1; }
    [ -x "$VENV/bin/python" ] || python3 -m venv --system-site-packages "$VENV"
    "$VENV/bin/pip" install -q formulas==1.3.4 openpyxl==3.1.5
    ;;
  run)
    # The system Python carries the UNO bridge; the venv carries `formulas`.
    cd "$HERE/lab"
    PYTHONPATH="$HERE/lab:$("$VENV/bin/python" -c 'import site; print(site.getsitepackages()[0])')" \
      /usr/bin/python3 "$2"
    ;;
  check)
    cd "$HERE/lab" && /usr/bin/python3 data.py --check
    ;;
  *)
    sed -n '2,30p' "$0"; exit 2 ;;
esac
