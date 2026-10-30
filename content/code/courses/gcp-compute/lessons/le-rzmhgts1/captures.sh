#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of gcp-compute, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lab.sh tools                   # once, beside course.json
#   bash lessons/le-rzmhgts1/captures.sh
#
# Every run is in a network namespace with only loopback in it, so nothing
# here reached Google, and nothing could reach a metadata server.
#
# What is STAGED rather than typed:
#   - main.tf, startup.sh and adc.py are read out of the blocks of the
#     sections `startup-scripts` and `the-service-account`;
#   - `terraform init`, whose output lesson 1 shows, runs quietly, with a
#     provider cache private to this run (TF_PLUGIN_CACHE_DIR), because other
#     captures may be running Terraform from the shared cache at the same time;
#   - `curl-metadata` runs in the namespace, which has no route at all to
#     169.254.169.254: on a laptop with a network the same request waits
#     until its timeout instead, and the lesson says so.
#
# Recorded 2026-10-30 on Ubuntu 24.04, no Google Cloud account,
# TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

mkdir -p meta
from_lesson "$HERE/startup-scripts.md" meta/main.tf > meta/main.tf
from_lesson "$HERE/startup-scripts.md" meta/startup.sh > meta/startup.sh
from_lesson "$HERE/the-service-account.md" meta/adc.py > meta/adc.py
cd meta || exit 1
quiet 'export TF_PLUGIN_CACHE_DIR=$HOME/gcp/.tfcache; mkdir -p $TF_PLUGIN_CACHE_DIR'
quiet 'terraform init'

block startup-local
run 'bash startup.sh; echo "exit status $?"'

block plan-meta
run "terraform plan -no-color | sed -n '/+ metadata  /,/^ *EOT\$/p'"

block curl-metadata
run 'curl -sS -m 5 -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/project/project-id; echo "exit status $?"'

block adc
run 'time python3 adc.py'
run 'GOOGLE_APPLICATION_CREDENTIALS=~/gcp/meta/key.json python3 adc.py'

block plan-sa
run "terraform plan -no-color | grep -E '# google|email|member|auth/'"

block scopes
run "sed -i 's/\"cloud-platform\"\\]/\"storage-ro\", \"logging-write\"]/' main.tf"
run "terraform plan -no-color | grep 'auth/'"
