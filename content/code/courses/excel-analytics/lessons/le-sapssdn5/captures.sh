#!/usr/bin/env bash
# Every number lesson 14 quotes, computed from the files lessons 13 and 14 print for
# the student to save with a text editor, and the pasted Sales and Products.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Run it from this
# directory, after `bash ../../lab.sh up`:
#
#   bash captures.sh
#
# NOT RUN: Power Query. It has no engine outside Excel, and this machine has no
# Excel (lab.sh). What each transformation produces (the filter, the merges and their join
# kinds, the append, the unpivot, the groupings) is computed in Python by lab/l14.py over
# the text of the lesson's own fences (lab/pqfiles.py), and the lesson says so.
# The one formula the lesson prints, a SUMIFS that reconciles a grouped total,
# is put in a cell of LibreOffice Calc 24.2 like every formula of lessons 1-12.
#
# Recorded on Ubuntu 24.04 with Python 3.12 and LibreOffice 24.2.7.2, TZ=America/Sao_Paulo, on
# 2026-10-10.
set -euo pipefail
export TZ=America/Sao_Paulo
cd "$(dirname "$0")"
exec bash ../../lab.sh run l14.py
