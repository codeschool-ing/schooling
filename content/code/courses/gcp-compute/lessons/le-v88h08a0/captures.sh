#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of gcp-compute, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lab.sh tools                   # once, beside course.json
#   bash lessons/le-v88h08a0/captures.sh
#
# Runs in the lab's own network namespace: gunicorn and curl talk over
# loopback, and nothing reaches Google. curl stands in for Cloud Tasks and is
# named as curl in the lesson; the X-CloudTasks-* headers it sends are the ones
# Google documents, and the task names and orders are made up.
#
# What is STAGED rather than typed:
#   - the "second terminal": gunicorn is started in the background on port
#     8082; `gunicorn` prints the command the lesson gives and that terminal's
#     log, and `gunicorn-log` the lines the mailer printed afterwards;
#   - prices.py is read out of lesson 1's section `the-price-sheet`;
#   - `terraform init`, whose output lesson 1 shows, runs quietly with a plugin
#     cache of the run's own (TF_PLUGIN_CACHE_DIR);
#   - main.py, backoff.py and the two main.tf are read out of this lesson's
#     blocks.
#
# Recorded 2026-10-30 on Ubuntu 24.04, no Google Cloud account,
# TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

export TF_PLUGIN_CACHE_DIR=~/gcp/.tfcache; mkdir -p "$TF_PLUGIN_CACHE_DIR"

block plan-queue
mkdir -p tasks && cd tasks || exit 1
from_lesson "$HERE/queues.md" tasks/main.tf > main.tf
quiet 'terraform init'
run "terraform plan -no-color | grep -E '^  #|max_dispatches|max_concurrent|max_attempts|min_backoff|max_backoff|max_doublings|^Plan'"
cd .. || exit 1

mkdir -p mailer && cd mailer || exit 1
from_example "$HERE/the-task-handler.md" main.py > main.py
gunicorn -b :8082 main:app > gunicorn.log 2>&1 & G=$!
for _ in $(seq 80); do curl -s -o /dev/null localhost:8082 && break; sleep 0.25; done
block gunicorn
shown 'gunicorn -b :8082 main:app' 'cat gunicorn.log'
block deliver
run "curl -s -w '%{http_code}\\n' localhost:8082/send -H 'X-CloudTasks-QueueName: emails' -H 'X-CloudTasks-TaskName: order-1042-confirmation' -H 'X-CloudTasks-TaskRetryCount: 0' -H 'content-type: application/json' -d '{\"order\": 1042, \"email\": \"ana@example.com\"}'"
run "curl -s -w '%{http_code}\\n' localhost:8082/send -H 'X-CloudTasks-QueueName: emails' -H 'X-CloudTasks-TaskName: order-1042-confirmation' -H 'X-CloudTasks-TaskRetryCount: 1' -H 'content-type: application/json' -d '{\"order\": 1042, \"email\": \"ana@example.com\"}'"
sleep 1
block gunicorn-log
grep -v '^\[' gunicorn.log
block failures
run "curl -s -w '%{http_code}\\n' localhost:8082/send -H 'X-CloudTasks-QueueName: emails' -H 'X-CloudTasks-TaskName: order-1043-confirmation' -H 'X-CloudTasks-TaskRetryCount: 0' -H 'content-type: application/json' -d '{\"order\": 1043, \"email\": \"bo@down.example\"}'"
run "curl -s -w '%{http_code}\\n' localhost:8082/send -H 'X-CloudTasks-QueueName: emails' -H 'X-CloudTasks-TaskName: order-1043-confirmation' -H 'X-CloudTasks-TaskRetryCount: 1' -H 'content-type: application/json' -d '{\"order\": 1043, \"email\": \"bo@down.example\"}'"
run "curl -s -w '%{http_code}\\n' localhost:8082/send -H 'content-type: application/json' -d '{\"order\": 1044, \"email\": \"cy@example.com\"}'"
kill "$G"; wait "$G" 2>/dev/null
cd .. || exit 1

from_example "$HERE/retries-and-rates.md" backoff.py > backoff.py
block backoff
run 'python3 backoff.py'
block backoff-5
run 'python3 backoff.py 10 300 3 5'

block plan-scheduler
mkdir -p scheduler && cd scheduler || exit 1
from_lesson "$HERE/scheduler.md" scheduler/main.tf > main.tf
quiet 'terraform init'
run "terraform plan -no-color | grep -E '^  #|schedule |time_zone|uri|http_method|retry_count|^Plan'"
cd .. || exit 1

from_example "$HERE/../le-0wj8wcjn/the-price-sheet.md" prices.py > prices.py
block prices
run "python3 prices.py other | grep Scheduler"
