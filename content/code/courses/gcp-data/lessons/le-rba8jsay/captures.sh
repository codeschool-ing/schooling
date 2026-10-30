#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of gcp-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo FAKE_GCS_BIN=FILE bash ../../lab.sh tools   # once, with the network
#   sudo bash ../../lab.sh run captures.sh
#
# THE LAB IS THE LESSON'S. lab.sh built ~ana from the ```sh fences of
# the-lab.md; this script starts where a student is after "Every time you open
# a terminal", with no emulator running, and starts fake-gcs-server with the
# command of the fifth fence, as the student does in the other terminal.
#
# The failures that need a terminal in a different state are made by unsetting
# what the sixth fence set, inside the command, as a new terminal would have it.
#
# The run has no network at all, so the two blocks that try to reach Google
# (`bq`, and `gcloud` with the endpoint override removed) show what a laptop
# with no route to Google shows; the lesson says so beside them.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/gcp || exit 1
L="$LESSONS/le-rba8jsay"

emu_start gcs || exit 1

block check
run 'gcloud version'
run 'gcloud auth list'
run 'gcloud storage buckets list'
run 'du -sh ~/gcp'

block fail-path
run 'PATH=/usr/bin:/bin; gcloud version'
block fail-nooverride
run 'env -u CLOUDSDK_AUTH_DISABLE_CREDENTIALS gcloud storage buckets list'
block fail-noproject
run 'env -u CLOUDSDK_CORE_PROJECT gcloud storage buckets list'
block fail-noemu
emu_stop gcs
run 'gcloud storage buckets list'
emu_start gcs
block fail-port
run "timeout 10 $(emu_cmd gcs) 2>&1 | tail -3"

block emu-is
emu_stop gcs; emu_start gcs
run 'gcloud storage buckets create gs://quitanda-emu-demo --location=us-east1'
run "gcloud storage buckets describe gs://quitanda-emu-demo --format='value(location,location_type)'"
run 'echo hello > note.txt && gcloud storage cp note.txt gs://quitanda-emu-demo/note.txt'
run "curl -s http://localhost:4443/storage/v1/b/quitanda-emu-demo/o/note.txt?alt=media"
run "gcloud storage objects describe gs://quitanda-emu-demo/note.txt --format='value(acl[0].entity)'"
run 'bq ls'
run 'env -u CLOUDSDK_API_ENDPOINT_OVERRIDES_STORAGE gcloud storage buckets list'
emu_stop gcs; emu_start gcs

block price
run "python3 -c 'print(round(1024 * 0.035, 2), round(1024 * 0.020, 2))'"
run "python3 -c 'print(round(30 * 24 * 60 * 0.005 / 1000, 2), round(1_000_000 * 0.0004 / 1000, 2))'"

# ---- buckets-and-objects: its first fence, run as it stands ------------------
bash -e <(fence "$L/buckets-and-objects.md" 1) || exit 1
block objects-put
run 'gcloud storage buckets create gs://quitanda-raw-prod --location=southamerica-east1'
run 'gcloud storage cp export/orders-2026-10-01.csv gs://quitanda-raw-prod/raw/orders/orders-2026-10-01.csv'
run 'gcloud storage cp export/orders-2026-10-0[23].csv gs://quitanda-raw-prod/raw/orders/'
block objects-list
run 'gcloud storage ls gs://quitanda-raw-prod'
run 'gcloud storage ls --recursive gs://quitanda-raw-prod'
run "curl -s 'http://localhost:4443/storage/v1/b/quitanda-raw-prod/o?prefix=raw/&delimiter=/' | python3 -m json.tool"
block objects-nofolder
run 'gcloud storage objects describe gs://quitanda-raw-prod/raw/orders/'
block objects-replace
run "gcloud storage objects describe gs://quitanda-raw-prod/raw/orders/orders-2026-10-01.csv --format='value(size,md5_hash,generation)'"
run "printf '01-3,c-22,990\n' >> export/orders-2026-10-01.csv && gcloud storage cp export/orders-2026-10-01.csv gs://quitanda-raw-prod/raw/orders/orders-2026-10-01.csv"
run "gcloud storage objects describe gs://quitanda-raw-prod/raw/orders/orders-2026-10-01.csv --format='value(size,md5_hash,generation)'"
run 'gcloud storage hash export/orders-2026-10-01.csv --skip-crc32c'
emu_stop gcs; emu_start gcs

block naming-rules
run 'gcloud storage buckets create gs://qr'
run 'gcloud storage buckets create gs://Quitanda_Raw'
run 'gcloud storage buckets create gs://192.168.5.4'
run 'gcloud storage buckets create gs://quitanda.raw.prod'
run 'gcloud storage buckets create gs://goog-quitanda'
run 'gcloud storage buckets create gs://quitanda-raw-prod'
run 'gcloud storage buckets create gs://quitanda-raw-prod'

block fail-rm
emu_stop gcs; emu_start gcs
gcloud storage buckets create gs://quitanda-raw-dev > /dev/null 2>&1
echo hello > note.txt && gcloud storage cp note.txt gs://quitanda-raw-dev/note.txt > /dev/null 2>&1
run 'gcloud storage rm gs://quitanda-raw-dev/note.txt'
run 'gcloud storage ls gs://quitanda-raw-dev'
