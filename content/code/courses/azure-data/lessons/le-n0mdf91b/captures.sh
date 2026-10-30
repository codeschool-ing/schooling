#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of azure-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# It starts where a student is after "Every time you open a terminal" in
# lesson 1's the-lab.md, with Azurite started and empty. The export file, the
# Terraform file, rehydrate.py and year.py are read out of the sections that
# show them, so there is no second copy here.
#
# STAGED: Azurite is started by `services` rather than by the `docker compose
# up -d` the student types. year.py's output is printed under its example
# without a prompt, so it runs outside `run`. The Terraform mistake is made
# with sed, as the command shows.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/azure || exit 1
services azurite || exit 1

bash -e <(fence "$HERE/setting-a-tier.md" 1) || exit 1

block upload
run 'az storage container create -n orders-archive -o none'
run 'az storage blob upload -c orders-archive -n orders/2026-09/default.csv -f export/orders-2026-09.csv --no-progress -o none'
run 'az storage blob upload -c orders-archive -n orders/2026-09/cool.csv -f export/orders-2026-09.csv --tier Cool --no-progress -o none'
run 'az storage blob show -c orders-archive -n orders/2026-09/default.csv --query "properties.[blobTier, blobTierInferred, blobTierChangeTime]" -o tsv'
run 'az storage blob show -c orders-archive -n orders/2026-09/cool.csv --query "properties.[blobTier, blobTierInferred, blobTierChangeTime]" -o tsv'

block set-tier
run 'az storage blob set-tier -c orders-archive -n orders/2026-09/default.csv --tier Cold'
run 'az storage blob show -c orders-archive -n orders/2026-09/default.csv --query "properties.[blobTier, blobTierInferred, blobTierChangeTime]" -o tsv'
run 'az storage blob set-tier -c orders-archive -n orders/2026-09/default.csv --tier Frozen 2>&1 | cut -d, -f1-4'
run 'az storage blob upload -c orders-archive -n logs/app.log -f export/orders-2026-09.csv --type append --no-progress -o none'
run 'az storage blob set-tier -c orders-archive -n logs/app.log --tier Cool 2>&1 | grep ErrorCode'

block tf-tiers
bash -e <(fence "$HERE/setting-a-tier.md" 2) || exit 1
cd ~/azure/tf/tiers && file_fence "$HERE/setting-a-tier.md" main.tf > main.tf
PROMPT_DIR='~/azure/tf/tiers'
run "terraform init -no-color | grep -E 'Installing|Installed|successfully'"
run 'terraform validate -no-color'
run "sed -i 's/\"Cool\"/\"Archive\"/' main.tf && terraform validate -no-color"
PROMPT_DIR='~/azure'
cd ~/azure

block archive
run 'az storage blob set-tier -c orders-archive -n orders/2026-09/cool.csv --tier Archive'
run 'az storage blob download -c orders-archive -n orders/2026-09/cool.csv -f back.csv --no-progress 2>&1 | grep -E "ERROR|ErrorCode"'
run 'az storage blob show -c orders-archive -n orders/2026-09/cool.csv --query "{tier:properties.blobTier, size:properties.contentLength}"'

block rehydrate
run 'az storage blob set-tier -c orders-archive -n orders/2026-09/cool.csv --tier Hot --rehydrate-priority Standard'
run 'az storage blob show -c orders-archive -n orders/2026-09/cool.csv --query "properties.[blobTier, rehydrationStatus]" -o tsv'
run 'az storage blob download -c orders-archive -n orders/2026-09/cool.csv -f back.csv --no-progress -o none && cat back.csv'

block copy-cli
run 'az storage blob copy start -c orders-archive -b restored/cool.csv --source-container orders-archive --source-blob orders/2026-09/cool.csv --tier Hot --rehydrate-priority High 2>&1 | grep ErrorCode'

block copy
file_fence "$HERE/archived-blobs.md" rehydrate.py > rehydrate.py
run 'python rehydrate.py'

block delete
run 'az storage blob delete -c orders-archive -n orders/2026-09/default.csv'
run 'az storage blob list -c orders-archive --prefix orders/2026-09/ --query "[].[name, properties.blobTier]" -o tsv'

block year-out
example "$HERE/a-terabyte-a-year.md" year.py year.py
python year.py 2>&1
