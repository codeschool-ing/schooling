#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of gcp-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# It starts where a student is after lesson 1's "Every time you open a
# terminal", and starts fake-gcs-server with the command lesson 1 gives, as
# the student does in the other terminal, so the emulator is empty. The
# September export is made by the first ```sh fence of on-upload.md, run as it
# stands, and year.py is read out of the example in a-terabyte-a-year.md, so
# neither has a second copy here.
#
# STAGED: fake-gcs-server runs in the background here; the student runs it in
# the foreground in a terminal of its own. Generation numbers and times are
# the emulator's and change on every run; the prose quotes none of them.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/gcp || exit 1
B=quitanda-archive-prod
K=orders/2026-09

emu_start gcs || exit 1

block price-arith
run "python3 -c 'print(round(0.035 / 0.003, 1), round(1024 * 0.003 * 365 / 30, 2), round(1024 * 0.003 * 10 / 30, 2))'"

bash -e <(fence "$HERE/on-upload.md" 1) || exit 1
block upload-classes
run "gcloud storage buckets create gs://$B --location=southamerica-east1"
run "gcloud storage cp export/orders-2026-09.csv gs://$B/$K/standard.csv"
run "gcloud storage cp export/orders-2026-09.csv gs://$B/$K/nearline.csv --storage-class=NEARLINE"
run "gcloud storage cp export/orders-2026-09.csv gs://$B/$K/coldline.csv --storage-class=COLDLINE"
run "gcloud storage cp export/orders-2026-09.csv gs://$B/$K/archive.csv --storage-class=ARCHIVE"
run "gcloud storage objects list 'gs://$B/$K/*' --format='table(name,storage_class,size)'"
run "gcloud storage objects describe gs://$B/$K/nearline.csv --format='yaml(storage_class,storage_class_update_time,size,generation)'"

block upload-names
run "gcloud storage cp export/orders-2026-09.csv gs://$B/$K/lower.csv --storage-class=nearline"
run "gcloud storage cp export/orders-2026-09.csv gs://$B/$K/glacier.csv --storage-class=GLACIER"
run "gcloud storage objects list gs://$B/$K/lower.csv gs://$B/$K/glacier.csv --format='table(name,storage_class)'"

block bucket-default
run "gcloud storage buckets create gs://quitanda-raw-dev --location=southamerica-east1 --default-storage-class=NEARLINE"
run "gcloud storage buckets describe gs://quitanda-raw-dev --format='value(default_storage_class)'"
run "gcloud storage cp export/orders-2026-09.csv gs://quitanda-raw-dev/$K/orders.csv"
run "gcloud storage objects describe gs://quitanda-raw-dev/$K/orders.csv --format='value(storage_class)'"
run "gcloud storage buckets update gs://quitanda-raw-dev --default-storage-class=COLDLINE"
run "gcloud storage buckets describe gs://quitanda-raw-dev --format='value(default_storage_class)'"

block class-change
run "gcloud storage objects describe gs://$B/$K/standard.csv --format='value(storage_class,generation,creation_time)'"
run "gcloud storage objects update gs://$B/$K/standard.csv --storage-class=COLDLINE"
run "gcloud storage objects describe gs://$B/$K/standard.csv --format='value(storage_class,generation,creation_time)'"
run "gcloud storage objects update gs://$B/$K/nearline.csv --storage-class=ARCHIVE"
run "gcloud storage objects describe gs://$B/$K/nearline.csv --format='value(storage_class,generation)'"

block read-archive
run "gcloud storage cat gs://$B/$K/archive.csv | head -3"
run "gcloud storage cp gs://$B/$K/archive.csv back.csv && wc -c back.csv"
run "gcloud storage restore --help | sed -n '/^DESCRIPTION/,/^EXAMPLES/p' | head -8"
run "python3 -c 'print(1024 * 0.01, 1024 * 0.02, 1024 * 0.05)'"

block photos
run "python3 -c 'gib = 2_000_000 * 300_000 / 2**30; print(round(gib, 1)); [print(c, round(gib * p * 12, 2), round(2_000_000 / 1000 * a, 2)) for c, p, a in ((\"Standard\", 0.035, 0.005), (\"Archive\", 0.003, 0.05))]'"

block autoclass
run "gcloud storage buckets create gs://quitanda-logs-prod --location=southamerica-east1 --enable-autoclass --autoclass-terminal-storage-class=ARCHIVE"
run "gcloud storage buckets describe gs://quitanda-logs-prod --format=json"
run "curl -s http://localhost:4443/storage/v1/b/quitanda-logs-prod | grep -c -i autoclass"
block autoclass-fee
run "python3 -c 'keep = 128 / 1024**2 * 0.035; fee = 0.0025 / 1000; print(f\"{keep:.8f} {fee:.8f} {fee / keep:.0%}\")'"
run "python3 -c 'keep = 1 / 1024 * 0.035; fee = 0.0025 / 1000; print(f\"{keep:.8f} {fee:.8f} {fee / keep:.1%}\")'"

example "$HERE/a-terabyte-a-year.md" year.py ~/gcp/year.py || exit 1
block year
run 'python3 year.py'
run "python3 -c 'print(round((86.016 - 36.864) / (51.2 - 20.48), 1), round((245.76 - 86.016) / (20.48 - 10.24), 1))'"

block short-stay
run "python3 -c 'for name, price, least in [(\"Standard\", 0.035, 0), (\"Nearline\", 0.020, 30), (\"Coldline\", 0.007, 90), (\"Archive\", 0.003, 365)]: print(f\"{name:<10}{1024 * price * max(60, least) / 30:>7.2f}\")'"
