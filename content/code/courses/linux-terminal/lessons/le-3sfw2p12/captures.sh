#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of linux-terminal, replayed.
#
# THE AUTHOR'S TOOL; the loader reads none of it. ../../lab/replay.py types every
# `PS /home/ana/work/ps>` command into one pwsh kept for the whole run, and every
# bash command into a real bash, and prints the fences whose output differs.
# --setup-home runs the `sh` fences that begin in ~: the copy of lesson 8's
# access.log and sales.csv into ~/work/ps, and bigfiles.ps1, which the
# `cat bigfiles.ps1` transcript then checks against the page. The install of
# PowerShell itself is not replayed; the capture machine has it already, from
# Microsoft's repository, as the page says: PowerShell 7.6.6.
#
#   sudo bash captures.sh
#
# Expected to differ: dates, the day of the week a week from now, free space on
# the disk, the timing of pwsh against bash (kept from the first capture, on 7.4),
# and the order of a hashtable's keys, which .NET seeds afresh in every process —
# the collections section says so. Recaptured on 2026-10-07 after lessons 1 to 9.
set -euo pipefail
cd "$(dirname "$0")"
LAB=../../lab
bash "$LAB/upto.sh" 10
sections=$(python3 -c "import json; print(' '.join(s['slug'] + '.md' for s in json.load(open('lesson.json'))['sections'] if s['kind'] != 'practice'))")
# shellcheck disable=SC2086
python3 "$LAB/replay.py" --setup-home $sections
