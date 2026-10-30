#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of azure-foundations, as a script
# that produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/azlab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# IT BUILDS THE STUDENT'S LAB FROM THE LESSON ITSELF, into an empty home. The
# section "setting-up" is read out of its ```sh fences and run as it stands:
# fence 2 installs the Azure CLI and the Azure Identity library, fence 3
# Terraform, fence 4 writes ~/azure/env.sh, fence 5 is the line typed into
# every terminal and fence 6 fetches the Bicep CLI. The first fence, apt-get,
# needs sudo and is not run: the script checks that its packages are installed
# and stops if one is missing. The lab this leaves behind is the one every other
# lesson's capture runs in.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson:
#   - in `failure-arch` the Arm build of Terraform is unpacked over the right
#     one in ~/.local/bin for one command, and the right one is put back.
#
# NOTHING HERE REACHES AZURE. The downloads go to the Python Package Index,
# releases.hashicorp.com and downloads.bicep.azure.com; `az account show`,
# `az account list-locations` and `az group list` refuse before sending
# anything, because nobody has signed in.
#
# NOT PRODUCED HERE, and said so in the prose: the missing python3-venv (the
# machine has the package and the failure needs it absent), a failed download
# of Bicep, and everything in "a-real-account", which needs an Azure account.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
SETUP="$HERE/setting-up.md"
SCRATCH=$(mktemp -d)
trap 'rm -rf "$SCRATCH"' EXIT

mkdir -p "$LAB_ROOT"
exec 9>"$LAB_ROOT/capture.lock"
flock 9
clean_env
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 PYTHONDONTWRITEBYTECODE=1
export PATH="${PYTHON3_DIR:+$PYTHON3_DIR:}/usr/local/bin:/usr/bin:/bin"
rm -rf "$LAB_HOME" && mkdir -p "$LAB_HOME" && export HOME=$LAB_HOME
cd "$HOME" || exit 1

installed() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'install ok installed'; }
for p in python3 python3.12-venv curl jq unzip bind9-dnsutils; do
  installed "$p" || { echo "install first, as in the first fence: $p"; exit 1; }
done

fence() {
  sh_fences "$SETUP" "$1" > "$SCRATCH/fence-$1.sh" || exit 1
  bash -e "$SCRATCH/fence-$1.sh" > "$SCRATCH/fence-$1.log" 2>&1 \
    || { echo "fence $1 of setting-up.md failed:"; cat "$SCRATCH/fence-$1.log"; exit 1; }
}

# ---- the lab, built by the section's own commands ---------------------------
fence 2          # the Azure CLI and Azure Identity
fence 3          # Terraform
fence 4          # env.sh
cd ~/azure || exit 1

block failure-path
# a new terminal, which opens in the home directory and has not read env.sh
cd ~ && at '~'
run 'az version'
cd ~/azure && at '~/azure'

# shellcheck disable=SC1090
. <(sh_fences "$SETUP" 5)
cd ~/azure || exit 1
fence 6          # the Bicep CLI, once

block check
run 'az version'
run 'az bicep version'
run 'terraform version'
run 'az account show'
run 'cd ~ && du -sh azure/venv azure/.azure .local/bin/terraform'

block failure-arch
mkdir -p "$SCRATCH/arm"
curl -sS -o "$SCRATCH/arm/terraform.zip" https://releases.hashicorp.com/terraform/1.17.1/terraform_1.17.1_linux_arm64.zip
cp ~/.local/bin/terraform "$SCRATCH/terraform.amd64"
unzip -qo "$SCRATCH/arm/terraform.zip" terraform -d ~/.local/bin
run 'terraform version'
cp "$SCRATCH/terraform.amd64" ~/.local/bin/terraform

block failure-signin
run 'az group list'

block clouds
run 'az cloud list --output table'
run 'az cloud show --name AzureCloud --query "{resourceManager: endpoints.resourceManager, signIn: endpoints.activeDirectory, storage: suffixes.storageEndpoint}"'

block locations
run 'az account list-locations --output table'
