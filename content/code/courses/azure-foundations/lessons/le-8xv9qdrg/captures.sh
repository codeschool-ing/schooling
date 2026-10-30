#!/usr/bin/env bash
# The terminal sessions quoted in lesson 24 of azure-foundations, as a script
# that produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/azlab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - ~/azure/cli is removed before the run, and the default group the lesson
#     sets is unset again by the lesson's own last command, so no other lesson
#     inherits it.
#
# NOTHING HERE REACHES AZURE. Every command is answered by the Azure CLI's own
# installation, or refused by it for want of a sign-in.
#
# NOT PRODUCED HERE, and said so in the prose: `az extension add`, whose index
# lives at an address the recording machine cannot reach; everything about
# Azure PowerShell, whose module comes from the PowerShell Gallery, which the
# recording machine cannot reach either; and Cloud Shell, which needs an account.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
rm -rf ~/azure/cli
az config unset defaults.group >/dev/null 2>&1

. <(sh_fences "$HERE/the-cli.md" 1)
at '~/azure/cli'

block help
run "az group create --help | sed -n '1,12p'"
block missing
run 'az group create'
block config
run 'az config set defaults.group=rg-shop-prod'
run 'az config get defaults'
run 'az config unset defaults.group'
block extensions
run 'az extension list'

block formats
run 'az cloud list --query "[].name" --output tsv'
run 'az cloud list --query "[].{name: name, active: isActive}" --output table'
run 'az cloud show --query "{resourceManager: endpoints.resourceManager}" --output yaml'
run 'az cloud show --query endpoints.resourceManager --output json'
block query
run "az cloud list --query \"[?name=='AzureCloud'].endpoints.resourceManager | [0]\" --output tsv"
run 'az cloud list --query "length([])"'
run 'az cloud list --query "sort_by([], &name)[].{name: name, active: isActive}"'
block accounts
run 'az account list; echo "exit code $?"'
