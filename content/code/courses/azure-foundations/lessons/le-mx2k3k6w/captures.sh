#!/usr/bin/env bash
# The terminal sessions quoted in lesson 22 of azure-foundations, as a script
# that produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/azlab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# lb.bicep is read out of the ```bicep fence of "load-balancer", and the
# directory is made by that section's ```sh fence.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - ~/azure/balancing is removed before the run.
#
# WHAT REACHES THE INTERNET: three questions to the public DNS, through the
# recording machine's resolver. The CNAME chains of portal.azure.com and
# mcr.microsoft.com are Microsoft's to change, and a later run may print other
# names; the addresses at the end of each chain and the TTLs are left out on
# purpose, because they differ on every query. login.microsoftonline.com was
# tried first and dropped: on the recording day it answered through
# trafficmanager.net on one query and akadns.net on the next.
#
# NOT PRODUCED HERE, and said so in the prose: deploying the load balancer, an
# Application Gateway, a Traffic Manager profile or a Front Door, all of which
# need Azure.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
rm -rf ~/azure/balancing

. <(sh_fences "$HERE/load-balancer.md" 1)
at '~/azure/balancing'
put bicep "$HERE/load-balancer.md" 1 lb.bicep

block lb
run "az bicep build --file lb.bicep --stdout | jq -c '.resources[] | {type, name, zones, sku: .sku.name}'"

block portal
run 'dig portal.azure.com +noall +answer +nottlid | grep CNAME'
block mcr
run 'dig mcr.microsoft.com +noall +answer +nottlid | grep CNAME'
block nx
run 'dig shop-azure-foundations-l22.trafficmanager.net +noall +comments | grep -o "status: [A-Z]*"'
