#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of azure-foundations, as a script
# that produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/azlab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# The files the student saves are read out of the lesson: overlap.py from the
# example in "peering", hub-side.bicep and peering.bicep from the two
# ```bicep fences of "hub-and-spoke", in order, and main.tf from its ```hcl
# fence.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - ~/azure/peering is removed before the run. Terraform's plugin cache is
#     left as the earlier lessons filled it.
#
# NOTHING HERE REACHES AZURE. `terraform init` asks HashiCorp's registry.
#
# NOT PRODUCED HERE, and said so in the prose: any peering, any packet across
# one, the effective routes of a network interface, and Azure's refusal of a
# peering with both gateway settings on one side.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
rm -rf ~/azure/peering

# ---- peering ---------------------------------------------------------------------
. <(sh_fences "$HERE/peering.md" 1)
at '~/azure/peering'
example "$HERE/peering.md" overlap.py > overlap.py || exit 1
block overlap
run 'python3 overlap.py hub=10.0.0.0/16 prod=10.20.0.0/16 staging=10.30.0.0/16 office=192.168.0.0/16 dev=10.20.128.0/17 partner=10.0.0.0/16'

# ---- hub-and-spoke ---------------------------------------------------------------
put bicep "$HERE/hub-and-spoke.md" 1 hub-side.bicep
put bicep "$HERE/hub-and-spoke.md" 2 peering.bicep
block build
run 'az bicep build --file peering.bicep --stdout | jq -c '"'"'.resources[] | {type, name, subscription: .subscriptionId, group: .resourceGroup}'"'"''

. <(sh_fences "$HERE/hub-and-spoke.md" 1)
at '~/azure/peering/tf'
put hcl "$HERE/hub-and-spoke.md" 1 main.tf
block tf
run 'terraform init -input=false'
run 'terraform validate'
