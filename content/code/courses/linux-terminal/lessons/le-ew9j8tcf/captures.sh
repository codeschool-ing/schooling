#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of linux-terminal, replayed.
#
# THE AUTHOR'S TOOL; the loader reads none of it. ../../lab/replay.py types every
# transcript of the lesson into a real bash, as the user and in the directory the
# prompt names, and prints the fences whose output differs. --setup runs the
# `sh` fences as the page shows them: hello.sh and hello.service in
# systemctl.md, broken.service in unit-files.md.
#
#   sudo bash captures.sh
#
# The machine first goes through lessons 1 to 4 (../../lab/upto.sh). It is a
# sandbox with no systemd as PID 1, which is why systemctl runs with --root=/
# and why reading-status, journalctl and targets-and-boot draw rather than
# quote. It has no SSH server either: the ssh section's transcripts are kept
# from the first capture, on a machine whose sshd listened on 2222, and the prose
# says so. Recorded on 2026-10-07; dates, hashes and salts differ every time.
set -euo pipefail
cd "$(dirname "$0")"
LAB=../../lab
bash "$LAB/upto.sh" 5
sections=$(python3 -c "import json; print(' '.join(s['slug'] + '.md' for s in json.load(open('lesson.json'))['sections'] if s['kind'] != 'practice'))")
# shellcheck disable=SC2086
python3 "$LAB/replay.py" --setup $sections
