#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of azure-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# It starts where a student is after "Every time you open a terminal" in
# lesson 1's the-lab.md, with Azurite started and empty. The export file and
# the shell variables are made by the sh fences of the-account-key.md, and the
# Terraform file is read out of the-container-that-leaked.md.
#
# STAGED: Azurite is started by `services` rather than by the `docker compose
# up -d` the student types. A line that only sets a shell variable, such as
# SAS=$(az storage blob generate-sas ...), is run with `keep`, which prints it
# and evaluates it in this script's own shell, because `run` gives every
# command a fresh shell and the student's terminal keeps its variables. The
# expiry dates are computed by `date` at the moment of the run, as the
# commands show.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/azure || exit 1
services azurite || exit 1
keep() { printf 'ana@laptop:%s$ %s\n' "$PROMPT_DIR" "$1"; eval "$1"; export "${1%%=*}"; }

bash -e <(fence "$HERE/the-account-key.md" 1) || exit 1
eval "$(fence "$HERE/the-account-key.md" 2)"

block key
run 'az storage container create -n orders-raw -o none && az storage blob upload -c orders-raw -n exports/2026/10/orders-2026-10-29.csv -f export/orders-2026-10-29.csv --no-progress -o none'
run 'env -u AZURE_STORAGE_CONNECTION_STRING az storage container list --account-name devstoreaccount1 --account-key "$KEY" --blob-endpoint "$ACCOUNT" --query "[].name" -o tsv'
run 'env -u AZURE_STORAGE_CONNECTION_STRING az storage container list --account-name devstoreaccount1 --account-key "${KEY/E/F}" --blob-endpoint "$ACCOUNT" --query "[].name" -o tsv 2>&1'
run 'az storage account keys list -n stquitandadataprd 2>&1 | tail -1'

block anonymous
run 'curl -s -o /dev/null -w "%{http_code}\n" "$BLOB"'
run 'curl -s "$BLOB" | grep -o "<Code>.*</Code>"'

block sas
keep 'SAS=$(az storage blob generate-sas -c orders-raw -n exports/2026/10/orders-2026-10-29.csv --permissions r --expiry "$(date -u -d "+30 minutes" +%Y-%m-%dT%H:%MZ)" -o tsv)'
run 'echo "$SAS" | tr "&" "\n"'
run 'curl -s "$BLOB?$SAS"'
run 'curl -s -X PUT -H "x-ms-blob-type: BlockBlob" --data-binary @export/orders-2026-10-29.csv "$BLOB?$SAS" | grep -o "<Code>.*</Code>"'

block sas-bound
run 'curl -s "$CONTAINER/exports/2026/10/orders-2026-10-28.csv?$SAS" | grep -o "<Code>.*</Code>"'
run 'curl -s "$BLOB?${SAS/sp=r/sp=rw}" | grep -o "<Code>.*</Code>"'
keep 'OLD=$(az storage blob generate-sas -c orders-raw -n exports/2026/10/orders-2026-10-29.csv --permissions r --expiry 2026-10-29T12:00Z -o tsv)'
run 'curl -s -o /dev/null -w "%{http_code}\n" "$BLOB?$OLD"'

block policy
run 'az storage container policy create -c orders-raw -n analysts --permissions rl --expiry "$(date -u -d "+1 day" +%Y-%m-%dT%H:%MZ)" -o none'
run 'az storage container policy list -c orders-raw -o table'
keep 'CSAS=$(az storage container generate-sas -n orders-raw --policy-name analysts -o tsv 2>/dev/null)'
run 'echo "$CSAS" | tr "&" "\n"'
run 'curl -s "$CONTAINER?restype=container&comp=list&$CSAS" | grep -o "<Name>[^<]*</Name>"'
run 'az storage container policy delete -c orders-raw -n analysts -o none'
run 'curl -s "$CONTAINER?restype=container&comp=list&$CSAS" | grep -o "<Code>.*</Code>"'

block public
run 'az storage container set-permission -n orders-raw --public-access blob -o none'
run 'curl -s "$BLOB"'
run 'curl -s "$CONTAINER?restype=container&comp=list" | grep -o "<Code>.*</Code>"'
run 'az storage container set-permission -n orders-raw --public-access container -o none'
run 'curl -s "$CONTAINER?restype=container&comp=list" | grep -o "<Name>[^<]*</Name>"'
run 'az storage container set-permission -n orders-raw --public-access off -o none'
run 'curl -s -o /dev/null -w "%{http_code}\n" "$BLOB"'

block tf-hardened
bash -e <(fence "$HERE/the-container-that-leaked.md" 1) || exit 1
cd ~/azure/tf/hardened && file_fence "$HERE/the-container-that-leaked.md" main.tf > main.tf
PROMPT_DIR='~/azure/tf/hardened'
run "terraform init -no-color | grep -E 'Installing|Installed|successfully'"
run 'terraform validate -no-color'
run "sed -i 's/\"TLS1_2\"/\"TLS1_0\"/' main.tf && terraform validate -no-color"
