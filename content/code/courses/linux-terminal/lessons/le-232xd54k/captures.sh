#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of linux-terminal, replayed.
#
# THE AUTHOR'S TOOL; the loader reads none of it. ../../lab/replay.py types every
# transcript of the lesson into a real bash, as the user and in the directory the
# prompt names, and prints the fences whose output differs. --setup runs the
# `sh` fence of getting-a-linux.md, "The files this lesson uses", exactly as the
# page shows it, so what the student builds is what the transcripts were taken in.
#
#   sudo bash captures.sh            # report
#
# Recorded on Ubuntu 24.04 (a sandbox: no systemd, no KVM), bash 5.2, as `ana`,
# uid 1001, on 2026-10-07. Dates, sizes of /proc and the machine's own accounts
# differ on every machine and are expected to.
#
# Three sessions need the machine arranged first, and are captured on their own:
#   - getting-a-linux, `sudo kvm-ok`: needs cpu-checker installed.
#   - getting-a-linux, `tree` and when-it-goes-wrong, Ubuntu's `celar`: need the
#     command-not-found package (and python3 pointing at 3.12, as on stock Ubuntu,
#     or its helper cannot import apt_pkg). Remove it afterwards: the rest of the
#     course was captured without it.
#   - getting-a-linux, `sudo apt install tree` under the lock:
#     ../../lab/capture-apt-lock.py, which starts the real unattended-upgrade.
set -euo pipefail
cd "$(dirname "$0")"
LAB=../../lab
bash "$LAB/reset.sh"
sections=$(python3 -c "import json; print(' '.join(s['slug'] + '.md' for s in json.load(open('lesson.json'))['sections'] if s['kind'] != 'practice'))")
# shellcheck disable=SC2086
python3 "$LAB/replay.py" --setup $sections
