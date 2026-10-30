#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of gcp-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo WHEELS=DIR bash ../../lab.sh run captures.sh
#
# It starts where a student is after lesson 1's "Every time you open a
# terminal", with no emulator running. events.py, orders_beam.py, publish.py
# and dataflow_bill.py are read out of this lesson, so the copies run here are
# the ones printed.
#
# DATAFLOW IS NOT RUN: there is no emulator for it. The pipeline runs on Apache
# Beam's BundleBasedDirectRunner, inside Python, in batch over a file and in
# streaming over the Pub/Sub emulator. The DataflowRunner commands of the
# section on-dataflow are shown in the lesson and never run anywhere.
#
# STAGED:
#   - pip has no network inside the run: apache-beam==2.76.0 and its
#     dependencies were fetched beforehand with
#     `pip download -d DIR apache-beam==2.76.0` and are installed from WHEELS.
#   - the Pub/Sub emulator and the streaming pipeline each run in a terminal of
#     their own for the student; here both are started in the background, the
#     emulator with the command the lesson gives and the pipeline with its
#     `timeout 120`, and the pipeline's terminal is printed after it ends.
#   - the run has no route to GitHub, which is what the logged attempt to
#     download Prism shows.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/gcp || exit 1
file_fence "$HERE/the-pipeline.md" events.py > events.py || exit 1
example "$HERE/the-pipeline.md" orders_beam.py orders_beam.py || exit 1
file_fence "$HERE/in-stream.md" publish.py > publish.py || exit 1
file_fence "$HERE/the-bill.md" dataflow_bill.py > dataflow_bill.py || exit 1

block install
run 'pip install -q apache-beam==2.76.0'
run 'python3 -c "import apache_beam; print(apache_beam.__version__)"'
run "pip list 2>/dev/null | grep -E '^protobuf '"

block prism
run 'python3 -c "import logging,apache_beam as beam; logging.basicConfig(level=logging.INFO); p=beam.Pipeline(); p|beam.Create([1])|beam.Map(print); p.run().wait_until_finish()" 2>&1 | head -20'

block events
run 'python3 events.py'
run 'head -2 events.jsonl'

block batch
run 'time python3 orders_beam.py --input events.jsonl --output out/'
run 'ls out/'
run 'sort out/totals-*'
run 'cat out/unreadable-*'

block topics
emu_start pubsub || exit 1
run 'gcloud pubsub topics create order-events order-totals order-totals-unreadable'
run 'gcloud pubsub subscriptions create order-events-beam --topic=order-events'
run 'gcloud pubsub subscriptions create order-totals-check --topic=order-totals'
run 'gcloud pubsub subscriptions create order-totals-unreadable-check --topic=order-totals-unreadable'

block nowindow
run 'timeout 60 python3 orders_beam.py --subscription order-events-beam --topic order-totals --streaming --window 0 2>&1 | tail -1'

block stream
( exec > stream-terminal.txt 2>&1; run 'timeout 120 python3 orders_beam.py --subscription order-events-beam --topic order-totals --streaming' ) &
STREAM=$!
sleep 15
run 'python3 publish.py'
sleep 70
run "gcloud pubsub subscriptions pull order-totals-check --auto-ack --limit=20 --format='value(message.data)' | sort"
run "gcloud pubsub subscriptions pull order-totals-unreadable-check --auto-ack --limit=5 --format='value(message.data)'"
wait "$STREAM"
block stream-terminal
cat stream-terminal.txt

block bill
run 'python3 dataflow_bill.py'

block end
