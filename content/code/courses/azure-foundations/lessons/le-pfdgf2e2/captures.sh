#!/usr/bin/env bash
# The terminal sessions quoted in lesson 25 of azure-foundations, as a script
# that produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/azlab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# The files the student saves are read out of the lesson: request.py from the
# example in "rest-calls", vnet.bicep and future.bicep from its two ```bicep
# fences, in order.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - ~/azure/arm is removed before the run;
#   - `az group list --debug` is filtered with grep in the command itself, as
#     the lesson shows it, because the rest of its output carries memory
#     addresses and a log file name with the time in it.
#
# ONE COMMAND REACHES THE INTERNET, on purpose: the block `token` asks the real
# Microsoft Entra ID for a token for a tenant and an application that do not
# exist, and quotes the refusal. jq keeps the first sentence of the
# description, since the rest carries a trace id and a time.
#
# NOT PRODUCED HERE, and said so in the prose: anything sent to
# management.azure.com (the 401 and its WWW-Authenticate header, 429 and the
# rate-limit headers, the polling of a long operation), `az provider show` and
# `az provider register`, which need a subscription.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
rm -rf ~/azure/arm

. <(sh_fences "$HERE/the-request-path.md" 1)
at '~/azure/arm'

block token
run "curl -sS -X POST https://login.microsoftonline.com/aaaabbbb-0000-cccc-1111-dddd2222eeee/oauth2/v2.0/token -d grant_type=client_credentials -d client_id=00001111-aaaa-2222-bbbb-3333cccc4444 -d client_secret=not-a-secret -d scope=https://management.azure.com/.default | jq '{error, error_codes, first: (.error_description | split(\". \")[0])}'"
block debug
run "az group list --debug 2>&1 | grep -E 'Command table|client_type=|ERROR: cli'"

put bicep "$HERE/rest-calls.md" 1 vnet.bicep
put bicep "$HERE/rest-calls.md" 2 future.bicep
example "$HERE/rest-calls.md" request.py > request.py || exit 1
block build
run "az bicep build --file vnet.bicep && jq -c '.resources[] | {type, apiVersion, name, dependsOn}' vnet.json"
run 'python3 request.py vnet.json bbbbcccc-1111-dddd-2222-eeee3333ffff rg-shop-prod'
block rest
run 'az rest --method put --url "/subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff/resourceGroups/rg-shop-prod/providers/Microsoft.Network/virtualNetworks/vnet-shop-prod?api-version=2024-05-01" --body @body.json'
block future
run 'az bicep build --file future.bicep --stdout > /dev/null'
