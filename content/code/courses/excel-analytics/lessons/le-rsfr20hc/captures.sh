#!/usr/bin/env bash
# Every number lesson 13 quotes, computed from the files the lesson prints for
# the student to save with a text editor.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Run it from this
# directory, after `bash ../../lab.sh up`:
#
#   bash captures.sh
#
# NOT RUN: Power Query. It has no engine outside Excel, and this machine has no
# Excel (lab.sh). What each import step produces (the rows, the types read
# under a locale, the folder combined) is computed in Python by lab/l13.py over
# the text of the lesson's own fences (lab/pqfiles.py), and the lesson says so.
# The database and web sections describe dialogs and quote no number.
#
# Recorded on Ubuntu 24.04 with Python 3.12, TZ=America/Sao_Paulo, on
# 2026-10-10.
set -euo pipefail
export TZ=America/Sao_Paulo
cd "$(dirname "$0")"
exec bash ../../lab.sh run l13.py
