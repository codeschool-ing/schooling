#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of gcp-compute, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lab.sh tools                   # once, beside course.json
#   bash lessons/le-z84dr3j1/captures.sh
#
# Runs in the lab's own network namespace: gunicorn and curl talk over
# loopback, and nothing reaches Google.
#
# What is STAGED rather than typed:
#   - the "second terminal": gunicorn is started in the background with
#     PORT=8081; the `gunicorn` block prints the command the lesson tells the
#     student to type there and then what that terminal printed, from its log.
#     Its timestamps and process ids are this run's;
#   - prices.py is read out of lesson 1's section `the-price-sheet`;
#   - `terraform init`, whose output lesson 1 shows, runs quietly with a plugin
#     cache of the run's own (TF_PLUGIN_CACHE_DIR);
#   - main.py, app.yaml and main.tf are read out of this lesson's blocks.
#
# Recorded 2026-10-30 on Ubuntu 24.04, no Google Cloud account,
# TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

from_example "$HERE/../le-0wj8wcjn/the-price-sheet.md" prices.py > prices.py
mkdir -p storefront && cd storefront || exit 1
from_lesson "$HERE/standard.md" storefront/main.py > main.py
from_lesson "$HERE/standard.md" storefront/app.yaml > app.yaml
PORT=8081 gunicorn -b :8081 main:app > gunicorn.log 2>&1 & G=$!
for _ in $(seq 80); do curl -s -o /dev/null localhost:8081 && break; sleep 0.25; done
block gunicorn
shown 'PORT=8081 gunicorn -b :$PORT main:app' 'cat gunicorn.log'
block curl
run 'curl -s localhost:8081/'
block deploy
run 'gcloud app deploy'
kill "$G"; wait "$G" 2>/dev/null
cd .. || exit 1

block prices
run "python3 prices.py other | grep 'App Engine'"
block flex-cost
run "python3 -c 'print(round((0.0526 * 1 + 0.0071 * 1) * 730, 2))'"

block plan
mkdir -p appengine && cd appengine || exit 1
from_lesson "$HERE/what-remains.md" appengine/main.tf > main.tf
export TF_PLUGIN_CACHE_DIR=~/gcp/.tfcache; mkdir -p "$TF_PLUGIN_CACHE_DIR"
quiet 'terraform init'
run "terraform plan -no-color | grep -E '^  #|location_id|default_hostname|url_dispatch|^Plan'"
