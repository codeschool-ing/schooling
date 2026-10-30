#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of gcp-data (delivery guarantees),
# as a script that produces them. Every transcript in the lesson was copied
# from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# THE PROGRAMS ARE THE LESSON'S. pay.py, totals.py, sink.py and eo_check.py are
# read out of the examples in the sections that show them, and the commands
# that create the topic, the subscription and the snapshot of the-replay.md are
# that section's first ```sh fence, run as it stands. The Pub/Sub emulator and
# fake-gcs-server are started with the commands the lessons give the student,
# in the background, where the student runs each in a terminal of its own; both
# are empty when this starts.
#
# The "crash" is the program's own: totals.py ends itself with os._exit after
# the number of messages it is given, before its ack. The ack ids typed in
# where-duplicates.md are the ones the pull above them printed; the emulator
# numbers them in order, so they are the same on every run from empty. Nothing
# else is staged.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/gcp || exit 1
for p in the-replay:pay.py the-replay:totals.py idempotent-sinks:sink.py exactly-once:eo_check.py; do
  example "$HERE/${p%%:*}.md" "${p#*:}" "${p#*:}" || exit 1
done
emu_start pubsub || exit 1
emu_start gcs || exit 1

R=projects/planner-dev/subscriptions/retries
FMT="--format='table(message.messageId:label=ID,message.attributes.order_id:label=ORDER,ackId)'"
block retry
run 'gcloud pubsub topics create retries'
run 'gcloud pubsub subscriptions create retries --topic=retries'
for _ in 1 2; do
  run "gcloud pubsub topics publish retries --message='{\"order_id\": \"o-301\", \"cents\": 4590}' --attribute=order_id=o-301"
done
run "gcloud pubsub subscriptions pull retries --limit=10 $FMT"
block deadline
run "time gcloud pubsub subscriptions pull retries --limit=10 $FMT"
run "gcloud pubsub subscriptions modify-message-ack-deadline retries --ack-ids=$R:${A3:-3},$R:${A4:-4} --ack-deadline=60"
run "timeout 20 gcloud pubsub subscriptions pull retries --limit=10 $FMT; echo \"exit \$?\""
run "gcloud pubsub subscriptions ack retries --ack-ids=$R:${A3:-3},$R:${A4:-4}"
run 'gcloud pubsub subscriptions pull retries --limit=10'

bash -e <(fence "$HERE/the-replay.md" 1) > /dev/null 2>&1 || exit 1
DB="python3 -c \"import sqlite3; print(sqlite3.connect('totals.db').execute('SELECT * FROM totals ORDER BY 1').fetchall())\""
block pay
run 'python3 pay.py'
block plain
run 'python3 totals.py plain 4'
run 'python3 totals.py plain'
run 'sleep 10; python3 totals.py plain'
run "$DB"
for m in by-message-id by-order-id; do
  block "$m"
  run 'rm totals.db && gcloud pubsub subscriptions seek totals --snapshot=totals-start'
  run "python3 totals.py $m 4"
  run "sleep 10; python3 totals.py $m"
  run "$DB"
done
block again
run 'gcloud pubsub subscriptions seek totals --snapshot=totals-start && python3 totals.py by-order-id'
run "python3 -c \"import sqlite3; db = sqlite3.connect('totals.db'); print(db.execute('SELECT * FROM totals ORDER BY 1').fetchall(), db.execute('SELECT count(*) FROM processed').fetchone())\""

block sink
run 'python3 sink.py add c-08 500'
run 'python3 sink.py add c-08 500'
run 'python3 sink.py put c-09 500'
run 'python3 sink.py put c-09 500'
block objects
run 'gcloud storage buckets create gs://quitanda-raw-prod --location=southamerica-east1'
run "printf '%s\\n' '{\"order_id\": \"o-301\", \"cents\": 4590}' '{\"order_id\": \"o-302\", \"cents\": 12800}' > batch.json"
for _ in 1 2; do
  run 'gcloud storage cp batch.json gs://quitanda-raw-prod/raw/payments-by-time/$(date +%s%N).json'
done
for _ in 1 2; do
  run 'gcloud storage cp batch.json gs://quitanda-raw-prod/raw/payments-by-content/$(sha256sum batch.json | cut -c1-16).json'
done
run 'gcloud storage ls gs://quitanda-raw-prod/raw/**'

block eo
run 'gcloud pubsub topics create receipts'
run 'gcloud pubsub subscriptions create receipts-plain --topic=receipts'
run 'gcloud pubsub subscriptions create receipts-once --topic=receipts --enable-exactly-once-delivery'
run "gcloud pubsub subscriptions describe receipts-once --format='value(enableExactlyOnceDelivery)'"
run "gcloud pubsub topics publish receipts --message='{\"order_id\": \"o-307\", \"cents\": 3100}'"
run 'python3 eo_check.py receipts-plain'
run 'python3 eo_check.py receipts-once'
block eodup
run "gcloud pubsub topics publish receipts --message='{\"order_id\": \"o-308\", \"cents\": 2750}' && gcloud pubsub topics publish receipts --message='{\"order_id\": \"o-308\", \"cents\": 2750}'"
run "gcloud pubsub subscriptions pull receipts-once --auto-ack --limit=10 --format='table(message.messageId:label=ID,message.data.decode(base64).decode(utf-8):label=DATA)'"

block end
