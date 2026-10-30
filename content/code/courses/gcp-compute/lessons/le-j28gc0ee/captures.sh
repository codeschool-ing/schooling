#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of gcp-compute, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lab.sh tools                   # once, beside course.json
#   LAB_HOSTS=1 bash lessons/le-j28gc0ee/captures.sh
#
# LAB_HOSTS=1 because the containers' ports are published by Docker on the
# machine's own network; nothing here reaches anything outside the laptop.
#
# What is STAGED rather than typed:
#   - the image orders:1 is built quietly from lesson 8's files, read out of
#     that lesson's section `a-container-that-fits`, as a student who did
#     lesson 8 already has it; main.tf is read out of `traffic`;
#   - every container is removed at the start and at the end, so a run
#     leaves nothing behind (LAB_HOSTS runs take a lock, one at a time);
#   - `sleep 1` after `docker run -d`, quiet, gives the servers a moment to
#     start listening;
#   - `terraform init`, whose output lesson 1 shows, runs quietly, with a
#     provider cache private to this run (TF_PLUGIN_CACHE_DIR).
#
# Recorded 2026-10-30 on Ubuntu 24.04, no Google Cloud account,
# TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
L8=$HERE/../le-r7arqrvr

cleanup() { docker rm -f orders-v1 orders-v2 >/dev/null 2>&1; }
cleanup
mkdir -p orders traffic
from_lesson "$L8/a-container-that-fits.md" orders/app.py > orders/app.py
from_lesson "$L8/a-container-that-fits.md" orders/Dockerfile > orders/Dockerfile
quiet 'docker build -q -t orders:1 orders'
from_lesson "$HERE/traffic.md" traffic/main.tf > traffic/main.tf

block suffix
run "gcloud run deploy --help | grep -A5 -- '^     --revision-suffix'"

block two
run 'docker run -d --name orders-v1 -p 8081:8080 -e K_REVISION=orders-v1 orders:1'
run 'docker run -d --name orders-v2 -p 8082:8080 -e K_REVISION=orders-v2 -e ORDERS_DELAY_MS=250 orders:1'
quiet 'sleep 1'
run 'curl -s localhost:8081/orders | python3 -m json.tool | tail -2'
run 'curl -s -o /dev/null -w "%{time_total}\n" localhost:8081/orders'
run 'curl -s localhost:8082/orders | python3 -m json.tool | tail -2'
run 'curl -s -o /dev/null -w "%{time_total}\n" localhost:8082/orders'

block plan
cd traffic || exit 1
quiet 'export TF_PLUGIN_CACHE_DIR=$HOME/gcp/.tfcache; mkdir -p $TF_PLUGIN_CACHE_DIR'
quiet 'terraform init'
run "terraform plan -no-color | sed -n '/+ traffic {/,/^        }/p'"

block too-much
run "sed -i 's/percent  = 10/percent  = 20/' main.tf"
run "terraform plan -no-color | grep -E 'percent|^Plan'"
cd .. || exit 1

block update-traffic
run "gcloud run services update-traffic --help | sed -n '/^EXAMPLES/,/^POSITIONAL/p'"

block no-traffic
run "gcloud run deploy --help | grep -A9 -- '^     --no-traffic'"

block tag
run "gcloud run deploy --help | grep -A2 -- '^     --tag=TAG'"

cleanup
