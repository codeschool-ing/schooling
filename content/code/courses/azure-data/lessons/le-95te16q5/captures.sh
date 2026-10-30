#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of azure-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# It starts where a student is after "Every time you open a terminal" in
# lesson 1's the-lab.md, with Azurite started and empty. seed.py, rename.py and
# the Terraform files are read out of the sections that show them, so there is
# no second copy here.
#
# STAGED: Azurite is started by `services` rather than by the `docker compose
# up -d` the student types. The Terraform mistakes are made with sed, as the
# commands show, and undone before the next one.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/azure || exit 1
services azurite || exit 1

block seed
file_fence "$HERE/renaming-on-a-flat-namespace.md" seed.py > seed.py
example "$HERE/renaming-on-a-flat-namespace.md" rename.py rename.py
run 'python seed.py'

block crash
run 'python rename.py clicks/2026/10/29/ clicks/date=2026-10-29/ 400'
run 'az storage blob list -c lake --prefix clicks/2026/10/29/ --num-results 5000 --query "length(@)"'
run 'az storage blob list -c lake --prefix clicks/date=2026-10-29/ --num-results 5000 --query "length(@)"'

block finish
run 'python rename.py clicks/2026/10/29/ clicks/date=2026-10-29/'
run 'az storage blob list -c lake --prefix clicks/2026/10/29/ --num-results 5000 --query "length(@)"'
run 'az storage blob list -c lake --prefix clicks/date=2026-10-29/ --num-results 5000 --query "length(@)"'

block fs
run 'az storage fs create -n lake2 -o none && az storage container list --query "[].name" -o tsv'
run 'az storage fs directory create -f lake2 -n raw 2>&1 | tail -2'
run 'curl -s -i -X PUT -H "x-ms-version: 2026-06-06" "http://127.0.0.1:10000/devstoreaccount1/lake2/raw?resource=directory" | tr -d "\r"'

block tf-lake
bash -e <(fence "$HERE/the-dfs-endpoint.md" 1) || exit 1
cd ~/azure/tf/lake && file_fence "$HERE/the-dfs-endpoint.md" main.tf > main.tf
PROMPT_DIR='~/azure/tf/lake'
run "terraform init -no-color | grep -E 'Installing|Installed|successfully'"
run 'terraform validate -no-color'
run "sed -i 's/= \"directory\"/= \"file\"/' main.tf && terraform validate -no-color"
sed -i 's/= "file"/= "directory"/' main.tf

block tf-acl
file_fence "$HERE/acls.md" acl.tf > acl.tf
run 'terraform validate -no-color'
run "sed -i '0,/\"r-x\"/s//\"read\"/' acl.tf && terraform validate -no-color"
sed -i 's/"read"/"r-x"/' acl.tf
run "sed -i '0,/\"group\"/s//\"role\"/' acl.tf && terraform validate -no-color"
PROMPT_DIR='~/azure'
cd ~/azure

block hns-show
run 'az storage account show -n stquitandalakeprd --query isHnsEnabled 2>&1 | tail -1'
