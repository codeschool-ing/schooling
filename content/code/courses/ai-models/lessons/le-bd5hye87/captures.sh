#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of ai-models, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash ../../lab.sh up        # once: Ollama, the models, ~/desk
#   sudo bash captures.sh
#
# A line that starts with ana@desk:~/desk$ is what ana typed and what it
# printed. A program it runs is the student's, shown whole in the lesson and
# taken from it here; a quotation carries no prompt, and is read by
# lab/sources.py at the commit it pins.
#
# huggingface.co and router.huggingface.co were refused by the network of the
# machine this was recorded on (403 from its proxy). So hf_route.py runs
# through the student's relay.py (lesson 9) to Ollama, which shows what
# huggingface_hub's InferenceClient sends, and what a server that does not
# know the router's suffixes does with them. Nothing here plays the router.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture-lib.sh

lab reset >/dev/null

give hf_route.py router.md python 1

relay_up
block router
quote lines hf-providers 135 139
session <<'SH'
export HF_BASE_URL=http://127.0.0.1:8500/v1 HF_TOKEN=ollama MODEL=llama3.2:3b
python hf_route.py
python relay.py show --count 3
python relay.py show --headers authorization,user-agent | head -4
SH
relay_down

block billing
quote lines hf-pricing 3 3
quote lines hf-pricing 9 12
quote lines hf-pricing 24 27
