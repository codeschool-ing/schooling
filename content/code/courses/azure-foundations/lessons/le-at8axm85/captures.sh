#!/usr/bin/env bash
# The terminal sessions quoted in lesson 23 of azure-foundations, as a script
# that produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/azlab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# vpn.bicep is read out of the ```bicep fence of "the-tunnel-in-bicep", the
# directory is made by that section's first ```sh fence, and leaky.bicep by its
# second, the `sed` line the student types.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - ~/azure/hybrid is removed before the run.
#
# NOTHING HERE REACHES AZURE OR THE INTERNET: both commands are the Bicep
# compiler, on this machine.
#
# NOT PRODUCED HERE, and said so in the prose: deploying the gateway, the local
# network gateway or the connection, the 45 minutes a gateway takes, failover,
# BGP sessions, and everything about ExpressRoute, which needs Azure and a
# carrier.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
rm -rf ~/azure/hybrid
SEC="$HERE/the-tunnel-in-bicep.md"

. <(sh_fences "$SEC" 1)
at '~/azure/hybrid'
put bicep "$SEC" 1 vpn.bicep

block vpn
run "az bicep build --file vpn.bicep --stdout | jq -c '.parameters, [.resources[] | {type, name}]'"

bash -e <(sh_fences "$SEC" 2) || { echo "the sed fence failed"; exit 1; }
block leaky
run 'az bicep build --file leaky.bicep --stdout > /dev/null'
rm -f leaky.bicep
