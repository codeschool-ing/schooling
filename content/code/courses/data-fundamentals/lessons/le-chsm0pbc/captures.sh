#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of data-fundamentals, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash ../../lab.sh image          # once
#   bash captures.sh > out.txt
#   python3 ../../lab/splice.py . out.txt
#
# The machine is the one lesson 1 builds: ~/roda with its .venv, TZ set by
# ~/.bashrc. The lesson works in ~/roda/shapes. The six programs it runs
# (structured.py, loose.py, events.py, flatten.py, drift.py, emails.py) are read
# out of the lesson's sections by lab/extract.py, so the program run is the
# program printed.
#
# STAGED rather than typed: ~/roda/shapes already exists and holds the six
# programs when the script starts, because extract.py writes them there; the
# student makes the directory with the `mkdir` in section `structured` and
# saves each file by hand. Everything else, including rides.csv and the two
# rides-*.jsonl files, is written by the programs during the run.
#
# Recorded on Ubuntu 24.04, Python 3.12.3, pyarrow 26.0.0, fastavro 1.13.1,
# TZ=America/Sao_Paulo, on 2026-10-10.
set -uo pipefail
cd "$(dirname "$0")"
LAB=../../lab.sh

bash $LAB run le-chsm0pbc <<'S'
cd shapes

block structured
on 'python structured.py'

block loose
on 'python loose.py'

block events
on 'python events.py'
on 'head -1 rides-2025-09-15.jsonl | python -m json.tool'

block optional
on "grep -c '\"end\"' rides-2025-09-15.jsonl"
on 'grep -c coupon rides-2025-09-15.jsonl'

block flatten
on 'python flatten.py rides-2025-09-15.jsonl'

block drift
on 'python drift.py rides-2025-09-15.jsonl rides-2025-09-16.jsonl'

block emails
on 'python emails.py'
S
