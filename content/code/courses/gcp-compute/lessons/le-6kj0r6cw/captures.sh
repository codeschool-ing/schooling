#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of gcp-compute, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lab.sh tools                                   # once, beside course.json
#   LAB_HOSTS=1 bash lessons/le-6kj0r6cw/captures.sh
#
# LAB_HOSTS=1 because the Pub/Sub emulator and fake-gcs-server run on the
# machine's own network (--network host), and a push reaches a function on
# localhost. Nothing here reaches Google.
#
# What is STAGED rather than typed:
#   - the "second terminal": each functions-framework is started in the
#     background by this script; its ff-* block prints the command the lesson
#     tells the student to type there and then that terminal's log;
#   - in `ff-flaky` the prompt and the command are printed and the command
#     runs in the background, as the student's second terminal would run it;
#   - the script waits for each emulator and the framework to answer before
#     the first command that needs them, and sleeps the ten seconds the lesson
#     asks the student to wait;
#   - `terraform init`, whose output lesson 1 shows, runs quietly with a plugin
#     cache of the run's own (TF_PLUGIN_CACHE_DIR);
#   - pubsub.py is read out of lesson 17's section `pubsub-trigger`; main.tf
#     and the two main.py out of this lesson's blocks.
#
# fake-gcs-server 1.56.1 is an open-source imitation of Cloud Storage; the
# notifications it publishes follow Google's documented format.
#
# Recorded 2026-10-30 on Ubuntu 24.04, no Google Cloud account,
# TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

wait_url() { for _ in $(seq 120); do curl -s -o /dev/null "$1" && return 0; sleep 0.25; done; return 1; }
ff_start() { functions-framework "$@" > ff.log 2>&1 & FF=$!; wait_url localhost:8080; }
ff_stop() { kill "$FF" 2>/dev/null; wait "$FF" 2>/dev/null; }
quiet 'docker rm -f pubsub gcs'
from_example "$HERE/../le-n59nt1ev/pubsub-trigger.md" pubsub.py > pubsub.py

block plan
mkdir -p eventarc && cd eventarc || exit 1
from_lesson "$HERE/triggers.md" eventarc/main.tf > main.tf
export TF_PLUGIN_CACHE_DIR=~/gcp/.tfcache; mkdir -p "$TF_PLUGIN_CACHE_DIR"
quiet 'terraform init'
run "terraform plan -no-color | grep -E '^  #|attribute|value|service +=|region +=|service_account|transport|^Plan'"
cd .. || exit 1

block start-pubsub
run 'docker run -d --name pubsub --network host gcr.io/google.com/cloudsdktool/google-cloud-cli:591.0.0-emulators gcloud beta emulators pubsub start --host-port=0.0.0.0:8085 --project=planner-dev'
wait_url localhost:8085
run 'export PUBSUB_EMULATOR_HOST=localhost:8085'
run 'python3 pubsub.py topic photo-uploads'
block start-gcs
run 'docker run -d --name gcs --network host -e PUBSUB_EMULATOR_HOST=localhost:8085 fsouza/fake-gcs-server:1.56.1 -scheme http -port 4443 -backend memory -event.pubsub-project-id planner-dev -event.pubsub-topic photo-uploads -event.list finalize,delete'
wait_url localhost:4443/storage/v1/b

mkdir -p thumbnails && cd thumbnails || exit 1
from_lesson "$HERE/storage-events.md" thumbnails/main.py > main.py
ff_start --target on_upload --signature-type cloudevent
block ff-thumbnails
shown 'functions-framework --target on_upload --signature-type cloudevent' 'cat ff.log'
cd .. || exit 1
block subscribe
run 'python3 pubsub.py push thumbnails photo-uploads http://localhost:8080/'
block upload
run "curl -s -X POST 'localhost:4443/storage/v1/b?project=planner-dev' -H 'content-type: application/json' -d '{\"name\": \"shop-photos\"}' | jq -r .name"
run 'head -c 48213 /dev/urandom > 1042.jpg'
run "curl -s -X POST --data-binary @1042.jpg -H 'content-type: image/jpeg' 'localhost:4443/upload/storage/v1/b/shop-photos/o?uploadType=media&name=products/1042.jpg' | jq -r '.name, .size'"
run "curl -s -o /dev/null -w '%{http_code}\\n' -X DELETE localhost:4443/storage/v1/b/shop-photos/o/products%2F1042.jpg"
sleep 3
block ff-thumbnails-log
cat thumbnails/ff.log
ff_stop
quiet 'docker rm -f gcs pubsub'

mkdir -p flaky && cd flaky || exit 1
from_lesson "$HERE/delivery-and-retries.md" flaky/main.py > main.py
functions-framework --target flaky --signature-type cloudevent > ~/gcp/flaky.log 2>&1 & FF=$!
wait_url localhost:8080
block ff-flaky
prompt 'functions-framework --target flaky --signature-type cloudevent > ~/gcp/flaky.log 2>&1'
cd .. || exit 1
block flaky
run 'docker run -d --name pubsub --network host gcr.io/google.com/cloudsdktool/google-cloud-cli:591.0.0-emulators gcloud beta emulators pubsub start --host-port=0.0.0.0:8085 --project=planner-dev'
wait_url localhost:8085
run 'python3 pubsub.py topic orders'
run 'python3 pubsub.py push flaky orders http://localhost:8080/'
run 'python3 pubsub.py publish orders 1042'
sleep 10
block count
run "grep -c 'delivery of message 1' flaky.log"
run "grep -m 3 -A 1 'delivery of message 1' flaky.log"
ff_stop
quiet 'docker rm -f pubsub'
