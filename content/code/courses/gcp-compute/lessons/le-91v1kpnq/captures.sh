#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of gcp-compute, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lab.sh tools                   # once, beside course.json
#   bash lessons/le-91v1kpnq/captures.sh
#
# Every run is in a network namespace with only loopback, so nothing here
# reached Google: each plan was computed by the provider on this machine.
#
# What is STAGED rather than typed:
#   - `terraform init` runs quietly; lesson 1 shows its output;
#   - TF_PLUGIN_CACHE_DIR points at a cache inside this run's ~/gcp, because
#     several captures share this machine and a provider being executed by one
#     cannot be rewritten in a shared cache by another;
#   - main.tf and pool.tf are read out of the blocks in `the-control-plane`
#     and `node-pools`; prices.py out of lesson 1's `the-price-sheet`; pool.tf
#     is held back until `cp-plan` has run, as the student writes it later;
#   - the wrong values are written with sed and put back quietly.
#
# Recorded 2026-10-30 on Ubuntu 24.04, no Google Cloud account,
# TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
quiet 'export TF_PLUGIN_CACHE_DIR=$HOME/gcp/.plugin-cache; mkdir -p $TF_PLUGIN_CACHE_DIR'
from_example "$HERE/../le-0wj8wcjn/the-price-sheet.md" prices.py > prices.py

mkdir -p gke
from_lesson "$HERE/the-control-plane.md" gke/main.tf > gke/main.tf
cd gke || exit 1
quiet 'terraform init'

block cp-plan
run "terraform plan -no-color | grep -E '^  #|\+ location|channel|workload_pool|^Plan'"

block gke-price
cd .. || exit 1
run "python3 prices.py serverless | grep -E 'cluster|credit'"
cd gke || exit 1

block pool-plan
from_lesson "$HERE/node-pools.md" gke/pool.tf > pool.tf
run "terraform plan -no-color | grep -E '^  #|node_count|node_locations|machine_type|^Plan'"

block pool-price
cd .. || exit 1
run "python3 prices.py vm | grep -E 'per hour|e2-standard-4'"
run 'python3 -c "print(round(3 * 0.13402284 * 730, 2))"'
cd gke || exit 1

block channel-wrong
run "sed -i 's/\"REGULAR\"/\"WEEKLY\"/' main.tf"
run 'terraform validate -no-color'
quiet "sed -i 's/\"WEEKLY\"/\"REGULAR\"/' main.tf"

block strategy-wrong
run "sed -i 's/\"SURGE\"/\"ROLLING\"/' pool.tf"
run 'terraform validate -no-color'
quiet "sed -i 's/\"ROLLING\"/\"SURGE\"/' pool.tf"

block window-plan
run "terraform plan -no-color | grep -E 'start_time|end_time|recurrence|exclusion_name|\+ scope'"

block local-time
run 'TZ=America/Sao_Paulo date -d 2026-11-07T05:00:00Z'
run 'TZ=America/Sao_Paulo date -d 2026-11-07T11:00:00Z'
