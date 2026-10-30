#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of azure-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# It starts where a student is after "Every time you open a terminal" in
# lesson 1's the-lab.md, with Azurite started and empty. The export files are
# made by the first sh fence of containers-and-blobs.md, and every program is
# read out of the section that shows it, so there is no second copy here.
#
# STAGED: Azurite is started by `services` rather than by the `docker compose
# up -d` the student types. The outputs of blocks.py and etag.py are printed
# under their examples without a prompt, so they are run outside `run`.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/azure || exit 1
services azurite || exit 1

bash -e <(fence "$HERE/containers-and-blobs.md" 1) || exit 1

block upload
run 'az storage container create -n orders-raw'
run 'az storage blob upload-batch -d orders-raw -s export --destination-path exports/2026/10 --no-progress -o none'
run 'az storage blob list -c orders-raw --query "[].name" -o tsv'

block prefix
run 'az storage blob list -c orders-raw --query "[].name" -o tsv --delimiter /'
run 'az storage blob list -c orders-raw --query "[].name" -o tsv --delimiter / --prefix exports/2026/'
run 'az storage blob show -c orders-raw -n exports/2026/ 2>&1 | tail -1'
run 'az storage blob exists -c orders-raw -n EXPORTS/2026/10/orders-2026-10-27.csv'

block blocks-out
example "$HERE/block-blobs.md" blocks.py blocks.py
python blocks.py 2>&1

block split
file_fence "$HERE/block-blobs.md" split.py > split.py
run 'python split.py'

block append
file_fence "$HERE/append-and-page-blobs.md" applog.py > applog.py
run 'python applog.py'
run 'python applog.py'

block append-gone
run 'az storage blob upload -c app-logs -n checkout/2026-10-30.log -f export/orders-2026-10-27.csv --overwrite --no-progress -o none'
run 'az storage blob show -c app-logs -n checkout/2026-10-30.log --query "[properties.blobType, properties.contentLength]" -o tsv'
run 'python applog.py 2>&1 | grep ErrorCode'

block pages
file_fence "$HERE/append-and-page-blobs.md" pages.py > pages.py
run 'python pages.py'

block props
run 'az storage blob show -c orders-raw -n exports/2026/10/orders-2026-10-27.csv --query "{type:properties.blobType, size:properties.contentLength, contentType:properties.contentSettings.contentType, contentMd5:properties.contentSettings.contentMd5, etag:properties.etag, blobTier:properties.blobTier}"'
run 'openssl dgst -md5 -binary export/orders-2026-10-27.csv | base64'

block meta
run 'az storage blob show -c orders-raw -n exports/2026/10/orders-2026-10-27.csv --query properties.etag -o tsv'
run 'az storage blob metadata update -c orders-raw -n exports/2026/10/orders-2026-10-27.csv --metadata source=shop rows=2 -o none'
run 'az storage blob metadata show -c orders-raw -n exports/2026/10/orders-2026-10-27.csv'
run 'az storage blob show -c orders-raw -n exports/2026/10/orders-2026-10-27.csv --query properties.etag -o tsv'
run 'az storage blob metadata update -c orders-raw -n exports/2026/10/orders-2026-10-27.csv --metadata rows=3 -o none'
run 'az storage blob metadata show -c orders-raw -n exports/2026/10/orders-2026-10-27.csv'
run 'az storage blob metadata update -c orders-raw -n exports/2026/10/orders-2026-10-27.csv --metadata row-count=3 2>&1 | grep ErrorCode'

block cond-cli
run 'az storage blob upload -c orders-raw -n exports/2026/10/orders-2026-10-27.csv -f export/orders-2026-10-28.csv --no-progress 2>&1 | grep ErrorCode'
run 'az storage blob upload -c orders-raw -n exports/2026/10/orders-2026-10-27.csv -f export/orders-2026-10-28.csv --overwrite --if-none-match "*" --no-progress 2>&1 | grep ErrorCode'
run 'az storage blob upload -c orders-raw -n exports/2026/10/orders-2026-10-27.csv -f export/orders-2026-10-28.csv --overwrite --if-match "\"0x8D0000000000000\"" --no-progress 2>&1 | grep ErrorCode'
run 'az storage blob upload -c orders-raw -n exports/2026/10/orders-2026-10-27.csv -f export/orders-2026-10-28.csv --overwrite --if-match "$(az storage blob show -c orders-raw -n exports/2026/10/orders-2026-10-27.csv --query properties.etag -o tsv)" --no-progress -o none && echo written'

block etag-out
example "$HERE/conditional-writes.md" etag.py etag.py
python etag.py 2>&1

block lease
run 'az storage blob lease acquire -c orders-raw -b control/last-export.txt --lease-duration 15 -o tsv | wc -c'
run 'az storage blob upload -c orders-raw -n control/last-export.txt -f export/orders-2026-10-28.csv --overwrite --no-progress 2>&1 | grep ErrorCode'
