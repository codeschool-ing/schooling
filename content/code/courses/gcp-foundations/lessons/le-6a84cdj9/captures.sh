#!/usr/bin/env bash
# The terminal sessions quoted in lesson 24 of gcp-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/gcplab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# Runs in the lab lesson 1 built (../../from-lessons.sh says how), against an
# empty emulator, with lesson 9's ~/gcp/federation/credentials.json in place.
# publish.py is read out of the example in "client-libraries".
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson: nothing.
#
# REACHES GOOGLE: the block `google`, which sends the placeholder token to the
# Pub/Sub API with curl, and the block `adc`, whose program looks for Google's
# credentials (it finds none, and asks no server) and for the file lesson 9's
# federation names (it is not on a laptop). Both are refused or stop.
#
# NOT PRODUCED HERE, and said so in the prose: any credential that works, the
# metadata server, and a publish to Google.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
pubsub_fresh
cd ~/gcp && at '~/gcp'
[ -f ~/gcp/federation/credentials.json ] || { echo 'lesson 9 first: ~/gcp/federation/credentials.json'; exit 1; }

block loghttp
run "gcloud pubsub topics create orders --log-http 2>&1 | sed -n '/^uri:/p;/^method:/p;/^== body start/,/^== body end/p;/^status:/p;/^-- body start/,/^-- body end/p'"
block subscription
run "curl -s -X PUT http://localhost:8085/v1/projects/planner-dev/subscriptions/orders-sub -H 'Content-Type: application/json' -d '{\"topic\": \"projects/planner-dev/topics/orders\"}'"
block google
run 'curl -s https://pubsub.googleapis.com/v1/projects/planner-dev/topics -H "Authorization: Bearer $(cat ~/gcp/placeholder-token)"'

example "$HERE/client-libraries.md" publish.py > publish.py || exit 1
block publish
run 'python3 publish.py'
run "curl -s -X POST http://localhost:8085/v1/projects/planner-dev/subscriptions/orders-sub:pull -H 'Content-Type: application/json' -d '{\"maxMessages\": 10}' | jq -c '.receivedMessages[].message | {id: .messageId, data: (.data | @base64d), attributes}'"

block adc
run 'env -u PUBSUB_EMULATOR_HOST python3 publish.py 2>&1 | tail -1'
block found
run "GOOGLE_APPLICATION_CREDENTIALS=~/gcp/federation/credentials.json python3 -c 'import google.auth; c, p = google.auth.default(); print(type(c).__module__, type(c).__name__, p)'"
block federated
run 'env -u PUBSUB_EMULATOR_HOST GOOGLE_APPLICATION_CREDENTIALS=~/gcp/federation/credentials.json python3 publish.py 2>&1 | tail -1'
