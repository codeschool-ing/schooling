#!/usr/bin/env bash
# The terminal sessions quoted in lesson 25 of azure-data (Microsoft
# Purview), as a script that produces them. Every transcript in the lesson
# was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# NOTHING HERE IS PURVIEW, which has no emulator. make_export.py and
# classify.py are the course's own programs, read out of classification.md,
# run against Azurite; the Terraform file is read out of
# data-map-and-scans.md and only validated.
#
# STAGED: Azurite is started by `services`, as in every lesson.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/azure || exit 1
services azurite || exit 1
file_fence "$HERE/classification.md" make_export.py > make_export.py || exit 1
example "$HERE/classification.md" classify.py classify.py || exit 1

block export
run 'python make_export.py > customers.csv && head -4 customers.csv'
run 'az storage container create -n quitanda-raw -o none && az storage blob upload -c quitanda-raw -n exports/2026-10-29/customers.csv -f customers.csv --no-progress -o none'
block classify
run 'python classify.py quitanda-raw exports/2026-10-29/customers.csv'
block low
run "sed 's/^THRESHOLD = 0.6/THRESHOLD = 0.1/' classify.py > classify_low.py && python classify_low.py quitanda-raw exports/2026-10-29/customers.csv | grep -E 'cpf|tracking|notes'"

block tf
bash -e <(fence "$HERE/data-map-and-scans.md" 1) || exit 1
cd ~/azure/tf/purview && file_fence "$HERE/data-map-and-scans.md" main.tf > main.tf
PROMPT_DIR='~/azure/tf/purview'
run "terraform init -no-color | grep -E 'Installing|Installed|successfully'"
run 'terraform validate -no-color'
PROMPT_DIR='~/azure'
