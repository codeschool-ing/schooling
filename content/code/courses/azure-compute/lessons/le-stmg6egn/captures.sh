#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of azure-compute (App Service:
# plans, slots and swap with warm-up), as a script that produces them. THE
# SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash lessons/le-stmg6egn/captures.sh
#
# There is no Azure account. No plan, web app or slot is created and no swap
# is run: every `az appservice` and `az webapp` command here either prints its
# own help or stops at the refusal `Please run 'az login' to setup account.`
# The Bicep compiler checks the declarations offline. What runs for real is a
# version of the shop with a slow start, in the Docker of the `docker` course,
# probed with curl until it answers: the laptop's behaviour, not App Service's.
#
# What is STAGED rather than typed:
#   - shop-web.bicep, warm.py and Dockerfile.warm are taken out of the
#     lesson's own text, and app.py out of lesson 7's, so the files that ran
#     are the files the student reads;
#   - the image is built FROM this machine's python:3.12-slim, which lab.sh
#     rebuilt with the proxy's certificate added; the student's base image has
#     none of it, and the build needs nothing from the network after the pull;
#     the build itself is quiet here, because its output is an image id;
#   - the container and the image are removed at the end.
#
# The probe's count of 503s depends on how fast the container starts, and the
# container id in /version differs on every run.
#
# Recorded 2026-10-30 on Ubuntu 24.04, no Azure account, TZ=America/Sao_Paulo.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"

L7=$HERE/../le-gpjpyeh5
quiet 'docker rm -f shop-warm'

# a parameter's help on one line: the CLI wraps descriptions in a narrow column
ONELINE="awk '/^    --/ {print \"\"} {printf \"%s \", \$0}' | tr -s ' '"

# plans-and-the-web-app
from_lesson "$HERE/plans-and-the-web-app.md" shop-web.bicep > shop-web.bicep

block planhelp
run "az appservice plan create --help | $ONELINE | grep -E -- '^ --(is-linux|number-of-workers|zone-redundant) ' | sed 's/ Global Policy Arguments//'"

block build
run 'bicep build shop-web.bicep'
run "jq -c '.resources[] | {type, name}' shop-web.json"
run "jq -r '.resources[1].properties.siteConfig.linuxFxVersion' shop-web.json"

block port
run "sed \"s/value: '8080'/value: 8080/\" shop-web.bicep > port.bicep"
run 'bicep build port.bicep'

block silent
run "sed 's/DOCKER|/DOCKER:/' shop-web.bicep > colon.bicep"
run 'bicep build colon.bicep'
run "sed '/reserved: true/d' shop-web.bicep > windows.bicep"
run 'bicep build windows.bicep'
run "jq -c '.resources[0].properties' windows.json"

block webhelp
run "az webapp create --help | $ONELINE | grep -E -- '^ --(container-image-name|runtime) '"

# slots
block slothelp
run "az webapp deployment slot create --help | $ONELINE | grep -E -- '^ --configuration-source '"
run "az webapp config appsettings set --help | $ONELINE | grep -E -- '^ --slot-settings ' | sed 's/ Global Policy Arguments//'"

block sticky
run "jq '.resources[3].properties' shop-web.json"

block stickymistakes
run "sed \"s/'slotConfigNames'/'slotSettings'/\" shop-web.bicep > name.bicep"
run 'bicep build name.bicep'
run "sed -n '/appSettingNames/,/]/p' shop-web.bicep"
run "sed \"/appSettingNames: \\[/,/]/c\\    appSettingNames: 'SHOP_ENV'\" shop-web.bicep > list.bicep"
run 'bicep build list.bicep'

block basic
run "sed \"s/name: 'P1v3'/name: 'B1'/\" shop-web.bicep > basic.bicep"
run 'bicep build basic.bicep'
run "jq -c '[.resources[0].sku.name, .resources[2].type]' basic.json"

# swap-with-warm-up
block swaphelp
run "az webapp deployment slot swap --help | sed -n '/^Arguments/,/^\$/p'"

block statuses
run "sed \"s/WARMUP_PING_STATUSES', value: '200'/WARMUP_PING_STATUSES', value: '200;202'/\" shop-web.bicep > statuses.bicep"
run 'bicep build statuses.bicep'

block autoswap
run "sed \"0,/alwaysOn: true/! s/alwaysOn: true/alwaysOn: true\n      autoSwapSlotName: 'production'/\" shop-web.bicep > autoswap.bicep"
run "grep -n autoSwapSlotName autoswap.bicep"
run 'bicep build autoswap.bicep'

quiet 'mkdir -p shop'
from_example "$L7/the-shop-at-home.md" app.py > shop/app.py
from_example "$HERE/swap-with-warm-up.md" warm.py > shop/warm.py
from_lesson "$HERE/swap-with-warm-up.md" Dockerfile.warm > shop/Dockerfile.warm
quiet 'docker build --quiet --tag shop:1.1 --file shop/Dockerfile.warm shop'

block warm
run 'ls shop'
run 'docker run -d --name shop-warm -p 8088:8080 -e SHOP_WARMUP_SECONDS=6 shop:1.1 > /dev/null'
run "for i in \$(seq 1 20); do h=\$(curl -s -o /dev/null -w '%{http_code}' localhost:8088/healthz); r=\$(curl -s -o /dev/null -w '%{http_code}' localhost:8088/robots933456.txt); echo \"\$i  /healthz \$h  /robots933456.txt \$r\"; [ \"\$h\" = 200 ] && break; sleep 1; done"
run 'docker logs shop-warm | grep msg'
run "curl -s -w '\n' localhost:8088/version"

block refusal
run 'az webapp deployment slot swap --resource-group shop --name shop-sp --slot staging --action preview'

quiet 'docker rm -f shop-warm'
quiet 'docker image rm shop:1.1'
