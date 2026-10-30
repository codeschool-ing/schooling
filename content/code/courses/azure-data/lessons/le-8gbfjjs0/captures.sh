#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of azure-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# It starts where a student is after lesson 1's "Every time you open a
# terminal". No emulator is used. main.tf is read out of
# declaring-a-workspace.md, so there is no second copy here.
#
# DATABRICKS IS NOT RUN, and has no emulator. Terraform creates nothing:
# `validate` reads the file and the azurerm provider's schema, offline, and
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
bash -e <(fence "$HERE/declaring-a-workspace.md" 1) || exit 1
cd ~/azure/tf/databricks || exit 1
file_fence "$HERE/declaring-a-workspace.md" main.tf > main.tf
PROMPT_DIR='~/azure/tf/databricks'

block workspace
run "terraform init -no-color | grep -E 'Installing|Installed|successfully'"
run 'terraform validate -no-color'
run "sed -i 's/= \"premium\"/= \"gold\"/' main.tf && terraform validate -no-color 2>&1 | grep Error; sed -i 's/= \"gold\"/= \"premium\"/' main.tf"
run 'terraform fmt -check && echo formatted'
