#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of gcp-data (Pub/Sub), as a script
# that produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# THE PROGRAMS ARE THE LESSON'S. events.py, subscriber.py, receiver.py,
# ordered.py, redeliver.py, billing_worker.py and bill.py are read out of the
# examples in the sections that show them. The Pub/Sub emulator is started with
# the command topics-and-subscriptions.md gives the student, in the background,
# where the student runs it in a terminal of its own; it is empty when this
# starts, and one emulator serves the whole lesson, in the order of the
# sections.
#
# STAGED: receiver.py is started in the background with `&`, as the lesson tells
# the student to; the student stops it with `kill %1`, which a fresh shell per
# command cannot do, so it is stopped here with pkill and nothing is printed.
# The pause of a few seconds before `cat push.log` is the capture's own sleep.
# The ack id typed in pull-and-push.md is the one the pull above it printed;
# the emulator numbers ack ids in order, so it is the same on every run from
# empty.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/gcp || exit 1
for p in topics-and-subscriptions:events.py pull-and-push:subscriber.py pull-and-push:receiver.py \
         ordering-keys:ordered.py ordering-keys:redeliver.py \
         dead-letters-and-replay:billing_worker.py emulator-and-bill:bill.py; do
  example "$HERE/${p%%:*}.md" "${p#*:}" "${p#*:}" || exit 1
done
emu_start pubsub || exit 1

FMT="--format='table(message.messageId:label=ID,message.attributes.type:label=TYPE,message.attributes.customer_id:label=CUSTOMER)'"
block topics
run 'gcloud pubsub topics create app-events'
run "gcloud pubsub subscriptions create billing --topic=app-events --message-filter='attributes.type = \"payment\"'"
run 'gcloud pubsub subscriptions create analytics --topic=app-events'
run 'gcloud pubsub subscriptions describe analytics'
run 'python3 events.py'
run "gcloud pubsub subscriptions pull analytics --auto-ack --limit=20 $FMT"
run "gcloud pubsub subscriptions pull billing --auto-ack --limit=20 $FMT"
run 'gcloud pubsub subscriptions pull analytics --auto-ack --limit=20'
block late
run 'gcloud pubsub subscriptions create fraud --topic=app-events'
run 'gcloud pubsub subscriptions pull fraud --auto-ack --limit=20'
run 'gcloud pubsub subscriptions delete fraud'

block pull
run 'python3 events.py > /dev/null'
run "gcloud pubsub subscriptions pull analytics --limit=2 --format='table(message.messageId:label=ID,message.attributes.type:label=TYPE,ackId)'"
run "gcloud pubsub subscriptions ack analytics --ack-ids=${ACKID:-projects/planner-dev/subscriptions/analytics:11}"
block stream
run 'python3 subscriber.py analytics'
block push
run 'gcloud pubsub subscriptions create pushed --topic=app-events --push-endpoint=http://localhost:8099/'
run 'python3 receiver.py > push.log 2>&1 &'
run "gcloud pubsub topics publish app-events --message='{\"order_id\": \"o-303\", \"cents\": 990}' --attribute=type=payment,customer_id=c-17"
sleep 5
run 'cat push.log'
run 'gcloud pubsub subscriptions delete pushed'
pkill -f receiver.py

block order
run 'gcloud pubsub topics create order-status'
run 'gcloud pubsub subscriptions create status-ordered --topic=order-status --enable-message-ordering'
run 'gcloud pubsub subscriptions create status-any --topic=order-status'
run 'python3 ordered.py'
run "gcloud pubsub subscriptions pull status-any --auto-ack --limit=20 --format='table(message.messageId:label=ID,message.orderingKey:label=KEY,message.data.decode(base64).decode(utf-8):label=DATA)'"
run 'python3 redeliver.py status-ordered'
run "python3 -c \"from google.cloud import pubsub_v1; p = pubsub_v1.PublisherClient(); p.publish(p.topic_path('planner-dev', 'order-status'), b'x', ordering_key='c-17')\" 2>&1 | tail -1"

block dlq
run 'gcloud pubsub subscriptions update billing --dead-letter-topic=app-events-dead --max-delivery-attempts=5'
run 'gcloud pubsub topics create app-events-dead'
run 'gcloud pubsub subscriptions update billing --dead-letter-topic=app-events-dead --max-delivery-attempts=3 2>&1 | head -1'
run 'gcloud pubsub subscriptions update billing --dead-letter-topic=app-events-dead --max-delivery-attempts=5'
run 'gcloud pubsub subscriptions create billing-dead --topic=app-events-dead'
run "gcloud pubsub topics publish app-events --message='{\"order_id\": \"o-304\", \"cents\": \"23,50\"}' --attribute=type=payment,customer_id=c-05"
run 'python3 billing_worker.py'
run "gcloud pubsub subscriptions pull billing-dead --auto-ack --format='yaml(message.data.decode(base64).decode(utf-8),message.attributes)'"
block seek
run 'gcloud pubsub subscriptions update analytics --retain-acked-messages'
run 'python3 events.py > /dev/null && python3 subscriber.py analytics'
run 'python3 subscriber.py analytics'
run "gcloud pubsub subscriptions seek analytics --time=\$(date -d '10 minutes ago' -Iseconds)"
run 'python3 subscriber.py analytics | wc -l'
block snapshot
run 'gcloud pubsub snapshots create analytics-before-deploy --subscription=analytics'
run 'python3 events.py > /dev/null && python3 subscriber.py analytics | wc -l'
run 'gcloud pubsub subscriptions seek analytics --snapshot=analytics-before-deploy'
run 'python3 subscriber.py analytics | wc -l'
block topicret
run 'gcloud pubsub topics update app-events --message-retention-duration=7d'
run 'gcloud pubsub topics describe app-events'

block weak
run 'gcloud pubsub subscriptions describe billing'
run "gcloud pubsub subscriptions create quick --topic=app-events --ack-deadline=5 && gcloud pubsub subscriptions describe quick --format='value(ackDeadlineSeconds)'"
run 'gcloud pubsub subscriptions create billing-retry --topic=app-events --min-retry-delay=20s --max-retry-delay=60s'
run "gcloud pubsub topics publish app-events --message=retry-me > /dev/null && A=\$(gcloud pubsub subscriptions pull billing-retry --format='value(ackId)') && gcloud pubsub subscriptions modify-message-ack-deadline billing-retry --ack-ids=\$A --ack-deadline=0 > /dev/null 2>&1 && time gcloud pubsub subscriptions pull billing-retry --format='value(message.data)'"
run "gcloud pubsub topics create kept --message-retention-duration=1d && gcloud pubsub topics publish kept --message=before > /dev/null && gcloud pubsub subscriptions create kept-late --topic=kept && gcloud pubsub subscriptions pull kept-late --auto-ack --format='value(message.data)'"
run 'gcloud pubsub subscriptions create to-warehouse --topic=app-events --bigquery-table=planner-dev:quitanda.app_events'
run "gcloud pubsub subscriptions describe to-warehouse --format='yaml(bigqueryConfig,state)'"
run "gcloud pubsub topics publish app-events --message=to-the-warehouse > /dev/null && gcloud pubsub subscriptions pull to-warehouse --auto-ack --format='value(message.data)'"
block expiry
run 'gcloud pubsub topics create ten-minutes && gcloud pubsub subscriptions create ten-minutes --topic=ten-minutes --message-retention-duration=10m && gcloud pubsub topics publish ten-minutes --message=old'
[ -n "${QUICK:-}" ] || run "sleep 660; gcloud pubsub subscriptions pull ten-minutes --auto-ack --format='value(message.data)'"
block bill
run 'python3 bill.py'

block end
