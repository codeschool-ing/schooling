#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of azure-foundations, as a script
# that produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/azlab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# The directory and allowed-locations.json come from the first ```sh fence of
# "definitions", run as it stands; policy.bicep is the ```bicep fence of
# "assignments".
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - ~/azure/policy is removed before the run.
#
# THREE DOWNLOADS REACH THE INTERNET, all from the GitHub copy of Azure Policy's
# built-in definitions (raw.githubusercontent.com/Azure/azure-policy). Microsoft
# revises built-ins, so a later `check` may report a new version number: that
# is the repository changing, not the lab.
#
# NOTHING HERE REACHES AZURE. `az policy definition show` and
# `az policy state trigger-scan` stop before sending anything, for want of a
# sign-in.
#
# NOT PRODUCED HERE, and said so in the prose: deploying the assignments, any
# deny, modify or audit, the evaluation cycle, remediation and exemptions.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
rm -rf ~/azure/policy

. <(sh_fences "$HERE/definitions.md" 1)
at '~/azure/policy'
block builtin
run "jq '{name, displayName: .properties.displayName, mode: .properties.mode, version: .properties.version, effects: .properties.parameters.effect.allowedValues}' allowed-locations.json"
block rule
run "jq '.properties.policyRule' allowed-locations.json"
block rg-builtin
run "curl -sS https://raw.githubusercontent.com/Azure/azure-policy/master/built-in-policies/policyDefinitions/General/ResourceGroupAllowedLocations_Deny.json | jq -c '[.name, .properties.displayName, .properties.mode]'"
block arm
run 'az policy definition show --name e56962a6-4747-49cd-b67b-bf8b01975c4c'

put bicep "$HERE/assignments.md" 1 policy.bicep
block compile
run "az bicep build --file policy.bicep --stdout | jq -c '.\"\$schema\", [.resources[] | [.type, .name]]'"
block brackets
run "az bicep build --file policy.bicep --stdout | jq -c '.resources[0].properties.policyRule.then, .resources[2].properties.policyDefinitionId'"

block inherit
run "curl -sS https://raw.githubusercontent.com/Azure/azure-policy/master/built-in-policies/policyDefinitions/Tags/InheritTag_Add_Modify.json | jq '{displayName: .properties.displayName, effect: .properties.policyRule.then.effect, roles: .properties.policyRule.then.details.roleDefinitionIds}'"
block scan
run 'az policy state trigger-scan --resource-group rg-shop-prod'
