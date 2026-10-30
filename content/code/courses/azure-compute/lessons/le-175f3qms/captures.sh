#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of azure-compute (scale sets and
# automatic scaling), as a script that produces them. THE SCRIPT IS THE SOURCE
# AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lessons/le-175f3qms/captures.sh
#
# No Azure account. What runs is the Bicep compiler, the Azure CLI's help
# text, and Docker running the shop's image; nothing reaches a subscription.
# The two Bicep files are taken out of the lesson's examples (from_example),
# so the files the student copies are the files that were compiled.
#
# What is STAGED rather than typed:
#   - the shop's image is built quietly, from the two files lesson 7 shows
#     whole (from the copies this course keeps until lesson 7 is written);
#     python:3.12-slim on this machine carries the proxy's certificate, which
#     the student's copy does not need;
#   - the container is removed at the end, quietly.
#
# Container ids and anything Docker invents are whatever this run produced.
#
# Recorded 2026-10-30 on Ubuntu 24.04, no Azure account, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

from_example "$HERE/the-scale-set.md" shop-vmss.bicep > shop-vmss.bicep

block build
run 'bicep build shop-vmss.bicep'
run 'ls'
run 'jq ".resources[] | {type, apiVersion, name, zones, sku}" shop-vmss.json'

block existing
run 'jq ".resources[0].properties.virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].properties.ipConfigurations[0].properties" shop-vmss.json'

block cli-modes
run 'az vmss create --help | tr -s "[:space:]" " " | grep -o "Allowed values: Flexible, Uniform. Default: [A-Za-z]*"'

block flex-wrong
run "sed -e \"s/'Flexible'/'Flex'/\" -e 's/platformFaultDomainCount: 1/platformFaultDomainCount: 3/' -e 's/singlePlacementGroup/singlePlacmentGroup/' shop-vmss.bicep > flex-wrong.bicep"
run 'diff shop-vmss.bicep flex-wrong.bicep'
run 'bicep build flex-wrong.bicep'

block autoscale-build
from_example "$HERE/autoscale-rules.md" shop-autoscale.bicep > shop-autoscale.bicep
run 'bicep build shop-autoscale.bicep'
run 'jq -c ".resources[0].properties.profiles[] | {name, capacity, fixedDate}" shop-autoscale.json'

block autoscale-wrong
run "sed -e \"0,/cooldown: 'PT10M'/s//cooldown: 10/\" -e \"0,/timeWindow: 'PT10M'/s//timeWindow: 'PT2M'/\" -e \"s/minimum: '3'/minimum: '13'/\" shop-autoscale.bicep > autoscale-wrong.bicep"
run 'diff shop-autoscale.bicep autoscale-wrong.bicep'
run 'bicep build autoscale-wrong.bicep'

block api-ranges
run 'grep -h -A2 ":ivar time_window:" venv/lib/python3.12/site-packages/azure/mgmt/monitor/models/_models_py3.py'
run 'grep -h -A1 ":ivar cooldown:" venv/lib/python3.12/site-packages/azure/mgmt/monitor/models/_models_py3.py'

block predictive-help
run 'az monitor autoscale create --help | tr -s "[:space:]" " " | grep -o "\-\-scale-mode : [^.]*\. Allowed values: [A-Za-z, ]*\."'

block upgrade-help
run 'az vmss create --help | tr -s "[:space:]" " " | grep -o "Allowed values: Automatic, Manual, Rolling. Default: [a-z]*"'

block repairs-help
run 'az vmss create --help | tr -s "[:space:]" " " | grep -o "\-\-automatic-repairs-grace-period : [^.]*\."'

block healthz
SEVEN="$HERE/../le-gpjpyeh5/the-shop-at-home.md"
mkdir -p shop
if [ -f "$SEVEN" ]; then
  from_example "$SEVEN" app.py > shop/app.py
  from_lesson "$SEVEN" Dockerfile > shop/Dockerfile
else
  cp /tmp/claude-0/-home-user-schooling/799218e8-cf26-5295-af2c-62af17912846/scratchpad/shop/app.py /tmp/claude-0/-home-user-schooling/799218e8-cf26-5295-af2c-62af17912846/scratchpad/shop/Dockerfile shop/
fi
quiet 'docker rm -f shop'
quiet 'docker build -q -t shop:1.0 shop'
run 'docker run -d --name shop -p 8080:8080 shop:1.0'
quiet 'sleep 2'
run 'curl -s -w " %{http_code}\n" localhost:8080/healthz'
run 'curl -s -w " %{http_code}\n" localhost:8080/health'
quiet 'docker rm -f shop'
