#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of gcp-compute, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lab.sh tools                   # once, beside course.json
#   bash lessons/le-5peyfwx8/captures.sh
#
# Every run is in a network namespace with only loopback, so nothing here
# reached Google: each plan was computed by the provider on this machine.
#
# What is STAGED rather than typed:
#   - `terraform init` in each folder runs quietly; lesson 1 shows its output;
#   - TF_PLUGIN_CACHE_DIR points at a cache inside this run's ~/gcp, because
#     several captures share this machine and a provider being executed by one
#     cannot be rewritten in a shared cache by another; it changes nothing
#     the student sees;
#   - the main.tf files are read out of the blocks in `direct-vpc-egress` and
#     `connectors`; prices.py out of lesson 1's `the-price-sheet`; the edits
#     that produce the refusals are made with sed, as typed.
#
# Recorded 2026-10-30 on Ubuntu 24.04, no Google Cloud account,
# TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
quiet 'export TF_PLUGIN_CACHE_DIR=$HOME/gcp/.plugin-cache; mkdir -p $TF_PLUGIN_CACHE_DIR'
from_example "$HERE/../le-0wj8wcjn/the-price-sheet.md" prices.py > prices.py

mkdir -p run-vpc run-connector
from_lesson "$HERE/direct-vpc-egress.md" run-vpc/main.tf > run-vpc/main.tf
from_lesson "$HERE/connectors.md" run-connector/main.tf > run-connector/main.tf

cd run-vpc || exit 1
quiet 'terraform init'
block direct-plan
run "terraform plan -no-color | grep -E '^  #|image|value|egress|network|^Plan'"

block ingress-wrong
run "sed -i 's/INGRESS_TRAFFIC_ALL/INTERNAL/' main.tf"
run 'terraform validate -no-color'
quiet "sed -i 's/\"INTERNAL\"/\"INGRESS_TRAFFIC_ALL\"/' main.tf"

block egress-wrong
run "sed -i 's/PRIVATE_RANGES_ONLY/PRIVATE_ONLY/' main.tf"
run 'terraform validate -no-color'

cd ../run-connector || exit 1
quiet 'terraform init'
block connector-plan
run "terraform plan -no-color | grep -E '^  #|connector|egress|machine_type|instances|ip_cidr|^Plan'"

block both
run "sed -i 's/^      connector = .*/&\n      network_interfaces {\n        network = \"shop\"\n      }/' main.tf"
run 'terraform validate -no-color'
run "terraform plan -no-color | grep -E 'Error|conflicts|^Plan'"
block both-literal
run "sed -i 's#google_vpc_access_connector.shop.id#\"projects/planner-dev/locations/southamerica-east1/connectors/shop-connector\"#' main.tf"
run 'terraform validate -no-color'

cd .. || exit 1
block connector-price
run "python3 prices.py vm | grep -E 'per hour|e2-micro'"
