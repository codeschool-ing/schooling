#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of azure-foundations, as a script
# that produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/azlab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# The files the student saves are read out of the lesson: pip.bicep from the
# ```bicep fence of "tags", inherit.bicep from the ```bicep fence of
# "inheritance", gen_export.py from the ```python fence of "exports" and
# who_spent.py from the example there.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - ~/azure/tags is removed before the run.
#
# ONE COMMAND REACHES THE INTERNET: the `curl` in "inheritance" reads
# Microsoft's built-in policy definition from the Azure/azure-policy
# repository on GitHub. Nothing reaches Azure.
#
# THE COST DATA IS INVENTED, and the prose says so: gen_export.py writes a
# month nobody spent. No real export, cost analysis or tag inheritance setting
# was used.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
rm -rf ~/azure/tags

# ---- tags -------------------------------------------------------------------------
. <(sh_fences "$HERE/tags.md" 1)
at '~/azure/tags'
put bicep "$HERE/tags.md" 1 pip.bicep
block pip
run "az bicep build --file pip.bicep --stdout | jq '{default: .parameters.tags.defaultValue, tags: .resources[0].tags}'"

# ---- inheritance ---------------------------------------------------------------------
block policy
run "curl -sS https://raw.githubusercontent.com/Azure/azure-policy/master/built-in-policies/policyDefinitions/Tags/InheritTag_Add_Modify.json | jq '{name, displayName: .properties.displayName, mode: .properties.mode, effect: .properties.policyRule.then.effect, operation: .properties.policyRule.then.details.operations[0].operation, role: .properties.policyRule.then.details.roleDefinitionIds[0]}'"
put bicep "$HERE/inheritance.md" 1 inherit.bicep
block assignment
run "az bicep build --file inherit.bicep --stdout | jq -c '(.resources[0] | {type, identity, policy: .properties.policyDefinitionId}), .outputs'"

# ---- exports ---------------------------------------------------------------------------
put python "$HERE/exports.md" 1 gen_export.py
example "$HERE/exports.md" who_spent.py > who_spent.py || exit 1
block gen
run 'python3 gen_export.py'
run 'head -4 shop-2026-10.csv'
block who
run 'python3 who_spent.py shop-2026-10.csv'
run 'python3 who_spent.py shop-2026-10.csv --effective'
run 'python3 who_spent.py shop-2026-10.csv --effective --inherit groups.json'
