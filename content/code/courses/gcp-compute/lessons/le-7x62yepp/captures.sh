#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of gcp-compute, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lab.sh tools                   # once, beside course.json
#   bash lessons/le-7x62yepp/captures.sh
#
# Every run is in a network namespace with only loopback, so nothing here
# reached Google: the data source in `data-source` fails to resolve
# compute.googleapis.com, which is the point it makes.
#
# What is STAGED rather than typed:
#   - `terraform init` in each folder is run quietly, and again if another
#     run holds the shared provider cache; lesson 1 shows its output;
#   - every main.tf is read out of the lesson's own blocks (from_lesson), and
#     prices.py out of lesson 1's example.
#
# Recorded 2026-10-30 on Ubuntu 24.04, no Google Cloud account,
# TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

from_example "$HERE/../le-0wj8wcjn/the-price-sheet.md" prices.py > prices.py

mkdir -p images image-build gpu
from_lesson "$HERE/public-images.md" images/main.tf > images/main.tf
from_lesson "$HERE/your-own-image.md" image-build/main.tf > image-build/main.tf
from_lesson "$HERE/gpus.md" gpu/main.tf > gpu/main.tf

cd images || exit 1
quiet 'for i in $(seq 200); do terraform init && break; sleep 3; done'
block data-source
run 'terraform plan'

block as-string
run "sed -i '/^data/,/^}/d; s|data.google_compute_image.debian.self_link|\"debian-cloud/debian-12\"|' main.tf"
run 'grep -n image main.tf'
run "terraform plan -no-color | grep -E '^  #|image|^Plan'"

block deprecate-states
cd .. || exit 1
run "gcloud compute images deprecate --help | sed -n '/^     --state=STATE/,/^OPTIONAL/p'"

block own-image
cd image-build || exit 1
quiet 'for i in $(seq 200); do terraform init && break; sleep 3; done'
run "terraform plan -no-color | grep -E '^  #|^      \\+ (name|family|source_disk) |^Plan'"

block image-price
cd .. || exit 1
run 'python3 prices.py disks | grep -E "image|snapshot"'

block gpu-plan
cd gpu || exit 1
quiet 'for i in $(seq 200); do terraform init && break; sleep 3; done'
run "terraform plan -no-color | grep -E '^  #|machine_type|on_host_maintenance|^          \\+ (count|type) |^Plan'"

block maintenance-help
cd .. || exit 1
run "gcloud compute instances create --help | sed -n '/^     --maintenance-policy/,/^     --max-run/p'"

block gpu-price
run 'python3 prices.py vm | grep -E "per hour|e2-standard-2|g2-standard-4"'
