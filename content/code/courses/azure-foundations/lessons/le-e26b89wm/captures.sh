#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of azure-foundations, as a script
# that produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/azlab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# moves.py is read out of the example in "the-table", and the directory is made
# by that section's first ```sh fence.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - ~/azure/moves is removed before the run.
#
# ONE THING REACHES THE INTERNET: moves.py downloads Microsoft's table of move
# support from the GitHub copy of its documentation (raw.githubusercontent.com).
# Microsoft edits that page, so the counts the prose quotes are those of the
# day of recording, and the prose says which day: a later `check` reporting a
# different count is the page changing, not the lab.
#
# NOTHING HERE REACHES AZURE. `az resource invoke-action` and `az resource move`
# stop before sending anything, for want of a sign-in.
#
# NOT PRODUCED HERE, and said so in the prose: any move, its validation, the
# lock on both groups, registration of a provider, and a change of tenant.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
rm -rf ~/azure/moves
S=/subscriptions/bbbbcccc-1111-dddd-2222-eeee3333ffff

. <(sh_fences "$HERE/the-table.md" 1)
at '~/azure/moves'
example "$HERE/the-table.md" moves.py > moves.py || exit 1

block count
run 'python3 moves.py'
block types
run 'python3 moves.py Microsoft.Network/virtualNetworks Microsoft.Network/publicIPAddresses Microsoft.Network/loadBalancers Microsoft.Network/bastionHosts Microsoft.Network/natGateways Microsoft.Network/azureFirewalls Microsoft.Compute/virtualMachines Microsoft.KeyVault/vaults'

block validate
run "az resource invoke-action --action validateMoveResources --ids $S/resourceGroups/rg-shop-prod --request-body '{\"resources\": [\"$S/resourceGroups/rg-shop-prod/providers/Microsoft.Network/virtualNetworks/vnet-shop-prod\"], \"targetResourceGroup\": \"$S/resourceGroups/rg-shop-prod-network\"}'"
block move
run "az resource move --destination-group rg-shop-prod-network --ids $S/resourceGroups/rg-shop-prod/providers/Microsoft.Network/virtualNetworks/vnet-shop-prod"
