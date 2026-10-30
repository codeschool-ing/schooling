#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of azure-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# It starts where a student is after "Every time you open a terminal" in
# the-lab.md, with Azurite started and empty; the Terraform files are read out
# of storage-accounts.md and naming.md, so there is no second copy here.
#
# STAGED: the emulators are started by `services` rather than by the
# `docker compose up -d` the student types; the failures in when-it-fails.md
# are produced by undoing one line of the lab each, as the commands
# themselves show, except the taken port: a python3 http.server holds
# 127.0.0.1:10000 while Azurite is stopped, standing in for the other program.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/azure || exit 1
services azurite || exit 1

block check
run "az version --query '\"azure-cli\"' -o tsv"
run 'terraform version | head -1'
run "docker compose ps --format '{{.Service}} {{.State}}'"
run 'az storage container list -o table'
run 'az storage container create -n smoke-test'
run "az storage container list --query '[].name' -o tsv"
run 'az storage account show-connection-string -n devstoreaccount1 2>&1 | tail -1'

block url
run 'az storage blob url -c orders -n exports/2026-10-29.csv -o tsv'

block tf-account
bash -e <(fence "$HERE/storage-accounts.md" 1) || exit 1
cd ~/azure/tf/account && file_fence "$HERE/storage-accounts.md" main.tf > main.tf
PROMPT_DIR='~/azure/tf/account'
run "terraform init -no-color | grep -E 'Installing|Installed|successfully'"
run 'terraform validate -no-color'
run "sed -i 's/\"ZRS\"/\"ZZRS\"/' main.tf && terraform validate -no-color"
PROMPT_DIR='~/azure'
cd ~/azure

block naming
cd ~/azure/tf/account && file_fence "$HERE/storage-accounts.md" main.tf > main.tf
PROMPT_DIR='~/azure/tf/account'
run "sed -i 's/stquitandadataprd/st-quitanda-data-prd/' main.tf && terraform validate -no-color 2>&1 | grep Error"
run "sed -i 's/st-quitanda-data-prd/stquitandadataanalyticsprd/' main.tf && terraform validate -no-color 2>&1 | grep Error"
PROMPT_DIR='~/azure'
cd ~/azure
run 'az storage container create -n Orders 2>&1 | head -2'
run 'az storage container create -n or 2>&1 | head -2'
run 'az storage container create -n orders-raw'
run 'echo x > x.csv && az storage blob upload -c orders-raw -n "exports/2026/10/29/orders.csv" -f x.csv -o none 2>/dev/null && az storage blob list -c orders-raw --query "[].name" -o tsv'

block ru
file_fence "$HERE/what-the-emulators-are.md" ru.py > ru.py
run 'docker compose --profile cosmos up -d 2>&1 | tail -1'
for _ in $(seq 60); do curl -s -o /dev/null http://127.0.0.1:8081/ && break; sleep 1; done; sleep 10
run 'python ru.py'

block fail-path
run 'PATH=/usr/bin:/bin; az version'
block fail-cs
run 'env -u AZURE_STORAGE_CONNECTION_STRING az storage container list -o table 2>&1 | tail -3'
block fail-down
run 'docker compose stop azurite 2>&1 | tail -1'
run 'az storage container list -o table 2>&1 | tail -3'
run 'docker compose up -d 2>&1 | tail -1'
block fail-port
docker compose stop azurite > /dev/null 2>&1
setsid python3 -m http.server 10000 --bind 127.0.0.1 > /dev/null 2>&1 < /dev/null &
squatter=$!
sleep 1
run 'docker compose up -d 2>&1 | tail -1'
kill "$squatter"
