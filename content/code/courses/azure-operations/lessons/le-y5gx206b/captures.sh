#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of azure-operations, as a script that
# produces them. Its output is not committed; every transcript was copied from it.
#
#   bash lab.sh student   # once: ~/azure built from "environment"
#   bash captures.sh
#
# STAGED: block old-azurite starts the Azurite image one release older than the
# course pins (3.35.0) on the same ports, to record the refusal a student meets
# when an old image is still on their machine. Block no-azurite stops Azurite
# first. Nothing here reaches Azure: `az group list` fails before it would.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
cd "$HOME/azure" || exit 1
azurite_up
# the fourth sh fence of "environment": what every new terminal types
# shellcheck disable=SC1090
. <(python3 - "$HERE/environment.md" <<'PY'
import re, sys
print(re.findall(r'^```sh\n(.*?)^```$', open(sys.argv[1]).read(), re.S | re.M)[3])
PY
)

block check
run 'az version'
run 'docker ps --format "{{.Names}}  {{.Image}}  {{.Status}}"'
run 'az storage container create --name smoke -o tsv'
run 'az storage container list --query "[].name" -o tsv'
run 'du -sh ~/azure/venv'

block no-login
run 'az group list'

block no-connection-string
( unset AZURE_STORAGE_CONNECTION_STRING; run 'az storage container list --query "[].name" -o tsv' )

block no-azurite
quiet 'docker stop azurite'
run 'az storage container list --query "[].name" -o tsv 2>&1 | tail -1'

block old-azurite
quiet 'docker rm -f azurite'
quiet 'docker run -d --name azurite -p 10000-10002:10000-10002 mcr.microsoft.com/azure-storage/azurite:3.35.0'
sleep 3
run 'az storage container list --query "[].name" -o tsv 2>&1 | grep -m1 "API version"'
lab_down
