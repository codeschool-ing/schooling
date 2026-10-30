#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of gcp-compute, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lab.sh tools                   # once, beside course.json
#   bash lessons/le-y37sj735/captures.sh
#
# Every run is in a network namespace with only loopback, so nothing here
# reached Google: each plan was computed by the provider on this machine.
# The key file is the lesson's own, with a sentence where a private key would
# be; no real key exists anywhere in this course.
#
# What is STAGED rather than typed:
#   - photos-key.json is written by running the lesson's second sh fence in
#     `the-static-key`;
#   - `terraform init` runs quietly; lesson 1 shows its output;
#   - TF_PLUGIN_CACHE_DIR points at a cache inside this run's ~/gcp, because
#     several captures share this machine and a provider being executed by one
#     cannot be rewritten in a shared cache by another;
#   - main.tf and direct.tf are read out of the blocks in
#     `the-pool-and-the-binding` and `direct-access`; direct.tf is written only
#     for `wi-direct`, as the student adds it then; the wrong values are
#     written with sed and put back quietly.
#
# Recorded 2026-10-30 on Ubuntu 24.04, no Google Cloud account,
# TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
quiet 'export TF_PLUGIN_CACHE_DIR=$HOME/gcp/.plugin-cache; mkdir -p $TF_PLUGIN_CACHE_DIR'

mkdir -p static-key && cd static-key || exit 1
bash "$HERE/../../lab.sh" fence "$HERE/the-static-key.md" 2 > /tmp/mkkey.$$
bash /tmp/mkkey.$$; rm -f /tmp/mkkey.$$

block secret-make
run 'printf "apiVersion: v1\nkind: Secret\nmetadata:\n  name: photos-key\ndata:\n  key.json: %s\n" "$(base64 -w0 photos-key.json)" > secret.yaml'
run 'cut -c1-72 secret.yaml'

block secret-read
run "grep key.json secret.yaml | awk '{print \$2}' | base64 -d | grep -E 'client_email|private_key\"'"

cd .. || exit 1
mkdir -p wi
from_lesson "$HERE/the-pool-and-the-binding.md" wi/main.tf > wi/main.tf
cd wi || exit 1
quiet 'terraform init'

block wi-plan
run "terraform plan -no-color | grep -E '^  #|account_id|email|member|role|^Plan'"

block wi-member
run "sed -i 's#\"serviceAccount:planner-dev.svc.id.goog#\"planner-dev.svc.id.goog#' main.tf"
run 'terraform validate -no-color'
quiet "sed -i 's#\"planner-dev.svc.id.goog#\"serviceAccount:planner-dev.svc.id.goog#' main.tf"

block wi-short
run "sed -i 's/\"photos-reader\"/\"pr\"/' main.tf"
run 'terraform validate -no-color'
quiet "sed -i 's/\"pr\"/\"photos-reader\"/' main.tf"

block wi-direct
from_lesson "$HERE/direct-access.md" wi/direct.tf > direct.tf
run "terraform plan -no-color | grep -E '^  # .*direct|principal|^Plan'"
