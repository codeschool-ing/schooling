#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of azure-foundations, as a script
# that produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/azlab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# main.tf is read out of the ```hcl fence of "administrative-units", and the
# directory is made by the first ```sh fence of "the-directory".
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - ~/azure/entra is removed before the run, and the azuread provider is
#     removed from Terraform's plugin cache, so that `terraform init` downloads
#     it as it does the first time a student runs it.
#
# TWO REQUESTS REACH MICROSOFT ENTRA ID, with no credentials: the discovery
# document of `organizations`, and the discovery document of the made-up
# tenant, which Entra ID refuses with AADSTS90002. The refusal's Trace ID and
# timestamp differ on every run, so the jq filter in the command cuts them off.
# `terraform init` downloads from HashiCorp's registry. `az ad user list` and
# `terraform plan` stop before sending anything, for want of a sign-in.
#
# NOT PRODUCED HERE, and said so in the prose: anything Microsoft Graph would
# answer, such as listing users or creating the group, the unit and the
# invitation.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
rm -rf ~/azure/entra "$TF_PLUGIN_CACHE_DIR/registry.terraform.io/hashicorp/azuread"

. <(sh_fences "$HERE/the-directory.md" 1)
at '~/azure/entra'

block discovery
run "curl -sS https://login.microsoftonline.com/organizations/v2.0/.well-known/openid-configuration | jq '{issuer, authorization_endpoint, token_endpoint, jwks_uri}'"
block no-tenant
run "curl -sS https://login.microsoftonline.com/aaaabbbb-0000-cccc-1111-dddd2222eeee/v2.0/.well-known/openid-configuration | jq '{error, error_codes, error_description: (.error_description | split(\" Trace ID\")[0])}'"

block user-list
run 'az ad user list --display-name Bia'

put hcl "$HERE/administrative-units.md" 1 main.tf
block tf
run 'terraform init -input=false'
run 'terraform validate'
run 'terraform plan -input=false'
