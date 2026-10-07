#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of linux-terminal, replayed.
#
# THE AUTHOR'S TOOL; the loader reads none of it. ../../lab/replay.py types every
# transcript into a real bash and prints the fences whose output differs.
# --setup runs the `sh` fence of the-three-streams.md, which writes
# make-data.py into ~/work exactly as the page shows it and runs it: the log
# and the sales file every section reads are that program's, from a fixed seed,
# so the student's bytes are these (sha256sum is the first transcript).
#
#   sudo bash captures.sh
#
# Recaptured on 2026-10-07 after lessons 1 to 7 (../../lab/upto.sh). Two kinds
# of fence are kept from the first capture because they differ only in shape:
# cat -n and nl keep their TAB, and `ls` there printed in columns. The
# $FDPID fence needs lesson 6's tail running.
set -euo pipefail
cd "$(dirname "$0")"
LAB=../../lab
bash "$LAB/upto.sh" 8
sections=$(python3 -c "import json; print(' '.join(s['slug'] + '.md' for s in json.load(open('lesson.json'))['sections'] if s['kind'] != 'practice'))")
# shellcheck disable=SC2086
python3 "$LAB/replay.py" --setup $sections
