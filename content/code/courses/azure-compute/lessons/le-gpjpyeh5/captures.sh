#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of azure-compute (Container
# Instances), as a script that produces them. THE SCRIPT IS THE SOURCE AND ITS
# OUTPUT IS NOT COMMITTED.
#
#   bash lab.sh tools                   # once, beside course.json
#   bash lessons/le-gpjpyeh5/captures.sh
#
# There is no Azure account. Every `az container create` here stops before a
# request is made: either at the CLI's own check of its arguments, or at the
# refusal `Please run 'az login' to setup account.` The Bicep compiler checks
# the declarations offline. What runs for real is the shop's image, in the
# Docker of the `docker` course.
#
# What is STAGED rather than typed:
#   - app.py, the Dockerfile, shop-aci.yaml and shop.bicep are taken out of the
#     lesson's own text, so the files that ran are the files the student reads;
#   - the image is built FROM this machine's python:3.12-slim, which lab.sh
#     rebuilt with the proxy's certificate added; the student's base image has
#     none of it, and the build needs nothing from the network after the pull;
#   - the `sleep` lines give a container time to start, or to fail and be
#     restarted, before the next command looks at it;
#   - the container started in the-shop-at-home is removed before
#     sizes-and-restart starts it again, as the lesson tells the student to.
#
# Recorded 2026-10-30 on Ubuntu 24.04, no Azure account, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

IMG=shopregistry.azurecr.io/shop:1.0
quiet 'docker rm -f shop report report-ok'

# container-groups
block vnet
run "az container create --resource-group shop --name shop --image $IMG --ports 8080 --vnet shop-vnet --subnet aci --dns-name-label shop-sp"
run "az container create --resource-group shop --name shop --image $IMG --ports 8080 --vnet shop-vnet --subnet aci --ip-address Public"

# the-shop-at-home
quiet 'mkdir -p shop'
from_example "$HERE/the-shop-at-home.md" app.py > shop/app.py
from_lesson "$HERE/the-shop-at-home.md" Dockerfile > shop/Dockerfile
from_example "$HERE/the-shop-at-home.md" shop-aci.yaml > shop-aci.yaml

block build
run 'ls shop'
run 'docker build --quiet --tag shop:1.0 shop | cut -c1-19'
run 'docker image ls shop:1.0 --format "{{.Repository}}:{{.Tag}}  {{.Size}}"'

block run
run 'docker run -d --name shop -p 8080:8080 shop:1.0 | cut -c1-12'
quiet 'sleep 1'
run "curl -s -w '\n' localhost:8080/healthz"
run "curl -s -w '\n' localhost:8080/version"
run "curl -s -w '\n' -X POST localhost:8080/orders -d '{\"item\": \"coffee\", \"qty\": 2}'"
run "curl -s -w '\n' localhost:8080/orders"
run "curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/nothing"

block logs
run 'docker logs shop'

block sidecar
run "docker run --rm --network container:shop shop:1.0 python -c \"import urllib.request; print(urllib.request.urlopen('http://localhost:8080/healthz').read().decode())\""
run "docker run --rm shop:1.0 python -c \"import urllib.request; print(urllib.request.urlopen('http://localhost:8080/healthz').read().decode())\" 2>&1 | tail -n 1"

block user
run 'docker exec shop id'

block create
run 'az container create --resource-group shop --file shop-aci.yaml'
quiet 'docker rm -f shop'

# sizes-and-restart
from_lesson "$HERE/sizes-and-restart.md" shop.bicep > shop.bicep

block help
run "az container create --help | awk '/^    --/{p=0} /^    --(cpu|memory|ports|restart-policy) /{p=1} p'"

block bicep
run 'bicep build shop.bicep'
run 'ls shop.*'
run 'jq ".resources[0].properties.containers[0].properties.resources" shop.json'

block float
run "sed \"s/json('1.5')/1.5/\" shop.bicep > float.bicep"
run 'bicep build float.bicep'
run 'ls float.*'

block typo
run "sed \"s/'Always'/'OnFaliure'/\" shop.bicep > typo.bicep"
run 'bicep build typo.bicep'
run 'jq -r ".resources[0].properties.restartPolicy" typo.json'
run "az container create --resource-group shop --name shop --image $IMG --restart-policy OnFaliure 2>&1 | head -n 1"

block spot
run "sed \"s/restartPolicy: 'Always'/&\\n    priority: 'Spot'/\" shop.bicep > spot.bicep"
run 'grep -n -A1 restartPolicy spot.bicep'
run 'bicep build spot.bicep'
run 'jq -r ".resources[0].properties.priority" spot.json'

block failing
run "docker run -d --name report --restart on-failure:3 shop:1.0 python -c \"import sys; print('report failed'); sys.exit(1)\" > /dev/null"
quiet 'sleep 6'
run 'docker inspect --format "{{.RestartCount}} {{.State.Status}} {{.State.ExitCode}}" report'
run 'docker logs report'

block succeeding
run "docker run -d --name report-ok --restart on-failure:3 shop:1.0 python -c \"print('report written')\" > /dev/null"
quiet 'sleep 2'
run 'docker inspect --format "{{.RestartCount}} {{.State.Status}} {{.State.ExitCode}}" report-ok'
run 'docker logs report-ok'

block restart
run 'docker run -d --name shop -p 8080:8080 shop:1.0 > /dev/null'
quiet 'sleep 1'
run "curl -s -w '\n' -X POST localhost:8080/orders -d '{\"item\": \"coffee\", \"qty\": 2}'"
run 'docker restart shop'
quiet 'sleep 1'
run "curl -s -w '\n' localhost:8080/orders"
run "curl -s -w '\n' localhost:8080/version"

quiet 'docker rm -f shop report report-ok'
quiet 'docker image rm shop:1.0'
