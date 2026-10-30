#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of azure-foundations, as a script
# that produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/azlab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# The files the student saves are read out of the lesson: route.py from the
# example in "system-routes", rt.bicep from the ```bicep fence of
# "route-tables", fwpolicy.bicep from the one of "firewall-and-tunnelling".
# The directory comes from the ```sh fence of "system-routes".
#
# route.py IS THE COURSE'S MODEL OF ROUTE SELECTION, and the prose says so:
# every route it marks chosen is that program's reading of Microsoft's
# documented rules, not an answer from Azure.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - ~/azure/routes is removed before the run.
#
# NOTHING HERE REACHES AZURE.
#
# NOT PRODUCED HERE, and said so in the prose: effective routes, next hop,
# the firewall itself and forced tunnelling, all of which need Azure.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
rm -rf ~/azure/routes

. <(sh_fences "$HERE/system-routes.md" 1)
at '~/azure/routes'
example "$HERE/system-routes.md" route.py > route.py || exit 1
block none
run 'python3 route.py - 203.0.113.80'

put bicep "$HERE/route-tables.md" 1 rt.bicep
block rt
run "az bicep build --file rt.bicep --outfile rt.json && jq -c '.resources[0].properties.routes[] | [.name, .properties.addressPrefix, .properties.nextHopIpAddress]' rt.json"
block six
for d in 203.0.113.80 10.20.3.4 10.30.1.4 10.99.0.1 10.0.1.4 192.168.10.5; do
  run "python3 route.py rt.json $d"
done

put bicep "$HERE/firewall-and-tunnelling.md" 1 fwpolicy.bicep
block policy
run "az bicep build --file fwpolicy.bicep --stdout | jq -c '.resources[] | select(.type | endswith(\"ruleCollectionGroups\")) | .properties.ruleCollections[] | {name, priority, action: .action.type, rules: [.rules[] | {ruleType, name}]}'"
