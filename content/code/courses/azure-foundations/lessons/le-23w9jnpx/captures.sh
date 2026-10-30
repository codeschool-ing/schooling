#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of azure-foundations, as a script
# that produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/azlab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# The directory comes from the first ```sh fence of "alz-tree", and alz.bicep
# from its ```bicep fence.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - ~/azure/alz is removed before the run;
#   - the stack command names lesson 4's ~/azure/policy/policy.bicep. If that
#     file is not in the lab, it is written from lesson 4's own fence, as a
#     student who did lesson 4 has it.
#
# NOTHING HERE REACHES AZURE OR THE INTERNET. `az stack mg create` and
# `az ts create` stop before sending anything, for want of a sign-in.
#
# NOT PRODUCED HERE, and said so in the prose: deploying the tree, the stack or
# the template spec, the deny assignment, subscription vending, and everything
# about Blueprints, which is taught from Microsoft's retirement page.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
rm -rf ~/azure/alz
if [ ! -f ~/azure/policy/policy.bicep ]; then
  mkdir -p ~/azure/policy
  put bicep "$HERE/../le-bzdcjxtv/assignments.md" 1 ~/azure/policy/policy.bicep
fi

. <(sh_fences "$HERE/alz-tree.md" 1)
at '~/azure/alz'
put bicep "$HERE/alz-tree.md" 1 alz.bicep
block compile
run "az bicep build --file alz.bicep --stdout | jq -c '.\"\$schema\", (.resources | map({type, name, copy}))'"

block stack
run 'az stack mg create --name shop-guardrails --management-group-id shop --location brazilsouth --template-file ../policy/policy.bicep --action-on-unmanage detachAll --deny-settings-mode denyDelete'
block ts
run 'az ts create --name ts-shop-alz --version 1.0 --resource-group rg-shop-platform --location brazilsouth --template-file alz.bicep'
