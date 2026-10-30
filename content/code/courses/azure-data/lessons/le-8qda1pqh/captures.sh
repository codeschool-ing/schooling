#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of azure-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# It starts where a student is after lesson 1's "Every time you open a
# terminal", with Azurite started and empty. orders.py is read out of lesson
# 17, main.tf, triggers.tf and schedule.tf out of lesson 19, and export.py,
# clean.py, test_clean.py and runtime.tf out of this lesson, so there is no
# second copy here.
#
# NEITHER DATA FACTORY NOR SPARK IS RUN. The transformation is run by DuckDB
# and PyArrow in one Python process, over files in Azurite; Terraform creates
# nothing and validates offline.
#
# STAGED: the emulators are started by `services` rather than by the
# `docker compose up -d` the student types; lesson 19's three Terraform files
# are written into ~/azure/tf/factory before this lesson's runtime.tf, as the
# student has them from that lesson.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/azure || exit 1
services azurite || exit 1
file_fence "$LESSONS/le-f5tg0ejs/delta-in-a-container.md" orders.py > orders.py || exit 1
file_fence "$HERE/the-same-transform.md" export.py > export.py || exit 1
example "$HERE/the-same-transform.md" clean.py clean.py || exit 1
file_fence "$HERE/testing-it.md" test_clean.py > test_clean.py || exit 1

block night
run 'az storage container create -n raw -o none && az storage container create -n curated -o none'
run 'python export.py export.csv'
run 'head -4 export.csv'
run 'wc -c export.csv'
run 'az storage blob upload -c raw -n orders/2026-10-01.csv -f export.csv -o none'
run 'python clean.py 2026-10-01'
run "az storage blob list -c curated --query '[].{name:name, bytes:properties.contentLength}' -o table"
run 'python clean.py 2026-10-01 | head -1'
run "az storage blob list -c curated --query 'length(@)'"

block test
run 'python test_clean.py'
run "sed -i \"s/replace(total, ',', '.')/replace(total, ',', '')/\" clean.py && python test_clean.py 2>&1 | tail -1; sed -i \"s/replace(total, ',', '')/replace(total, ',', '.')/\" clean.py"

block runtime
mkdir -p ~/azure/tf/factory && cd ~/azure/tf/factory || exit 1
file_fence "$LESSONS/le-7hb9ywv4/declaring-a-pipeline.md" main.tf > main.tf
file_fence "$LESSONS/le-7hb9ywv4/triggers.md" triggers.tf > triggers.tf
file_fence "$LESSONS/le-7hb9ywv4/triggers.md" schedule.tf > schedule.tf
terraform init -no-color > /dev/null || exit 1
file_fence "$HERE/the-clock.md" runtime.tf > runtime.tf
PROMPT_DIR='~/azure/tf/factory'
run 'terraform validate -no-color'
run "sed -i 's/core_count       = 8/core_count       = 4/' runtime.tf && terraform validate -no-color 2>&1 | grep Error; sed -i 's/core_count       = 4/core_count       = 8/' runtime.tf"
run "sed -i 's/\"General\"/\"Small\"/' runtime.tf && terraform validate -no-color 2>&1 | grep Error; sed -i 's/\"Small\"/\"General\"/' runtime.tf"
