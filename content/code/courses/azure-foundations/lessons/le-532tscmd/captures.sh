#!/usr/bin/env bash
# The terminal sessions quoted in lesson 26 of azure-foundations, as a script
# that produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/azlab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# The files the student saves are read out of the lesson: main.bicep from the
# ```bicep fence of "three-doors", main.tf from its ```hcl fence, typo.bicep
# from the ```bicep fence of "compile-and-compare".
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - ~/azure/doors is removed before the run.
#
# NOTHING HERE REACHES AZURE. `az network vnet create`, `terraform plan` and
# `az deployment group what-if` stop before sending anything, for want of a
# sign-in.
#
# NOT PRODUCED HERE, and said so in the prose: the portal, drift, deployment
# modes and deployment stacks, all of which need resources that exist.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
rm -rf ~/azure/doors
. <(sh_fences "$HERE/three-doors.md" 1)
at '~/azure/doors'
block cli
run 'az network vnet create --resource-group rg-shop-prod --name vnet-shop-prod --address-prefixes 10.20.0.0/16 --subnet-name snet-app --subnet-prefixes 10.20.2.0/24'

put bicep "$HERE/three-doors.md" 1 main.bicep
put bicep "$HERE/compile-and-compare.md" 1 typo.bicep
block build
run "az bicep build --file main.bicep && jq -c '.resources[] | {type, apiVersion, name}' main.json"
block decompile
run "jq 'del(.metadata)' main.json > exported.json && az bicep decompile --file exported.json"
run 'diff main.bicep exported.bicep'
block typo
run 'az bicep build --file typo.bicep --stdout > /dev/null'

. <(sh_fences "$HERE/three-doors.md" 2)
at '~/azure/doors/tf'
put hcl "$HERE/three-doors.md" 1 main.tf
block tf
run 'terraform init -input=false'
run 'terraform validate'
run 'terraform fmt -check'
run 'terraform graph'
block plan
run 'terraform plan -input=false'
run 'az deployment group what-if --resource-group rg-shop-prod --template-file ../main.bicep'
