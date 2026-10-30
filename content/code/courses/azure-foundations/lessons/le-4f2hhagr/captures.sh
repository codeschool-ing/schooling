#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of azure-foundations, as a script
# that produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/azlab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# The files the student saves are read out of the lesson: roledef.py from the
# example in "role-definitions", can.py from the example in "matching", and
# role.bicep and assign.bicep from the two ```bicep fences of "assignments".
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - ~/azure/rbac is removed before the run.
#
# WHAT REACHES THE INTERNET: roledef.py downloads four pages of Microsoft's
# documentation from raw.githubusercontent.com (MicrosoftDocs/azure-docs). If
# Microsoft edits a built-in role, the transcript changes with it. Nothing
# reaches Azure: `az role definition list` stops for want of a sign-in.
#
# NOT PRODUCED HERE, and said so in the prose: deploying the custom role or
# the assignment, Resource Manager's refusal of an assignment whose name is
# not a GUID, and every evaluation that weighs deny assignments, group
# membership or conditions.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
rm -rf ~/azure/rbac

block role-list
run 'az role definition list --name Contributor'

. <(sh_fences "$HERE/role-definitions.md" 1)
at '~/azure/rbac'
example "$HERE/role-definitions.md" roledef.py > roledef.py || exit 1
example "$HERE/matching.md" can.py > can.py || exit 1

block fetch
run 'python3 roledef.py privileged Contributor > contributor.json'
run 'python3 roledef.py privileged Owner > owner.json'
run 'python3 roledef.py general Reader > reader.json'
run "python3 roledef.py storage 'Storage Blob Data Reader' > blob-reader.json"
run 'jq .permissions contributor.json'
run 'jq -c .permissions owner.json reader.json'
run 'jq -c .permissions blob-reader.json'

block can
run 'python3 can.py Microsoft.Network/virtualNetworks/write contributor.json reader.json owner.json'
run 'python3 can.py Microsoft.Authorization/roleAssignments/write contributor.json owner.json'
run 'python3 can.py --data Microsoft.Storage/storageAccounts/blobServices/containers/blobs/read owner.json contributor.json blob-reader.json'
run 'python3 can.py Microsoft.Storage/storageAccounts/listKeys/action contributor.json reader.json'

put bicep "$HERE/assignments.md" 1 role.bicep
put bicep "$HERE/assignments.md" 2 assign.bicep
block build
run 'az bicep build --file role.bicep --stdout | jq '"'"'{schema: ."$schema", name: .resources[0].name, scopes: .resources[0].properties.assignableScopes}'"'"''
run 'az bicep build --file assign.bicep --stdout | jq '"'"'.resources[0] | {name, roleDefinitionId: .properties.roleDefinitionId}'"'"''
