#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of linux-terminal, replayed.
#
# THE AUTHOR'S TOOL; the loader reads none of it. ../../lab/replay.py types every
# transcript into a real bash and prints the fences whose output differs; --setup
# writes the lesson's programs into ~/work from the `sh` fence of
# what-a-process-is.md, exactly as the page shows them.
#
#   sudo bash captures.sh
#
# Nearly every fence in this lesson differs on any replay, and should: process
# numbers, elapsed times and load averages are the machine's moment. What was
# re-taken on 2026-10-07 is the zombie in states.md. The rest are the first
# capture's, from the same sandbox (PID 1 is its supervisor, and its own
# processes show in ps, pstree and top, which the prose says where it matters);
# the hangup in surviving-the-hangup closes a terminal, which replay.py cannot.
set -euo pipefail
cd "$(dirname "$0")"
LAB=../../lab
bash "$LAB/upto.sh" 6
sections=$(python3 -c "import json; print(' '.join(s['slug'] + '.md' for s in json.load(open('lesson.json'))['sections'] if s['kind'] != 'practice'))")
# shellcheck disable=SC2086
python3 "$LAB/replay.py" --setup $sections
