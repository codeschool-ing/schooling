#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of gcp-compute, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lab.sh tools                   # once, beside course.json
#   bash lessons/le-apvab8he/captures.sh
#
# Every run is in a network namespace with only loopback, so nothing here
# reached Google: each plan was computed by the provider on this machine. The
# Kubernetes manifests in this lesson are not run anywhere; there is no
# cluster in the lab.
#
# What is STAGED rather than typed:
#   - `terraform init` runs quietly; lesson 1 shows its output;
#   - TF_PLUGIN_CACHE_DIR points at a cache inside this run's ~/gcp, because
#     several captures share this machine and a provider being executed by one
#     cannot be rewritten in a shared cache by another;
#   - address.tf and cluster.tf are read out of the blocks in `ingress` and
#     `gateway-api`; cluster.tf is written only when `gateway-plan` runs, as
#     the student adds it then; the wrong channel is written with sed.
#
# Recorded 2026-10-30 on Ubuntu 24.04, no Google Cloud account,
# TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
quiet 'export TF_PLUGIN_CACHE_DIR=$HOME/gcp/.plugin-cache; mkdir -p $TF_PLUGIN_CACHE_DIR'

mkdir -p lb
from_lesson "$HERE/ingress.md" lb/address.tf > lb/address.tf
cd lb || exit 1
quiet 'terraform init'

block address-plan
run "terraform plan -no-color | grep -E '^  #|address|name|^Plan'"

block gateway-plan
from_lesson "$HERE/gateway-api.md" lb/cluster.tf > cluster.tf
run "terraform plan -no-color | grep -E '^  #|enable_autopilot|channel|^Plan'"

block gateway-wrong
run "sed -i 's/CHANNEL_STANDARD/STANDARD/' cluster.tf"
run 'terraform validate -no-color'
