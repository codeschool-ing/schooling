#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of gcp-compute, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lab.sh tools                                   # once, beside course.json
#   LAB_HOSTS=1 bash lessons/le-n59nt1ev/captures.sh
#
# LAB_HOSTS=1 because the Pub/Sub emulator runs on the machine's own network
# (--network host) and pushes to a function on localhost. Nothing here reaches
# Google: the function, the emulator and curl are all on this machine.
#
# What is STAGED rather than typed:
#   - the "second terminal": each functions-framework is started in the
#     background by this script, and its block (ff-*) prints the command the
#     lesson tells the student to type there followed by what that terminal
#     printed, read from its log;
#   - the script waits for the framework and the emulator to answer before the
#     first command that needs them, as a person would wait;
#   - `terraform init`, whose output lesson 1 shows, runs quietly, with a
#     plugin cache of the run's own (TF_PLUGIN_CACHE_DIR) so that it never
#     collides with another run using the shared one;
#   - main.py, notify/main.py, orders-events/main.py, pubsub.py and main.tf
#     are read out of the lesson's own blocks.
#
# Recorded 2026-10-30 on Ubuntu 24.04, no Google Cloud account,
# TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

wait_port() { for _ in $(seq 80); do curl -s -o /dev/null "localhost:$1" && return 0; sleep 0.25; done; return 1; }
ff_start() { functions-framework "$@" > ff.log 2>&1 & FF=$!; wait_port 8080; }
ff_stop() { kill "$FF" 2>/dev/null; wait "$FF" 2>/dev/null; }
quiet 'docker rm -f pubsub'

mkdir -p quote && cd quote || exit 1
from_example "$HERE/http-functions.md" main.py > main.py
ff_start --target quote
block ff-quote
shown 'functions-framework --target quote' 'cat ff.log'
block quote
run "curl -s -w '%{http_code}\\n' -X POST localhost:8080 -H 'content-type: application/json' -d '{\"items\": [{\"sku\": \"mug\", \"qty\": 2}, {\"sku\": \"tee\", \"qty\": 1}]}'"
run "curl -s -w '%{http_code}\\n' localhost:8080"
run "curl -s -w '%{http_code}\\n' -X POST localhost:8080 -H 'content-type: application/json' -d '{\"items\": [{\"sku\": \"hat\", \"qty\": 1}]}'"
ff_stop
cd .. || exit 1

mkdir -p notify && cd notify || exit 1
from_lesson "$HERE/event-functions.md" notify/main.py > main.py
ff_start --target on_event --signature-type cloudevent
block ff-notify
shown 'functions-framework --target on_event --signature-type cloudevent' 'cat ff.log'
block notify
run "curl -s -w ' %{http_code}\\n' localhost:8080 -H 'ce-specversion: 1.0' -H 'ce-type: shop.order.created' -H 'ce-source: //shop/web' -H 'ce-id: 7f3e-1042' -H 'content-type: application/json' -d '{\"order\": 1042, \"total_cents\": 14900}'"
run "curl -s -o /dev/null -w '%{http_code}\\n' localhost:8080 -H 'ce-specversion: 1.0' -H 'ce-type: shop.order.created' -H 'ce-source: //shop/web' -H 'content-type: application/json' -d '{\"order\": 1043}'"
sleep 1
block ff-notify-log
cat ff.log
ff_stop
cd .. || exit 1

block emulator
run 'docker run -d --name pubsub --network host gcr.io/google.com/cloudsdktool/google-cloud-cli:591.0.0-emulators gcloud beta emulators pubsub start --host-port=0.0.0.0:8085 --project=planner-dev'
for _ in $(seq 80); do curl -s -o /dev/null localhost:8085 && break; sleep 0.5; done
from_example "$HERE/pubsub-trigger.md" pubsub.py > pubsub.py
export PUBSUB_EMULATOR_HOST=localhost:8085
mkdir -p orders-events && cd orders-events || exit 1
from_lesson "$HERE/pubsub-trigger.md" orders-events/main.py > main.py
ff_start --target on_order --signature-type cloudevent
block ff-orders
shown 'functions-framework --target on_order --signature-type cloudevent' 'cat ff.log'
cd .. || exit 1
block chain
run 'python3 pubsub.py topic orders'
run 'python3 pubsub.py push orders-fn orders http://localhost:8080/'
run 'python3 pubsub.py publish orders 1042 source=web'
sleep 3
block ff-orders-log
cat orders-events/ff.log
ff_stop
quiet 'docker rm -f pubsub'

block plan
mkdir -p functions && cd functions || exit 1
from_lesson "$HERE/generations-and-limits.md" functions/main.tf > main.tf
export TF_PLUGIN_CACHE_DIR=~/gcp/.tfcache; mkdir -p "$TF_PLUGIN_CACHE_DIR"
quiet 'terraform init'
run "terraform plan -no-color | grep -E '^  #|runtime|entry_point|available_memory|timeout_seconds|max_instance_count|  \\+ (uri|url) |^Plan'"
