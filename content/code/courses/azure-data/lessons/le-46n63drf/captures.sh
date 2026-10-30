#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of azure-data, as a script that
# produces them. Every transcript in the lesson was copied from its output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# THE PROGRAMS ARE THE LESSON'S: session.py is the schooling-example of
# session-tokens.md, overriding.py and main.tf are the fences those names
# introduce in overriding.md and regions.md. Nothing is copied here.
#
# STAGED: the Cosmos DB emulator is started empty by `services`, where the
# student types `docker compose --profile cosmos up -d`. The Terraform provider
# comes from the plugin cache lesson 1 set up, and `validate` asks Azure
# nothing: no account was created and none exists.
#
# Recorded 2026-10-30 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/azure || exit 1
services cosmos || exit 1

example "$HERE/session-tokens.md" session.py session.py
file_fence "$HERE/overriding.md" overriding.py > overriding.py

block session
run 'python session.py'

block override
run 'python overriding.py'

block regions
bash -e <(fence "$HERE/regions.md" 1) || exit 1
cd ~/azure/tf/cosmos && file_fence "$HERE/regions.md" main.tf > main.tf
PROMPT_DIR='~/azure/tf/cosmos'
run "terraform init -no-color | grep -E 'Installing|Installed|successfully'"
run 'terraform validate -no-color'
run "sed -i 's/\"Session\"/\"BoundedStaleness\"\n    max_interval_in_seconds = 1/' main.tf && terraform validate -no-color"
file_fence "$HERE/regions.md" main.tf > main.tf
run "sed -i 's/\"Session\"/\"Strong\"/; s/_enabled = false/_enabled = true/' main.tf && terraform validate -no-color"
PROMPT_DIR='~/azure'
