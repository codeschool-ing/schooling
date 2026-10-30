#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of azure-foundations, as a script
# that produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/azlab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# The files the student saves are read out of the lesson: breakeven.py from the
# example in "three-ways", vm.bicep from the ```bicep fence of "hybrid-benefit".
# The `sed` that makes the misspelt copy is typed in the transcript.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - ~/azure/bill is removed before the run.
#
# NOTHING HERE REACHES AZURE, OR ANY PRICE. The two prices given to
# breakeven.py are round numbers the lesson invents and says it invents.
#
# NOT PRODUCED HERE, and said so in the prose: buying a reservation or a savings
# plan, any real price (prices.azure.com is not reachable from this machine),
# Hybrid Benefit on a real machine, and everything in "a-wrong-bill", which
# reads a real billing account.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
rm -rf ~/azure/bill

# ---- three-ways ----------------------------------------------------------------
. <(sh_fences "$HERE/three-ways.md" 1)
at '~/azure/bill'
example "$HERE/three-ways.md" breakeven.py > breakeven.py || exit 1
block breakeven
run 'python3 breakeven.py 1.00 0.60'
run 'python3 breakeven.py 1.00 0.40'

# ---- hybrid-benefit ---------------------------------------------------------------
put bicep "$HERE/hybrid-benefit.md" 1 vm.bicep
block vm
run "az bicep build --file vm.bicep --stdout | jq -c '.resources[0] | {name, licenseType: .properties.licenseType}'"
run "sed \"s/'Windows_Server'/'Windows_Sever'/\" vm.bicep > typo.bicep"
run "az bicep build --file typo.bicep --stdout | jq -c '.resources[0] | {name, licenseType: .properties.licenseType}'"
