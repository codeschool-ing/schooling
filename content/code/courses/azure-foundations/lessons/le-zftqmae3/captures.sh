#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of azure-foundations, as a script
# that produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/azlab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# main.tf is read out of the ```hcl fence of "declaring-it", and the two
# edits are the section's own ```sh fences 2 and the `sed` it names inline.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - ~/azure/pim is removed before the run;
#   - `terraform init` runs before the first transcript with its output
#     discarded: the prose asks the student to run it, and lesson 2 already
#     shows what it prints.
#
# NOTHING HERE REACHES AZURE. `terraform plan` stops for want of a sign-in.
#
# NOT PRODUCED HERE, and said so in the prose: everything about PIM itself,
# which needs a real tenant and a licence; activating, approving, the audit
# history, notifications and access reviews; the role management policy.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
rm -rf ~/azure/pim

. <(sh_fences "$HERE/declaring-it.md" 1)
at '~/azure/pim'
put hcl "$HERE/declaring-it.md" 1 main.tf
terraform init -input=false > /dev/null 2>&1 || { echo "terraform init failed"; exit 1; }

block valid
run 'terraform validate'

bash -e <(sh_fences "$HERE/declaring-it.md" 2) || exit 1
block conflict
run 'terraform validate'
sed -i '/end_date_time/d' main.tf

block plan
run 'terraform plan -input=false'
