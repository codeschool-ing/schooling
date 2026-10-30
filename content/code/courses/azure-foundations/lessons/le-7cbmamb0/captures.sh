#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of azure-foundations, as a script
# that produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/azlab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# main.tf is read out of the ```hcl fence of "conditional-access".
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - ~/azure/access is removed before the run;
#   - `terraform init` runs before the first transcript with its output
#     discarded: the prose asks the student to run it, and lesson 6 shows what
#     it prints for this provider.
#
# NOTHING HERE REACHES AZURE OR ENTRA ID. The CLI's client id is read from the
# installed CLI; `terraform plan` stops for want of a sign-in.
#
# NOT PRODUCED HERE, and said so in the prose: security defaults, mandatory
# MFA, any sign-in, the policy's creation and its report-only week, and
# everything about emergency accounts, all of which need a real tenant.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
rm -rf ~/azure/access

block client-id
run "python3 -c 'from azure.cli.core.auth.constants import AZURE_CLI_CLIENT_ID; print(AZURE_CLI_CLIENT_ID)'"

. <(sh_fences "$HERE/conditional-access.md" 1)
at '~/azure/access'
put hcl "$HERE/conditional-access.md" 1 main.tf
terraform init -input=false > /dev/null 2>&1 || { echo "terraform init failed"; exit 1; }

block validate
run 'terraform validate'
run "sed -i 's/\"enabledForReportingButNotEnforced\"/\"reportOnly\"/' main.tf"
run 'terraform validate'
sed -i 's/"reportOnly"/"enabledForReportingButNotEnforced"/' main.tf

block plan
run 'terraform plan -input=false'
