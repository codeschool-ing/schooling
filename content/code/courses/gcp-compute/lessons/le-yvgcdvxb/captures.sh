#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of gcp-compute, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lab.sh tools                   # once, beside course.json
#   LAB_HOSTS=1 bash lessons/le-yvgcdvxb/captures.sh
#
# LAB_HOSTS=1 because the container's port is published by Docker on the
# machine's own network; nothing here reaches anything outside the laptop.
#
# What is STAGED rather than typed:
#   - the image orders:1 is built quietly from lesson 8's files, read out of
#     that lesson's section `a-container-that-fits`, as a student who did
#     lesson 8 already has it; load.py, runcost.py and main.tf are read out
#     of this lesson's sections;
#   - every container is removed at the start and at the end, so a run
#     leaves nothing behind (LAB_HOSTS runs take a lock, one at a time);
#   - `sleep 1` after `docker run -d`, quiet, gives the server a moment to
#     start listening, except in `cold`, which measures exactly that wait;
#   - prices.py is read out of lesson 1's section `the-price-sheet`;
#   - `terraform init`, whose output lesson 1 shows, runs quietly, with a
#     provider cache private to this run (TF_PLUGIN_CACHE_DIR).
#
# Every timing is this laptop's, Docker 29.9.2 on Ubuntu 24.04, and the
# lesson says so; none of it is a measurement of Cloud Run.
#
# Recorded 2026-10-30 on Ubuntu 24.04, no Google Cloud account,
# TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
L8=$HERE/../le-r7arqrvr

cleanup() { docker rm -f orders-slow orders-cold >/dev/null 2>&1; }
cleanup
mkdir -p orders tuning
from_lesson "$L8/a-container-that-fits.md" orders/app.py > orders/app.py
from_lesson "$L8/a-container-that-fits.md" orders/Dockerfile > orders/Dockerfile
quiet 'docker build -q -t orders:1 orders'
from_lesson "$HERE/concurrency.md" load.py > load.py
from_lesson "$HERE/cpu-allocation.md" runcost.py > runcost.py
from_lesson "$HERE/min-instances-and-boost.md" tuning/main.tf > tuning/main.tf
from_example "$HERE/../le-0wj8wcjn/the-price-sheet.md" prices.py > prices.py

block load
run 'docker run -d --name orders-slow -p 8080:8080 -e ORDERS_DELAY_MS=200 orders:1'
quiet 'sleep 1'
run 'python3 load.py http://localhost:8080/orders 20 1'
run 'python3 load.py http://localhost:8080/orders 20 20'
run 'python3 load.py http://localhost:8080/orders 200 80'
quiet 'docker rm -f orders-slow'

block prices
run 'python3 prices.py serverless | head -12'

block runcost
run 'for b in 0.05 0.25 0.50 0.75 1.00; do python3 runcost.py $b; done'

block cold
run 'time (docker run -d --name orders-cold -p 8080:8080 orders:1 > /dev/null; until curl -sf localhost:8080/health > /dev/null; do sleep 0.02; done)'
run 'time curl -s localhost:8080/health'
quiet 'docker rm -f orders-cold'

block imports
run "python3 -X importtime -c 'import google.cloud.pubsub_v1' 2>&1 | tail -1"
run "time python3 -c 'import google.cloud.pubsub_v1'"
run "time python3 -c 'import json, http.server'"

block plan
cd tuning || exit 1
quiet 'export TF_PLUGIN_CACHE_DIR=$HOME/gcp/.tfcache; mkdir -p $TF_PLUGIN_CACHE_DIR'
quiet 'terraform init'
run "terraform plan -no-color | grep -E 'concurrency|cpu_idle|startup_cpu_boost|min_instance_count|^Plan'"
cd .. || exit 1

cleanup
