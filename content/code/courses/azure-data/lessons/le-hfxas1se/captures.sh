#!/usr/bin/env bash
# The terminal sessions quoted in lesson 23 of azure-data (Stream Analytics),
# as a script that produces them. Every transcript in the lesson was copied
# from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# NOTHING HERE IS STREAM ANALYTICS, which has no emulator. send_checkouts.py
# and windows.py are the course's own programs, read out of the examples in
# event-time.md, run against the Event Hubs emulator; the Terraform file is
# read out of the-job.md and only validated.
#
# STAGED: Azurite is started by `services`; the Event Hubs emulator by the
# command the lesson shows, with the wait for its "Successfully Up" line done
# here by a loop. The three Terraform changes in late-data.md are each made
# on a fresh copy of the file, which is what the `cp` in each command is.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/azure || exit 1
services azurite || exit 1
example "$HERE/event-time.md" send_checkouts.py send_checkouts.py || exit 1
example "$HERE/event-time.md" windows.py windows.py || exit 1

block tf
bash -e <(fence "$HERE/the-job.md" 1) || exit 1
cd ~/azure/tf/asa && file_fence "$HERE/the-job.md" main.tf > main.tf && cp main.tf main.tf.orig
PROMPT_DIR='~/azure/tf/asa'
run "terraform init -no-color | grep -E 'Installing|Installed|successfully'"
run 'terraform validate -no-color'
block tf-ranges
run "cp main.tf.orig main.tf && sed -i 's/_out_of_order_max_delay_in_seconds = 20/_out_of_order_max_delay_in_seconds = 600/' main.tf && terraform validate -no-color 2>&1 | grep Error"
run "cp main.tf.orig main.tf && sed -i 's/_late_arrival_max_delay_in_seconds = 60/_late_arrival_max_delay_in_seconds = 1814400/' main.tf && terraform validate -no-color 2>&1 | grep Error"
run "cp main.tf.orig main.tf && sed -i 's/\"Adjust\"/\"Keep\"/' main.tf && terraform validate -no-color 2>&1 | grep Error"
cp main.tf.orig main.tf
PROMPT_DIR='~/azure'
cd ~/azure

block up
run 'docker compose --profile eventhubs up -d 2>&1 | tail -1'
for _ in $(seq 240); do docker compose logs eventhubs 2>&1 | grep -q 'Successfully Up' && break; sleep 0.5; done
eval "$(fence "$HERE/event-time.md" 1)"
block first
run 'python send_checkouts.py'
run 'python windows.py drop 20'
block adjust
run 'python windows.py adjust 20'
block wait
run 'python windows.py drop 60'
