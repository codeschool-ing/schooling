#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of azure-compute (Container Apps:
# scale to zero, revisions and traffic splitting), as a script that produces
# them. THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lessons/le-sdktrwp1/captures.sh
#
# There is no Azure account. No environment, app, revision or traffic split is
# created: every `az containerapp` command here either prints its own help,
# stops at the CLI's check of its arguments, or stops at the refusal
# `Please run 'az login' to setup account.` The Bicep compiler checks the
# declarations offline. What runs for real is the shop's image, twice, in the
# Docker of the `docker` course, and a short Python program doing arithmetic.
#
# The `containerapp` extension of the CLI was NOT installed: on this machine
# the extension index (aka.ms, then azcliextensionsync.blob.core.windows.net)
# was refused by the network, so every command here is the core CLI's own
# `az containerapp` group, which needs no extension.
#
# What is STAGED rather than typed:
#   - shop-app.bicep and split.py are taken out of the lesson's own text, and
#     app.py and the Dockerfile out of lesson 7's, so the files that ran are
#     the files the student reads;
#   - the image is built FROM this machine's python:3.12-slim, which lab.sh
#     rebuilt with the proxy's certificate added; the student's base image has
#     none of it, and the build needs nothing from the network after the pull;
#   - the `sleep` gives the two containers time to start listening;
#   - the containers and the image are removed at the end.
#
# Container ids and host names differ on every run.
#
# Recorded 2026-10-30 on Ubuntu 24.04, no Azure account, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

L7=$HERE/../le-gpjpyeh5
quiet 'docker rm -f shop-v1-0 shop-v1-1'
quiet 'mkdir -p shop'
from_example "$L7/the-shop-at-home.md" app.py > shop/app.py
from_lesson "$L7/the-shop-at-home.md" Dockerfile > shop/Dockerfile
quiet 'docker build --quiet --tag shop:1.0 shop'

# a parameter's help on one line: the CLI wraps descriptions in a narrow column
ONELINE="awk '/^    --/ {print \"\"} {printf \"%s \", \$0}' | tr -s ' '"

# environment-and-app
from_lesson "$HERE/environment-and-app.md" shop-app.bicep > shop-app.bicep

block group
run 'az extension list'
run "az containerapp --help | grep -A1 '^Group'"

block envhelp
run "az containerapp env create --help | $ONELINE | grep -E -- '^ --(enable-workload-profiles|infrastructure-subnet-resource-id|internal-only) '"

block apphelp
run "az containerapp create --help | $ONELINE | grep -E -- '^ --(ingress|target-port|cpu|memory) '"

block build
run 'bicep build shop-app.bicep'
run 'ls shop-app.*'
run "jq -c '.resources[] | {type, apiVersion, name}' shop-app.json"
run "jq '.resources[1].dependsOn' shop-app.json"

block port
run "sed \"s/targetPort: 8080/targetPort: '8080'/\" shop-app.bicep > port.bicep"
run 'bicep build port.bicep'

block refusal
run 'az containerapp env create --name shop-env --resource-group shop'

# scale-rules
block scalehelp
run "az containerapp create --help | $ONELINE | grep -E -- '^ --(min-replicas|max-replicas|scale-rule-http-concurrency|scale-rule-type) ' | sed 's/ For more.*//'"

block scale
run "jq '.resources[1].properties.template.scale' shop-app.json"

block swap
run "sed 's/minReplicas: 0/minReplicas: 5/; s/maxReplicas: 10/maxReplicas: 0/' shop-app.bicep > swap.bicep"
run 'bicep build swap.bicep'
run "jq -c '.resources[1].properties.template.scale | {minReplicas, maxReplicas}' swap.json"

block number
run "sed \"s/concurrentRequests: '50'/concurrentRequests: 50/\" shop-app.bicep > number.bicep"
run 'bicep build number.bicep'

block image
run 'docker image ls shop:1.0 --format "{{.Repository}}:{{.Tag}}  {{.Size}}"'

# revisions
block two
run 'docker run -d --name shop-v1-0 -p 8081:8080 -e SHOP_VERSION=1.0 shop:1.0 > /dev/null'
run 'docker run -d --name shop-v1-1 -p 8082:8080 -e SHOP_VERSION=1.1 shop:1.0 > /dev/null'
quiet 'sleep 1'
run "curl -s -w '\n' localhost:8081/version"
run "curl -s -w '\n' localhost:8082/version"

block state
run "curl -s -w '\n' -X POST localhost:8081/orders -d '{\"item\": \"coffee\", \"qty\": 2}'"
run "curl -s -w '\n' localhost:8081/orders"
run "curl -s -w '\n' localhost:8082/orders"

block mode
run "az containerapp create --help | $ONELINE | grep -E -- '^ --revisions-mode '"
run "sed \"s/'Multiple'/'Multi'/\" shop-app.bicep > mode.bicep"
run 'bicep build mode.bicep'
run "jq -r '.resources[1].properties.configuration.activeRevisionsMode' mode.json"
run 'az containerapp create --name shop --resource-group shop --environment shop-env --image shopregistry.azurecr.io/shop:1.0 --revisions-mode multi 2>&1 | head -n 2'

block suffix
run "sed \"s/revisionSuffix: 'v1-1'/revisionSuffix: 'v1.1'/\" shop-app.bicep > suffix.bicep"
run 'bicep build suffix.bicep'
run "jq -r '.resources[1].properties.template.revisionSuffix' suffix.json"
run 'az containerapp update --name shop --resource-group shop --revision-suffix v1.1'

# traffic-splitting
block traffichelp
run "az containerapp ingress traffic set --help | sed -n '/^Arguments/,/^\$/p'"

block sum
run "sed 's/weight: 10,/weight: 20,/' shop-app.bicep > sum.bicep"
run 'bicep build sum.bicep'
run "jq -c '[.resources[1].properties.configuration.ingress.traffic[].weight]' sum.json"

from_lesson "$HERE/traffic-splitting.md" split.py > split.py
block split
run 'python3 split.py'

quiet 'docker rm -f shop-v1-0 shop-v1-1'
quiet 'docker image rm shop:1.0'
