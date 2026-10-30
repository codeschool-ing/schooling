#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of azure-foundations, as a script
# that produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/azlab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# The files the student saves are read out of the lesson: se.bicep from the
# ```bicep fence of "three-roads", pe.bicep from the one of
# "private-endpoints", and hard.bicep is made by the ```sh fence that follows
# it, as the student makes it.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - ~/azure/private-link is removed before the run.
#
# ONE COMMAND REACHES THE INTERNET: `dig login.microsoftonline.com` asks the
# public DNS. Its answer is Microsoft's to change, and the block `dig-login`
# is expected to differ between runs in the names after the `privatelink`
# link; the prose quotes only the zone names, which have held.
#
# NOT PRODUCED HERE, and said so in the prose: creating the account, the
# endpoint or the zone, and the chain of a real storage account's name, which
# the recording machine's resolver does not answer.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
rm -rf ~/azure/private-link

# ---- three-roads ----------------------------------------------------------------
. <(sh_fences "$HERE/three-roads.md" 1)
at '~/azure/private-link'
put bicep "$HERE/three-roads.md" 1 se.bicep
block se
run 'az bicep build --file se.bicep --stdout | jq '"'"'.resources[] | {type, endpoints: .properties.serviceEndpoints, acls: .properties.networkAcls}'"'"''

# ---- private-endpoints ----------------------------------------------------------
put bicep "$HERE/private-endpoints.md" 1 pe.bicep
block pe
run 'az bicep build --file pe.bicep --stdout | jq -c '"'"'.resources[] | {type, name}'"'"''
bash -e <(sh_fences "$HERE/private-endpoints.md" 1) || exit 1
block lint
run 'az bicep lint --file hard.bicep'

# ---- private-dns ----------------------------------------------------------------
block dig-login
run 'dig login.microsoftonline.com +noall +answer +nottlid | grep CNAME'
