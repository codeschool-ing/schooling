#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of gcp-compute, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lab.sh tools                   # once, beside course.json
#   bash lessons/le-skdjg18c/captures.sh
#
# Every run is in a network namespace with only loopback, so nothing here
# reached Google: each plan was computed by the provider on this machine, and
# autopilot.py only does arithmetic on prices.py's numbers.
#
# What is STAGED rather than typed:
#   - `terraform init` runs quietly; lesson 1 shows its output;
#   - TF_PLUGIN_CACHE_DIR points at a cache inside this run's ~/gcp, because
#     several captures share this machine and a provider being executed by one
#     cannot be rewritten in a shared cache by another;
#   - main.tf and pool.tf are read out of the blocks in `what-google-takes` and
#     `what-you-cannot-do`; prices.py out of lesson 1's `the-price-sheet`;
#     autopilot.py out of the example in `paying-per-pod`; pool.tf is written
#     only when `ap-pool` runs, as the student writes it then; the line that
#     produces `ap-conflict` is added with sed, as typed.
#
# Recorded 2026-10-30 on Ubuntu 24.04, no Google Cloud account,
# TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
quiet 'export TF_PLUGIN_CACHE_DIR=$HOME/gcp/.plugin-cache; mkdir -p $TF_PLUGIN_CACHE_DIR'
from_example "$HERE/../le-0wj8wcjn/the-price-sheet.md" prices.py > prices.py
from_example "$HERE/paying-per-pod.md" autopilot.py > autopilot.py

block ap-rates
run "python3 prices.py serverless | grep Autopilot"

block ap-shop
run 'python3 autopilot.py 6:0.5:1 2:1:4'

block ap-small
run 'python3 autopilot.py 2:0.25:0.5'

block ap-big
run 'python3 autopilot.py 12:1:4'

mkdir -p autopilot
from_lesson "$HERE/what-google-takes.md" autopilot/main.tf > autopilot/main.tf
cd autopilot || exit 1
quiet 'terraform init'

block ap-plan
run "terraform plan -no-color | grep -E '^  #|autopilot|\\+ location|^Plan'"

block ap-pool
from_lesson "$HERE/what-you-cannot-do.md" autopilot/pool.tf > pool.tf
run 'terraform validate -no-color'
run "terraform plan -no-color | grep -E '^  #|^Plan'"

block ap-conflict
run "sed -i 's/^  enable_autopilot    = true$/&\\n  remove_default_node_pool = true/' main.tf"
run 'terraform validate -no-color'
