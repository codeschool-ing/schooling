#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of linux-terminal, replayed.
#
# THE AUTHOR'S TOOL; the loader reads none of it. ../../lab/replay.py types every
# transcript of the lesson into a real bash, as the user and in the directory the
# prompt names, and prints the fences whose output differs. --setup runs every
# `sh` fence in the order the page shows it: the accounts, the group and /srv in
# user-group-other.md, and the small directories of the sections after it.
#
#   sudo bash captures.sh
#
# The machine first goes through lessons 1 to 3 (../../lab/upto.sh), because
# bruno is made in lesson 3. Recorded on Ubuntu 24.04 (a sandbox: no systemd, no
# AppArmor), as `ana`, uid 1001, on 2026-10-07; dates differ on any machine.
# Three things replay.py cannot type are kept from the first capture, which ran
# the same commands: `newgrp` (it starts a shell of its own), `sudo -l`'s
# wrapping (it wraps to the terminal's width) and carla's refused `sudo`.
set -euo pipefail
cd "$(dirname "$0")"
LAB=../../lab
bash "$LAB/upto.sh" 4
sections=$(python3 -c "import json; print(' '.join(s['slug'] + '.md' for s in json.load(open('lesson.json'))['sections'] if s['kind'] != 'practice'))")
# shellcheck disable=SC2086
python3 "$LAB/replay.py" --setup $sections
