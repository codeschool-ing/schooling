#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of gcp-operations.
#
#   bash lab.sh tools    # once: the cryptography package from envelope.md
#   bash captures.sh
#
# envelope.py is taken out of the lesson; its KEK versions are files, as it
# says, standing for Cloud KMS. The Terraform plan is local, with the fake
# token; the data source for the Cloud Storage service agent cannot be read
# without Google, which the plan shows.

HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../capture.sh
. "$HERE/../../capture.sh"
mkdir -p "$HOME/gcp/vault" && cd "$HOME/gcp/vault" || exit 1
rm -f kek/v1.bin kek/v2.bin kek/v3.bin order-1001.json order-1002.json
from_lesson "$HERE/envelope.md" envelope.py > ../envelope.py

block first
run 'python3 ../envelope.py rotate'
run "python3 ../envelope.py encrypt order-1001.json 'card ending 4242, R\$ 43.80'"
run "jq -c '{kek_version, wrapped_dek: .wrapped_dek[:24], ciphertext: .ciphertext[:24]}' order-1001.json"
block rotate
run 'python3 ../envelope.py rotate'
run "python3 ../envelope.py encrypt order-1002.json 'pix, R\$ 18.90'"
run 'python3 ../envelope.py decrypt order-1001.json'
run 'python3 ../envelope.py decrypt order-1002.json'
run 'ls kek'
block destroy
run 'rm kek/v1.bin'
run 'python3 ../envelope.py decrypt order-1001.json 2>&1 | tail -1'
run 'python3 ../envelope.py decrypt order-1002.json'

cd "$HOME/gcp" || exit 1
export GOOGLE_OAUTH_ACCESS_TOKEN=fake
rm -rf tf/kms && mkdir -p tf/kms && cd tf/kms || exit 1
from_lesson "$HERE/keys.md" tf/kms/main.tf > main.tf
quiet 'terraform init -input=false'
block plan
run 'terraform validate -no-color'
run 'terraform plan -input=false -no-color 2>&1 | grep -E "Error|^  # |Plan:" | head -6'
