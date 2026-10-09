#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of linux-terminal, replayed.
#
# THE AUTHOR'S TOOL; the loader reads none of it. ../../lab/replay.py types every
# transcript of the lesson into a real bash, as the user and in the directory the
# prompt names, and prints the fences whose output differs. --setup runs every
# `sh` fence in the order the page shows it: the ~/work project in fhs.md, and
# the small directories of moving-and-looking, file-operations, globbing, links,
# hidden-and-special and archives. What the student builds is what the
# transcripts were taken in.
#
#   sudo bash captures.sh
#
# Recorded on Ubuntu 24.04 (a sandbox: no systemd), as `ana`, uid 1001, on
# 2026-10-07. Expected to differ on any other machine: dates, inode numbers, the
# order `find` walks a directory in, df's numbers, /proc and /dev, and a few
# listings the prose shows in columns. mounts and disk-usage need loop devices.
set -euo pipefail
cd "$(dirname "$0")"
LAB=../../lab
bash "$LAB/reset.sh"
(cd ../le-232xd54k && python3 "../$LAB/replay.py" --setup --only 0 getting-a-linux.md >/dev/null)
sections=$(python3 -c "import json; print(' '.join(s['slug'] + '.md' for s in json.load(open('lesson.json'))['sections'] if s['kind'] != 'practice'))")
# shellcheck disable=SC2086
python3 "$LAB/replay.py" --setup $sections
