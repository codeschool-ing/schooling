#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of gcp-compute, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lab.sh tools                   # once, beside course.json
#   bash lessons/le-0wj8wcjn/captures.sh
#
# The environment the transcripts run in is the one the section `your-lab`
# builds: lab.sh runs that section's own fences, and every run starts with the
# lines of its sixth fence, the ones a student types in every new terminal.
# Every run is in a network namespace with only loopback, so nothing here
# reached Google.
#
# What is STAGED rather than typed:
#   - `docker-denied` runs `docker ps` as a user outside the docker group
#     (uid 65534), the state of a login before `usermod -aG docker` took
#     effect;
#   - `no-token` unsets GOOGLE_OAUTH_ACCESS_TOKEN, as a terminal that skipped
#     that line would have it;
#   - prices.py is read out of the example in `the-price-sheet` and
#     main.tf out of the block in `the-name`.
#
# Recorded 2026-10-30 on Ubuntu 24.04, no Google Cloud account,
# TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

block check
run 'gcloud version'
run 'terraform version'
run 'docker run --rm python:3.12.13-slim python3 --version'
run 'gcloud config list'

block no-account
run 'gcloud compute machine-types list --zones=southamerica-east1-a'

block docker-denied
shown 'docker ps' 'setpriv --reuid=65534 --regid=65534 --clear-groups docker ps'

block prices
from_example "$HERE/the-price-sheet.md" prices.py > prices.py
run 'python3 prices.py vm'
run 'python3 prices.py custom n4 4 10'
run 'python3 prices.py custom n4 4 32'

block name-init
mkdir -p vm
from_lesson "$HERE/the-name.md" vm/main.tf > vm/main.tf
cd vm || exit 1
run 'terraform init'

block name-plan
run "terraform plan -no-color | grep -E '^  #|^      \\+ (machine_type|name|zone) |^Plan'"

block no-token
quiet 'unset GOOGLE_OAUTH_ACCESS_TOKEN'
run 'terraform plan'
quiet 'export GOOGLE_OAUTH_ACCESS_TOKEN=no-account'

block lenient
run "sed -i 's/e2-standard-2/e2-standard-3/' main.tf"
run "terraform plan -no-color | grep -E 'machine_type|^Plan'"
run "sed -i 's/e2-standard-3/n4-custom-4-10240/' main.tf"
run "terraform plan -no-color | grep -E 'machine_type|^Plan'"

block families
cd .. || exit 1
run 'python3 prices.py vm | grep -E "standard-2|highcpu-2|highmem-2"'
