#!/usr/bin/env bash
# The terminal sessions quoted in lesson 25 of gcp-foundations, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/gcplab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# Runs in the lab lesson 1 built (../../from-lessons.sh says how), against an
# empty emulator. ~/gcp/inventory is made fresh with lesson 2's provider.tf,
# changed by the `sed` line of the ```sh fence of "finding-the-forgotten";
# topics.tf is read out of its ```hcl fence.
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson: nothing. The
# apply is real, against the emulator.
#
# REACHES GOOGLE: the blocks `methods` and `method`, which read the Cloud Asset
# API's public discovery document with no credential, and the block `search`,
# which sends the placeholder token to the Cloud Asset API and is refused.
#
# NOT PRODUCED HERE, and said so in the prose: any inventory search that
# answers, a feed, an export, and the history of an asset.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
pubsub_fresh
cd ~/gcp && at '~/gcp'

block help
run 'gcloud asset --help | sed -n "/^GROUPS/,/^NOTES/p" | grep -E "^     [a-z]"'
block methods
run "curl -s 'https://cloudasset.googleapis.com/\$discovery/rest?version=v1' | jq -r '.resources.v1.methods | keys[]'"
block method
run "curl -s 'https://cloudasset.googleapis.com/\$discovery/rest?version=v1' | jq '.resources.v1.methods.searchAllResources | {httpMethod, flatPath, parameters: (.parameters | keys)}'"

tf_dir inventory
sh_fences "$HERE/finding-the-forgotten.md" 1 | grep '^sed ' | bash || exit 1
tf_file "$HERE/finding-the-forgotten.md" 1 topics.tf
block apply
run 'terraform apply -input=false -no-color -auto-approve | grep -E "^(Apply|Error)"'
block byhand
run 'gcloud pubsub topics create scratch-2025'
block lists
run 'terraform state list'
run 'gcloud pubsub topics list --format="value(name.basename())"'
block comm
run "comm -13 <(terraform show -json | jq -r '.values.root_module.resources[].values.name' | sort) <(gcloud pubsub topics list --format=\"value(name.basename())\" | sort)"

cd ~/gcp && at '~/gcp'
net
block search
run 'gcloud asset search-all-resources --scope=organizations/123456789012 --query="NOT labels.team:*" --asset-types=pubsub.googleapis.com/Topic'
