#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of azure-foundations, as a script
# that produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/azlab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# app.bicep is read out of the ```bicep fence of "two-kinds", who.py out of the
# example in "default-credential", and the directory is made by the ```sh
# fence of "two-kinds".
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - ~/azure/identity is removed before the run.
#
# WHAT REACHES THE NETWORK: in block `chain`, the Azure Identity library's own
# ManagedIdentityCredential looks for the platform's token endpoint, which does
# not exist on this machine, and reports it unavailable; nothing else in that
# block leaves the machine. In block `env`, EnvironmentCredential asks
# login.microsoftonline.com for the made-up tenant's discovery document, which
# Entra ID refuses (AADSTS90002). No request reaches Resource Manager.
#
# NOT PRODUCED HERE, and said so in the prose: a token from the Instance
# Metadata Service or App Service's identity endpoint, which need a resource
# running on Azure, and deploying app.bicep.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
rm -rf ~/azure/identity

. <(sh_fences "$HERE/two-kinds.md" 1)
at '~/azure/identity'
put bicep "$HERE/two-kinds.md" 1 app.bicep
example "$HERE/default-credential.md" who.py > who.py || exit 1

block build
run "az bicep build --file app.bicep --stdout | jq '{identity: .resources[] | select(.type == \"Microsoft.Web/sites\") | .identity, outputs}'"

block chain
run 'python3 who.py'

block env
run 'AZURE_TENANT_ID=aaaabbbb-0000-cccc-1111-dddd2222eeee AZURE_CLIENT_ID=00001111-aaaa-2222-bbbb-3333cccc4444 AZURE_CLIENT_SECRET=not-a-secret python3 who.py'
