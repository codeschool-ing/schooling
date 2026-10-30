#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of azure-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# It starts where a student is after "Every time you open a terminal" in
# lesson 1's the-lab.md, with Azurite started and empty. The Terraform files
# and the programs are read out of the sections that show them, so there is
# no second copy here.
#
# STAGED: Azurite is started by `services` rather than by the `docker compose
# up -d` the student types. Each Terraform mistake is made with sed, as the
# command shows, and undone before the next file is added.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/azure || exit 1
services azurite || exit 1

block tf-account
bash -e <(fence "$HERE/soft-delete.md" 1) || exit 1
cd ~/azure/tf/protect && file_fence "$HERE/soft-delete.md" account.tf > account.tf
PROMPT_DIR='~/azure/tf/protect'
run "terraform init -no-color | grep -E 'Installing|Installed|successfully'"
run 'terraform validate -no-color'
run "sed -i 's/days = 14/days = 400/' account.tf && terraform validate -no-color"
sed -i 's/days = 400/days = 14/' account.tf

block tf-lifecycle
file_fence "$HERE/life-cycle.md" lifecycle.tf > lifecycle.tf
run 'terraform validate -no-color'
run "sed -i 's/\"blockBlob\"/\"BlockBlob\"/' lifecycle.tf && terraform validate -no-color"
sed -i 's/"BlockBlob"/"blockBlob"/' lifecycle.tf

block tf-audit
file_fence "$HERE/immutability.md" audit.tf > audit.tf
run 'terraform validate -no-color'
run "sed -i 's/= 2557/= 0/' audit.tf && terraform validate -no-color"
PROMPT_DIR='~/azure'
cd ~/azure

block snapshot
file_fence "$HERE/versioning.md" snapshot.py > snapshot.py
run 'python snapshot.py'

block soft-delete
run 'az storage blob service-properties delete-policy update --enable true --days-retained 7'
run 'printf "date,rate\n2026-10-29,5.41\n" > rates.csv && az storage blob upload -c finance -n rates.csv -f rates.csv --no-progress -o none'
run 'az storage blob delete -c finance -n rates.csv'
run 'az storage blob list -c finance --include d --prefix rates.csv --query "[].{name:name, deleted:deleted}"'
run 'az storage blob undelete -c finance -n rates.csv 2>&1 | grep -E "ERROR|ErrorCode"'

block versioning
file_fence "$HERE/where-azurite-is-weaker.md" versions.py > versions.py
run 'az storage account blob-service-properties update -n devstoreaccount1 --enable-versioning true 2>&1 | tail -1'
run 'python versions.py'

block immutability
file_fence "$HERE/where-azurite-is-weaker.md" protect.py > protect.py
run 'python protect.py'
