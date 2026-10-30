#!/usr/bin/env bash
# The terminal sessions quoted in lesson 22 of gcp-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo WHEELS=DIR bash ../../lab.sh run captures.sh
#
# It starts where a student is after lesson 1's "Every time you open a
# terminal", with no emulator running. evening.py, by_time.py, windows.py,
# late.py, publish_evening.py and from_pubsub.py are read out of this lesson,
# so the copies run here are the ones printed.
#
# DATAFLOW IS NOT RUN. The windows, the watermark and the triggers run on Apache
# Beam's BundleBasedDirectRunner: by_time.py and windows.py in batch, late.py
# over a TestStream whose arrival order, clock and watermark are fixed in
# evening.py, so its output is the same on every run. from_pubsub.py reads the
# Pub/Sub emulator, and what it prints depends on how many messages the
# DirectRunner's first pull returns; the lesson says so.
#
# STAGED:
#   - pip has no network inside the run: apache-beam==2.76.0, as lesson 21
#     installs it, comes from WHEELS, fetched beforehand with
#     `pip download -d DIR apache-beam==2.76.0`.
#   - the Pub/Sub emulator and from_pubsub.py each run in a terminal of their
#     own for the student; here both are started in the background, the
#     pipeline with the lesson's `timeout 90`, and its terminal is printed
#     after it ends. The pause between the two halves is a `sleep 25`.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/gcp || exit 1
pip install -q apache-beam==2.76.0 || exit 1
file_fence "$HERE/two-clocks.md" evening.py > evening.py || exit 1
file_fence "$HERE/two-clocks.md" by_time.py > by_time.py || exit 1
file_fence "$HERE/three-windows.md" windows.py > windows.py || exit 1
example "$HERE/watermarks.md" late.py late.py || exit 1
file_fence "$HERE/on-dataflow.md" publish_evening.py > publish_evening.py || exit 1
file_fence "$HERE/on-dataflow.md" from_pubsub.py > from_pubsub.py || exit 1

block clocks
run 'python3 by_time.py placed | sort'
run 'python3 by_time.py arrived | sort'

block windows
run 'python3 windows.py fixed | sort'
run 'python3 windows.py sliding | sort'
run 'python3 windows.py sessions | sort'

block late
run 'python3 late.py'
block late-again
run 'python3 late.py'

block lateness
run 'python3 late.py --lateness 300'
block early
run 'python3 late.py --lateness 300 --early'
block discarding
run 'python3 late.py --lateness 300 --early --mode discarding'

block pubsub
emu_start pubsub || exit 1
run 'gcloud pubsub topics create evening'
run 'gcloud pubsub subscriptions create evening-beam --topic=evening'
( exec > pipeline-terminal.txt 2>&1; run 'timeout 90 python3 from_pubsub.py' ) &
PIPELINE=$!
sleep 12
run 'python3 publish_evening.py first'
sleep 25
run 'python3 publish_evening.py second'
wait "$PIPELINE"
block pipeline-terminal
cat pipeline-terminal.txt

block end
