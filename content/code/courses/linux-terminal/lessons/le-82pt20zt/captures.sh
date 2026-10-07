#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of linux-terminal, replayed.
#
# THE AUTHOR'S TOOL; the loader reads none of it. ../../lab/replay.py types every
# transcript into a real bash and prints the fences whose output differs.
# --setup-home runs only the `sh` fences that begin in ~ or /tmp: each section's
# scripts, written into ~/work/scripts exactly as the page shows them, and the
# scratch files of /tmp/q and /tmp/q2. Every `cat script.sh` transcript then
# checks the page's block against the page's listing; a script and its listing
# cannot drift apart without this replay saying so. This lesson's other `sh`
# fences are examples to read, and are not run.
#
#   sudo bash captures.sh
#
# Expected to differ: clock times, dates, mktemp's random names; the two fences
# with typed input (read -p, and a file with no final newline running into the
# prompt), which replay.py cannot type; and shellcheck's footer of links, which
# the page leaves out. Recaptured on 2026-10-07 after lessons 1 to 8.
set -euo pipefail
cd "$(dirname "$0")"
LAB=../../lab
bash "$LAB/upto.sh" 9
sections=$(python3 -c "import json; print(' '.join(s['slug'] + '.md' for s in json.load(open('lesson.json'))['sections'] if s['kind'] != 'practice'))")
# shellcheck disable=SC2086
python3 "$LAB/replay.py" --setup-home $sections
