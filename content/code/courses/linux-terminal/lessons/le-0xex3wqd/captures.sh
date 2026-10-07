#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of linux-terminal, replayed.
#
# THE AUTHOR'S TOOL; the loader reads none of it. Every transcript in this lesson
# was captured on an Ubuntu 24.04 cloud image under QEMU, because the lesson is
# about cron and systemd and the capture machine of lessons 1 to 12 runs neither:
# ../../lab/replay.py logs in there by ssh (REPLAY_SSH is the ssh command; ana and
# root accept its key) and types each transcript into a real bash.
#
# The guest had what the lesson tells the student to install: anacron, at and
# postfix ("Local only"), and shellcheck from lesson 9. --setup-home runs the
# blocks that write each script, crontab file and unit file, install them, and
# wait for cron to run them; the waits are in the blocks, as the student's are.
#
#   REPLAY_SSH="ssh -p 2222 -i key" bash captures.sh
#
# Start from an account with no crontab, no ~/work, ~/bin or ~/srv, an empty
# /var/mail/ana, no at jobs and no report.timer installed. Expected to differ:
# every time, date, PID and message id, and the counts of mail, which grow by one
# a minute for each broken job while it is installed.
set -euo pipefail
cd "$(dirname "$0")"
LAB=../../lab
sections=$(python3 -c "import json; print(' '.join(s['slug'] + '.md' for s in json.load(open('lesson.json'))['sections'] if s['kind'] != 'practice'))")
# shellcheck disable=SC2086
python3 "$LAB/replay.py" --setup-home $sections
