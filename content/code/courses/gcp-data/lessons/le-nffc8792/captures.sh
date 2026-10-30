#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of gcp-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# It starts where a student is after lesson 1's "Every time you open a
# terminal", and starts fake-gcs-server with the command lesson 1 gives, as
# the student does in the other terminal, so the emulator is empty.
# versions.py and lifecycle.json are read out of the fence after their names
# in versioning.md and life-cycle.md, and keep.py out of the example in
# what-versions-cost.md, so none of them has a second copy here.
#
# STAGED: fake-gcs-server runs in the background here; the student runs it in
# the foreground in a terminal of its own. The small files written with printf
# are written in the same command line the student sees. Generation numbers
# and times are the emulator's and change on every run: the script reads them
# back to use in the next command, and the prose quotes none of them.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/gcp || exit 1
B=quitanda-curated-prod
O=customers/customers.csv
E=customers%2Fcustomers.csv

emu_start gcs || exit 1
file_fence "$HERE/versioning.md" versions.py > versions.py || exit 1
file_fence "$HERE/life-cycle.md" lifecycle.json > lifecycle.json || exit 1
example "$HERE/what-versions-cost.md" keep.py ~/gcp/keep.py || exit 1
gen() { python3 versions.py "$B" | awk -v n="$1" 'NR == n { print $1 }'; }

block versioning-on
run "gcloud storage buckets create gs://$B --location=southamerica-east1"
run "gcloud storage buckets describe gs://$B --format='value(versioning_enabled)'"
run "gcloud storage buckets update gs://$B --versioning"
run "gcloud storage buckets describe gs://$B --format='value(versioning_enabled)'"

block versioning-two
run "printf 'customer_id,city\nc-17,Santos\n' > customers.csv && gcloud storage cp customers.csv gs://$B/$O"
run "printf 'customer_id,city\nc-17,Campinas\n' > customers.csv && gcloud storage cp customers.csv gs://$B/$O"
run "gcloud storage ls -a gs://$B/customers/"
run "python3 versions.py $B"
OLD=$(gen 2)
run "curl -s 'http://localhost:4443/storage/v1/b/$B/o/$E?alt=media&generation=$OLD'"

block versioning-delete
run "gcloud storage rm gs://$B/$O"
run "gcloud storage ls gs://$B/customers/"
run "python3 versions.py $B"

block versioning-restore
run "gcloud storage cp gs://$B/$O#$OLD gs://$B/$O"
run "gcloud storage cat gs://$B/$O"
run "python3 versions.py $B"

block versioning-off
run "gcloud storage buckets update gs://$B --no-versioning"
run "printf 'customer_id,city\nc-17,Sorocaba\n' > customers.csv && gcloud storage cp customers.csv gs://$B/$O"
run "python3 versions.py $B"

block keep
run 'python3 keep.py'

block lifecycle
run "gcloud storage buckets create gs://quitanda-raw-prod --location=southamerica-east1"
run "gcloud storage buckets update gs://quitanda-raw-prod --lifecycle-file=lifecycle.json"
run "gcloud storage buckets describe gs://quitanda-raw-prod --format=json"
block lifecycle-check
run "printf '{\"rule\": [{\"action\": {\"type\": \"Teleport\"}, \"condition\": {\"age\": 1}}]}' > odd.json && gcloud storage buckets update gs://quitanda-raw-prod --lifecycle-file=odd.json"
run "printf '{\"rule\": [{\"action\": {\"type\": \"Delete\"}, \"condition\": {\"agee\": 1}}]}' > typo.json && gcloud storage buckets update gs://quitanda-raw-prod --lifecycle-file=typo.json"
block lifecycle-cost
run "python3 -c 'print(round(30 / 30 * 0.035 + 335 / 30 * 0.020 + 2190 / 30 * 0.003, 4), round(2555 / 30 * 0.035, 4))'"

block retention
run "gcloud storage buckets create gs://quitanda-archive-prod --location=southamerica-east1 --retention-period=1y"
run "gcloud storage buckets describe gs://quitanda-archive-prod --format='value(retention_policy)'"
run "printf 'invoice,total_cents\nnf-2026-10-0001,4590\n' > nf.csv && gcloud storage cp nf.csv gs://quitanda-archive-prod/invoices/2026-10/nf.csv"
run "gcloud storage rm gs://quitanda-archive-prod/invoices/2026-10/nf.csv"
run "gcloud storage ls gs://quitanda-archive-prod/invoices/"
run "gcloud storage buckets update gs://quitanda-archive-prod --retention-period=1y && gcloud storage buckets update gs://quitanda-archive-prod --lock-retention-period"

block holds
run "gcloud storage cp nf.csv gs://quitanda-archive-prod/disputes/c-17/order.csv && gcloud storage objects update gs://quitanda-archive-prod/disputes/c-17/order.csv --temporary-hold"
run "gcloud storage objects describe gs://quitanda-archive-prod/disputes/c-17/order.csv --format='value(temporary_hold,event_based_hold)'"
run "gcloud storage rm gs://quitanda-archive-prod/disputes/c-17/order.csv"
run "gcloud storage ls gs://quitanda-archive-prod/disputes/"

block soft-delete
run "gcloud storage buckets describe gs://quitanda-archive-prod --format='value(soft_delete_policy)'"
run "gcloud storage buckets update gs://quitanda-archive-prod --soft-delete-duration=30d"
run "gcloud storage buckets describe gs://quitanda-archive-prod --format='value(soft_delete_policy)'"
run "gcloud storage ls --soft-deleted 'gs://quitanda-archive-prod/**'"

block weak-list
run "curl -s 'http://localhost:4443/storage/v1/b/$B/o?versions=True' | grep -o '\"generation\"' | wc -l"
run "curl -s 'http://localhost:4443/storage/v1/b/$B/o?versions=true' | grep -o '\"generation\"' | wc -l"

block weak-cat
OLD=$(gen 2)
run "gcloud storage cat gs://$B/$O#$OLD"

block weak-rm
run "python3 versions.py $B"
OLD=$(gen 2)
run "gcloud storage rm gs://$B/$O#$OLD"
run "python3 versions.py $B"
