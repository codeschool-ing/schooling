#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of azure-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# It starts where a student is after lesson 1's "Every time you open a
# terminal". No emulator is used. main.tf is read out of
# declaring-a-pipeline.md, triggers.tf and schedule.tf out of triggers.md, so
# there is no second copy here.
#
# DATA FACTORY IS NOT RUN, and has no emulator. Terraform creates nothing:
# `validate` reads the files and the azurerm provider's schema, offline, and
# never contacts Azure.
#
# STAGED: nothing.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/azure || exit 1
bash -e <(fence "$HERE/declaring-a-pipeline.md" 1) || exit 1
cd ~/azure/tf/factory || exit 1
file_fence "$HERE/declaring-a-pipeline.md" main.tf > main.tf
PROMPT_DIR='~/azure/tf/factory'

block factory
run "terraform init -no-color | grep -E 'Installing|Installed|successfully'"
run 'terraform validate -no-color'
run "sed -i 's/adf-quitanda-etl-prd/adf_quitanda_etl_prd/' main.tf && terraform validate -no-color 2>&1 | grep Error; sed -i 's/adf_quitanda_etl_prd/adf-quitanda-etl-prd/' main.tf"
run "sed -i 's/type = \"Copy\"/type = \"Cpy\"/' main.tf && terraform validate -no-color; sed -i 's/type = \"Cpy\"/type = \"Copy\"/' main.tf"

block triggers
file_fence "$HERE/triggers.md" triggers.tf > triggers.tf
run 'terraform validate -no-color'
run "sed -i 's/= \"Hour\"/= \"Day\"/' triggers.tf && terraform validate -no-color 2>&1 | grep Error; sed -i 's/= \"Day\"/= \"Hour\"/' triggers.tf"
run "sed -i 's/\"00:30:00\"/\"30m\"/' triggers.tf && terraform validate -no-color 2>&1 | grep Error; sed -i 's/\"30m\"/\"00:30:00\"/' triggers.tf"
run "sed -i 's/max_concurrency = 4/max_concurrency = 60/' triggers.tf && terraform validate -no-color 2>&1 | grep Error; sed -i 's/max_concurrency = 60/max_concurrency = 4/' triggers.tf"
file_fence "$HERE/triggers.md" schedule.tf > schedule.tf
run 'terraform validate -no-color'
run 'terraform fmt -check && echo formatted'
