#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of azure-foundations, as a script
# that produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/azlab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# The files the student saves are read out of the lesson: plan.py from the
# example in "cutting-subnets", vnet.bicep from the ```bicep fence of
# "delegation". The directory comes from the first ```sh fence of
# "address-space".
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - ~/azure/vnet is removed before the run.
#
# NOTHING HERE REACHES AZURE. `az network vnet create` stops before sending
# anything, for want of a sign-in; `terraform console` evaluates on its own.
#
# NOT PRODUCED HERE, and said so in the prose: creating the network or a
# delegated subnet, and Azure's own refusals of a subnet outside its range or
# overlapping another, which need Resource Manager.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
rm -rf ~/azure/vnet

# ---- address-space ------------------------------------------------------------
. <(sh_fences "$HERE/address-space.md" 1)
at '~/azure/vnet'
block overlap
run 'for n in 10.0.0.0/16 10.30.0.0/16 192.168.0.0/16 10.0.0.0/8; do python3 -c "import ipaddress as i, sys; print(sys.argv[1], i.ip_network('"'"'10.20.0.0/16'"'"').overlaps(i.ip_network(sys.argv[1])))" $n; done'
block vnet-create
run 'az network vnet create --name vnet-shop-prod --resource-group rg-shop-prod --address-prefixes 10.20.0.0/16'

# ---- cutting-subnets ------------------------------------------------------------
example "$HERE/cutting-subnets.md" plan.py > plan.py || exit 1
block plan-prod
run 'python3 plan.py 10.20.0.0/16 snet-web=10.20.1.0/24 snet-app=10.20.2.0/24 snet-data=10.20.3.0/24 snet-pe=10.20.4.0/24'
block plan-wrong
run 'python3 plan.py 10.20.0.0/16 snet-web=10.20.1.0/24 snet-cache=10.20.1.128/25 snet-jobs=10.20.5.0/23 snet-tiny=10.20.9.0/30 snet-batch=10.30.0.0/24'
block plan-hub
run 'python3 plan.py 10.0.0.0/16 AzureFirewallSubnet=10.0.1.0/26 AzureBastionSubnet=10.0.2.0/26 GatewaySubnet=10.0.255.0/27'

# ---- delegation -------------------------------------------------------------------
put bicep "$HERE/delegation.md" 1 vnet.bicep
block bicep
run "az bicep build --file vnet.bicep --stdout | jq -c '.resources[0].properties.subnets[] | {name, prefix: .properties.addressPrefix, delegatedTo: .properties.delegations[0].properties.serviceName}'"
block outside
run "sed 's#10.20.4.0/24#10.99.4.0/24#' vnet.bicep > outside.bicep && az bicep build --file outside.bicep --stdout | jq -r '.resources[0].properties.subnets[3].properties.addressPrefix'"
block typo
run "sed '0,/defaultOutboundAccess/s//defaultOutbondAccess/' vnet.bicep > typo.bicep && az bicep build --file typo.bicep --stdout | jq -c '.resources[0].properties.subnets[0].properties'"
block cidr
run "echo '[for i in range(1, 5) : cidrsubnet(\"10.20.0.0/16\", 8, i)]' | terraform console"
run "echo 'cidrhost(\"10.20.2.0/24\", 4)' | terraform console"
