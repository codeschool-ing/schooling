#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of data-fundamentals, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash ../../lab.sh image          # once
#   bash captures.sh > out.txt
#   python3 ../../lab/splice.py . out.txt
#
# The machine is the one lesson 1, section `the-lab`, builds. The programs in
# ~/roda/stream are read out of this lesson's sections by lab/extract.py, so
# the program run is the program printed: sensors.py (`bounded-and-unbounded`),
# daily.py (`batch`), consumer.py (`stream`), lateness.py
# (`event-time-and-processing-time`), windows.py (`windows`), watermark.py
# (`late-data-and-watermarks`) and keyed.py (`delivery-guarantees`).
#
# STAGED rather than typed: nothing on the machine. What is staged is in the
# data, and the lesson says so: sensors.py plants two outages (ST08's link down
# on Monday from 08:20 to 08:51:30, ST04's from 09:20 until 07:02 on Tuesday),
# and `daily.py DAY ASOF` makes a job see only what had arrived by ASOF, which
# is how a run at 01:00 on Tuesday is reproduced on a file that already holds
# Tuesday. `consumer.py --crash` and `keyed.py --crash` stop the program at the
# point a crash would, between writing the result and committing the offset.
# The consumer is stopped after each run rather than left waiting, so the
# offset can be read between runs.
#
# Recorded on Ubuntu 24.04, Python 3.12.3, pyarrow 26.0.0, fastavro 1.13.1,
# TZ=America/Sao_Paulo, on 2026-10-10.
set -uo pipefail
cd "$(dirname "$0")"
LAB=../../lab.sh

bash $LAB run le-dffrs4pp <<'S'
cd stream

block make
on 'python sensors.py'
on 'head -3 docks.jsonl'

block batch-first
on 'python daily.py 2025-10-06 "2025-10-07 01:00"'
on 'cp daily-2025-10-06.csv first-run.csv'

block backfill
on 'for day in 2025-10-06 2025-10-07 2025-10-08; do python daily.py $day; done'
on 'diff first-run.csv daily-2025-10-06.csv'

block consume
on 'python consumer.py 300'
on 'python consumer.py 300'
on 'cat offset.txt'
on 'python consumer.py 300'
on 'python consumer.py 300'

block lateness
on 'python lateness.py'

block windows
on 'python windows.py'

block watermark
on 'python watermark.py 2'
on 'python watermark.py 25'

block crash
on 'rm offset.txt rides.json'
on 'python consumer.py 300'
on 'python consumer.py 300 --crash'
on 'python consumer.py 300'
on 'python consumer.py 300'

block keyed
on 'python keyed.py 300'
on 'python keyed.py 300 --crash'
on 'python keyed.py 300'
on 'python keyed.py 300'
S
