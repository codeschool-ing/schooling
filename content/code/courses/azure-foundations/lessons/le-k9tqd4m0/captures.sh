#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of azure-foundations, as a script
# that produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/azlab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# main.tf is read out of the ```hcl fence of "app-and-principal", and the
# directory is made by that section's ```sh fence.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - ~/azure/deploy is removed before the run. The azuread provider is left in
#     the plugin cache, where lesson 6 put it: the first `init` downloads it all
#     the same, because the directory has no lock file yet, and the block
#     `reinit` shows a second `init` in the same directory taking it from the
#     cache.
#
# ONE REQUEST REACHES MICROSOFT ENTRA ID: the client-credentials request in
# "credentials", with the made-up client id and the string `not-a-secret`,
# which Entra ID refuses with AADSTS700016. Its Trace ID and timestamp differ
# on every run, so the jq filter in the command cuts them off. `terraform plan`
# stops before sending anything, for want of a sign-in.
#
# NOT PRODUCED HERE, and said so in the prose: creating the registration, the
# service principal or a secret, and the token exchange with GitHub, which
# needs a GitHub job and a real tenant.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
rm -rf ~/azure/deploy
[ -d "$TF_PLUGIN_CACHE_DIR/registry.terraform.io/hashicorp/azuread" ] || { echo "run lesson 6's captures first"; exit 1; }

. <(sh_fences "$HERE/app-and-principal.md" 1)
at '~/azure/deploy'
put hcl "$HERE/app-and-principal.md" 1 main.tf

block tf
run 'terraform init -input=false'
run 'terraform validate'
run "sed -i 's/AzureADMyOrg/AzureADMyTenant/' main.tf && terraform validate"
run "sed -i 's/AzureADMyTenant/AzureADMyOrg/' main.tf"

block reinit
run "rm -rf .terraform && terraform init -input=false | grep -E 'Reusing|Using'"

block token
run "curl -sS -X POST https://login.microsoftonline.com/organizations/oauth2/v2.0/token -d client_id=00001111-aaaa-2222-bbbb-3333cccc4444 -d client_secret=not-a-secret -d grant_type=client_credentials -d scope=https://management.azure.com/.default | jq '{error, error_codes, error_description: (.error_description | split(\" Trace ID\")[0])}'"

block plan
run 'terraform plan -input=false'
