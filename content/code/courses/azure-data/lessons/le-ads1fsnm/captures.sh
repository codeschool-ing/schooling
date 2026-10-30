#!/usr/bin/env bash
# The terminal sessions quoted in lesson 22 of azure-data (Event Hubs), as a
# script that produces them. Every transcript in the lesson was copied from
# its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# THE PROGRAMS ARE THE LESSON'S. partitions.py is read out of partitions.md,
# send_clicks.py, read_clicks.py and checkpointed.py out of the examples in
# partitions.md, reading-a-partition.md and checkpoints.md, the exported
# connection string out of the first sh fence of partitions.md, and the
# Terraform file out of capture.md. The emulators are empty when this starts.
#
# STAGED: Azurite is started by `services`, as in every lesson; the Event Hubs
# emulator is started by the command the lesson shows, and the wait for its
# "Successfully Up" line is a loop here where the student reruns the check.
# The second `validate` puts the interval back before changing the tier, in
# the same command line the lesson shows.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/azure || exit 1
services azurite || exit 1
file_fence "$HERE/partitions.md" partitions.py > partitions.py || exit 1
example "$HERE/partitions.md" send_clicks.py send_clicks.py || exit 1
example "$HERE/reading-a-partition.md" read_clicks.py read_clicks.py || exit 1
example "$HERE/checkpoints.md" checkpointed.py checkpointed.py || exit 1
eval "$(fence "$HERE/partitions.md" 1)"

block up
run 'docker compose --profile eventhubs up -d 2>&1 | tail -1'
for _ in $(seq 240); do docker compose logs eventhubs 2>&1 | grep -q 'Successfully Up' && break; sleep 0.5; done
block ready
run "docker compose logs eventhubs 2>&1 | grep -o 'Emulator Service is Successfully Up!' | head -1"
block az
run 'az eventhubs eventhub show -g rg-quitanda-stream-prd --namespace-name evhns-quitanda-app-prd -n clicks 2>&1 | tail -1'
block empty
run 'python partitions.py'
block send
run 'python send_clicks.py'
run 'python partitions.py'
block read
run 'python read_clicks.py'
block latest
run "python read_clicks.py '\$Default' @latest"
block fraud
run 'python read_clicks.py fraud'
block analytics
run 'python read_clicks.py analytics'
block container
run 'az storage container create -n checkpoints'
block short
run "sed 's/^store = .*/store = BlobCheckpointStore.from_connection_string(\"UseDevelopmentStorage=true\", \"checkpoints\")/' checkpointed.py > short.py && python short.py 2>&1 | tail -1"
block twice
run 'python checkpointed.py'
run 'python send_clicks.py 11'
run 'python checkpointed.py'
block blobs
run "az storage blob list -c checkpoints --include m --query \"[].[name, metadata.sequencenumber, metadata.offset]\" -o tsv"

block tf
bash -e <(fence "$HERE/capture.md" 1) || exit 1
cd ~/azure/tf/stream && file_fence "$HERE/capture.md" main.tf > main.tf
PROMPT_DIR='~/azure/tf/stream'
run "terraform init -no-color | grep -E 'Installing|Installed|successfully'"
run 'terraform validate -no-color'
block tf-wrong
run "sed -i 's/interval_in_seconds = 300/interval_in_seconds = 30/' main.tf && terraform validate -no-color"
run "sed -i 's/= 30\$/= 300/; /sku /s/\"Standard\"/\"Dedicated\"/' main.tf && terraform validate -no-color"
PROMPT_DIR='~/azure'
