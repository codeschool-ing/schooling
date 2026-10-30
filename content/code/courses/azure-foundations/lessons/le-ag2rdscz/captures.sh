#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of azure-foundations, as a script
# that produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/azlab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# The files the student saves are read out of the lesson: rid.py from the
# example in "resource-ids", tree.bicep, rg.bicep and wrong.bicep from the
# three ```bicep fences of "four-scopes", in order, and main.tf from its
# ```hcl fence.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - ~/azure/hierarchy is removed before the run, and Microsoft's provider is
#     removed from Terraform's plugin cache, so that `terraform init` downloads
#     it as it does the first time a student runs it.
#
# NOTHING HERE REACHES AZURE. `terraform init` downloads from HashiCorp's
# registry; `az group create` and `terraform plan` stop before sending
# anything, for want of a sign-in.
#
# NOT PRODUCED HERE, and said so in the prose: creating any of the four boxes,
# and the four `az deployment ... create` commands, which need Azure.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
rm -rf ~/azure/hierarchy "$TF_PLUGIN_CACHE_DIR/registry.terraform.io/hashicorp/azurerm"
S=/subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff

block group-create
run 'az group create --name rg-shop-prod --location brazilsouth'

# ---- resource-ids -------------------------------------------------------------
. <(sh_fences "$HERE/resource-ids.md" 1)
at '~/azure/hierarchy'
example "$HERE/resource-ids.md" rid.py > rid.py || exit 1
block rid
run "python3 rid.py /subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff/resourceGroups/rg-shop-prod/providers/Microsoft.Network/virtualNetworks/vnet-shop-prod/subnets/snet-app /subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff/resourceGroups/rg-shop-prod /providers/Microsoft.Management/managementGroups/mg-shop /subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff/resourcegroups/RG-SHOP-PROD/providers/microsoft.network/virtualnetworks/vnet-shop-prod"

# ---- four-scopes ----------------------------------------------------------------
put bicep "$HERE/four-scopes.md" 1 tree.bicep
put bicep "$HERE/four-scopes.md" 2 rg.bicep
put bicep "$HERE/four-scopes.md" 3 wrong.bicep
block tree
run 'az bicep build --file tree.bicep --stdout | jq '"'"'{schema: ."$schema", resources: [.resources[] | {type, name, parent: .properties.details.parent.id}]}'"'"''
block rg
run 'az bicep build --file rg.bicep --stdout | jq -c '"'"'."$schema", .outputs'"'"''
run 'az bicep build --file wrong.bicep --stdout'

. <(sh_fences "$HERE/four-scopes.md" 1)
at '~/azure/hierarchy/tf'
put hcl "$HERE/four-scopes.md" 1 main.tf
block tf
run 'terraform init -input=false'
run 'terraform validate'
run 'terraform plan -input=false'
