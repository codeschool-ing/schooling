#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of azure-compute (Spot virtual
# machines and eviction policy), as a script that produces them. THE SCRIPT
# IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lessons/le-v6xmg2eg/captures.sh
#
# No Azure account. What runs is the Bicep compiler and the Azure CLI's help
# text; nothing reaches a subscription, nothing is evicted, and no Spot price
# appears anywhere. The three files the lesson shows whole are taken from it:
# report-vm.bicep out of `the-discount` (from_lesson), workers-vmss.bicep out
# of the example in `what-runs-on-spot` and spot-watch.py out of the example
# in `scheduled-events` (from_example), so what the student copies is what
# was compiled.
#
# What is STAGED rather than typed:
#   - the deliberate mistakes are made with sed into copies of the files, and
#     `diff` shows each change; the student makes them in an editor;
#   - the block `handler-compiles` is the author's check that spot-watch.py
#     is valid Python, and is not quoted: the lesson says the listener was
#     compiled and never run. Scheduled Events cannot be reached from a
#     laptop, and this script imitates no metadata service. (On this
#     recording machine 169.254.169.254 is answered by the sandbox's own
#     network filter, which is neither Azure nor what a laptop would answer,
#     so the listener is not run here even to show its failure branch.)
#
# Recorded 2026-10-30 on Ubuntu 24.04, no Azure account, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

from_lesson "$HERE/the-discount.md" report-vm.bicep > report-vm.bicep
from_example "$HERE/what-runs-on-spot.md" workers-vmss.bicep > workers-vmss.bicep
from_example "$HERE/scheduled-events.md" spot-watch.py > spot-watch.py

block help-priority
run 'az vm create --help | tr -s "[:space:]" " " | grep -o -- "--priority : [^:]*Allowed values: [A-Za-z, ]*\."'

block report-build
run 'bicep build report-vm.bicep'
run 'jq ".resources[0].properties | {priority, evictionPolicy, billingProfile}" report-vm.json'

block lowercase
run "sed \"s/'Spot'/'spot'/\" report-vm.bicep > lower.bicep"
run 'bicep build lower.bicep'
run 'jq ".resources[0].properties.priority" lower.json'
run "sed \"s/'Spot'/1/\" report-vm.bicep > number.bicep"
run 'bicep build number.bicep'

block help-eviction
run 'az vm create --help | tr -s "[:space:]" " " | grep -o -- "--eviction-policy : [^:]*: [A-Za-z, ]*\."'
run 'az vm create --help | tr -s "[:space:]" " " | grep -o -- "--max-price \[Preview\] : [^.]*\. [^.]*\."'

block wrong-type
run "sed -e \"s/maxPrice: -1/maxPrice: '-1'/\" -e \"s/    evictionPolicy: 'Deallocate'/&\n    evictionType: 'CapacityOnly'/\" report-vm.bicep > wrong.bicep"
run 'diff report-vm.bicep wrong.bicep'
run 'bicep build wrong.bicep'

block decimal
run "sed \"s/maxPrice: -1/maxPrice: 0.05/\" report-vm.bicep > price.bicep"
run 'bicep build price.bicep'
run 'ls price.*'

block decimal-json
run "sed -i \"s/maxPrice: 0.05/maxPrice: json('0.05')/\" price.bicep"
run 'bicep build price.bicep'
run 'jq ".resources[0].properties.billingProfile" price.json'

block workers-build
run 'bicep build workers-vmss.bicep'
run 'jq ".resources[0].properties | {priorityMixPolicy, spotRestorePolicy, priority: .virtualMachineProfile.priority, evictionPolicy: .virtualMachineProfile.evictionPolicy}" workers-vmss.json'

block help-mix
run 'az vmss create --help | tr -s "[:space:]" " " | grep -o -- "--regular-priority-[a-z]* \[Preview\] : [^.]*\. Must be [^.]*\."'

block workers-wrong
run "sed -e 's/AboveBase: 25/AboveBase: 150/' -e \"s/restoreTimeout: 'PT1H'/restoreTimeout: 60/\" -e \"s/'Flexible'/'Uniform'/\" -e \"s/'Delete'/'delete'/\" workers-vmss.bicep > workers-wrong.bicep"
run 'diff workers-vmss.bicep workers-wrong.bicep'
run 'bicep build workers-wrong.bicep'

block handler-compiles
run 'python3 -m py_compile spot-watch.py && echo compiled'
