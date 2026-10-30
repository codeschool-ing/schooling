#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of gcp-compute, as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lab.sh tools                   # once, beside course.json
#   bash lessons/le-n041grrg/captures.sh
#
# Every run is in a network namespace with only loopback, so nothing here
# reached Google.
#
# What is STAGED rather than typed:
#   - `terraform init` in each folder is run quietly, and again if another
#     run holds the shared provider cache; lesson 1 shows its output;
#   - every .tf file is read out of the lesson's own blocks (from_lesson), and
#     prices.py out of lesson 1's example;
#   - `schedule-typo` edits schedule.tf with sed, then puts it back.
#
# Recorded 2026-10-30 on Ubuntu 24.04, no Google Cloud account,
# TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

from_example "$HERE/../le-0wj8wcjn/the-price-sheet.md" prices.py > prices.py
mkdir -p disks hyperdisk scratch
from_lesson "$HERE/persistent-disks.md" disks/main.tf > disks/main.tf
from_lesson "$HERE/hyperdisk.md" hyperdisk/main.tf > hyperdisk/main.tf
from_lesson "$HERE/local-ssd.md" scratch/main.tf > scratch/main.tf

block disk-prices
run 'python3 prices.py disks | head -7'

block disks-plan
cd disks || exit 1
quiet 'for i in $(seq 200); do terraform init && break; sleep 3; done'
run "terraform plan -no-color | grep -E '^  #|^      \\+ (type|size) |device_name += \"|^Plan'"

block hyperdisk-plan
cd ../hyperdisk || exit 1
quiet 'for i in $(seq 200); do terraform init && break; sleep 3; done'
run "terraform plan -no-color | grep -E '^  #|provisioned_|^              \\+ type|^Plan'"

block scratch-plan
cd ../scratch || exit 1
quiet 'for i in $(seq 200); do terraform init && break; sleep 3; done'
run "terraform plan -no-color | grep -E '^  #|scratch_disk|^          \\+ (interface|size) |^Plan'"

block snapshot-prices
cd .. || exit 1
run 'python3 prices.py disks | grep snapshot'

block schedule-plan
from_lesson "$HERE/snapshots.md" disks/schedule.tf > disks/schedule.tf
cd disks || exit 1
run "terraform plan -no-color | grep -E '^  #|start_time|max_retention_days|on_source_disk_delete|^Plan'"

block schedule-typo
run "sed -i 's/KEEP_AUTO_SNAPSHOTS/KEEP_SNAPSHOTS/' schedule.tf"
run 'terraform plan -no-color'
quiet "sed -i 's/KEEP_SNAPSHOTS/KEEP_AUTO_SNAPSHOTS/' schedule.tf"
