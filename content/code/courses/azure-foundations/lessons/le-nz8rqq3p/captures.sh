#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of azure-foundations, as a script
# that produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/azlab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# The files the student saves are read out of the lesson: nsg.bicep from the
# ```bicep fence of "tags-and-groups", nsg.py from the example in
# "packet-walk". The directory comes from the ```sh fence of
# "tags-and-groups".
#
# nsg.py IS THE COURSE'S MODEL OF AN NSG, and the prose says so: every verdict
# below is that program's reading of Microsoft's documented rules, not an
# answer from Azure.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - ~/azure/nsg is removed before the run.
#
# NOTHING HERE REACHES AZURE.
#
# NOT PRODUCED HERE, and said so in the prose: IP flow verify, effective
# security rules, and the health probe actually failing, all of which need
# machines in Azure.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
rm -rf ~/azure/nsg

. <(sh_fences "$HERE/tags-and-groups.md" 1)
at '~/azure/nsg'
put bicep "$HERE/tags-and-groups.md" 1 nsg.bicep
block build
run "az bicep build --file nsg.bicep --outfile nsg.json && jq -c '.resources[] | {type, name}' nsg.json"

example "$HERE/packet-walk.md" nsg.py > nsg.py || exit 1
block draft
run "jq 'del(.resources[2].properties.securityRules[1,2])' nsg.json > draft.json && python3 nsg.py draft.json 10.20.1.4 10.20.2.4 8080"
block draft-ssh
run 'python3 nsg.py draft.json 10.20.1.4 10.20.2.4 22'
block noprobe
run "jq 'del(.resources[2].properties.securityRules[1])' nsg.json > noprobe.json && python3 nsg.py noprobe.json 168.63.129.16 10.20.2.4 8080"
block probe
run 'python3 nsg.py nsg.json 168.63.129.16 10.20.2.4 8080'
block three
run 'python3 nsg.py nsg.json 10.20.1.4 10.20.2.4 22'
run 'python3 nsg.py nsg.json 203.0.113.50 10.20.2.4 8080'
run 'python3 nsg.py nsg.json 10.20.1.4 10.20.2.5 8080'
