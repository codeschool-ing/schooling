#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of azure-compute (availability sets,
# availability zones and what each one protects against), as a script that
# produces them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lessons/le-v2t6dw1r/captures.sh
#
# No Azure account. What runs is the Bicep compiler, the Azure CLI's help
# text, the Azure SDK's own descriptions of two properties (installed with the
# CLI), and a short Python program; nothing reaches a subscription. The two
# Bicep files and the program are taken out of the lesson's examples
# (from_example), so the files the student copies are the files that ran.
#
# What is STAGED rather than typed: the mistaken copies of each Bicep file are
# made with sed rather than in an editor, and `diff` prints what changed.
#
# Recorded 2026-10-30 on Ubuntu 24.04, no Azure account, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

MODELS=venv/lib/python3.12/site-packages/azure/mgmt

block avset-build
from_example "$HERE/fault-and-update-domains.md" shop-avset.bicep > shop-avset.bicep
run 'bicep build shop-avset.bicep'
run 'jq -c ".resources[] | {type, name, copy: .copy.count}" shop-avset.json'
run 'jq ".resources[0].properties" shop-avset.json'

block avset-help
run 'az vm availability-set create --help | tr -s "[:space:]" " " | grep -o "\-\-platform-[a-z-]*-count : [^.]*\.[^.]*\."'

block avset-creation
run "grep -m1 -A10 ':ivar availability_set:' $MODELS/compute/v2024_11_01/models/_models_py3.py"

block avset-wrong
run "sed -e 's/platformFaultDomainCount: 2/platformFaultDomainCount: 4/' -e \"s/platformUpdateDomainCount: 5/platformUpdateDomainCount: '5'/\" shop-avset.bicep > avset-wrong.bicep"
run 'diff shop-avset.bicep avset-wrong.bicep'
run 'bicep build avset-wrong.bicep'

block zones-build
from_example "$HERE/availability-zones.md" shop-zones.bicep > shop-zones.bicep
run 'bicep build shop-zones.bicep'
run 'jq -c ".resources[] | {type, name, zones, sku}" shop-zones.json'

block zones-help
run 'az vm create --help | tr -s "[:space:]" " " | grep -o "\-\-zone -z : [^.]*\."'
run 'az network public-ip create --help | tr -s "[:space:]" " " | grep -o "\-\-zone -z : [^.]*\.\|\-\-sku : [^.]*\.[^.]*\."'

block zones-logical
run "grep -h -A3 ':ivar logical_zone:' $MODELS/resource/subscriptions/v2022_12_01/models/_models_py3.py"

block zones-wrong
run "sed -e \"s/zones: \\['1', '2', '3'\\]/zones: [1, 2, 3]/\" -e \"s/var zones = \\['1', '2'\\]/var zones = ['1', '4']/\" shop-zones.bicep > zones-wrong.bicep"
run 'diff shop-zones.bicep zones-wrong.bicep'
run 'bicep build zones-wrong.bicep'

block zones-both
run "sed \"/^resource vm/,/^  properties/s/^  location: location\$/&\\n  zones: ['1']/\" shop-avset.bicep > both.bicep"
run 'diff shop-avset.bicep both.bicep'
run 'bicep build both.bicep'

block arithmetic
from_example "$HERE/the-arithmetic-of-availability.md" availability.py > availability.py
run 'python3 availability.py'
