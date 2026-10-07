#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of ai-models, as a script that
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
# Nothing here talks to a model. Google's own pages could not be reached from
# the machine the course was recorded on; every number is LiteLLM's sheet at
# its pinned commit, whose entries for Gemini name Google's pricing page as
# their source.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture-lib.sh

lab reset >/dev/null

block lineup
on 'python sheet.py compare gemini/gemini-3.5-flash-lite gemini/gemini-3.5-flash gemini/gemini-3.1-pro-preview gemini/gemini-flash-latest gemini/gemini-pro-latest'
on 'python sheet.py show gemini/gemini-3.5-flash | grep -E "^(source|rpm|tpm)"'

give tiered.py price-tiers.md python 1

block price-tiers
on 'python sheet.py show gemini/gemini-pro-latest | grep -E "^(input|output)_cost_per_token"'
on 'python sheet.py cost gemini/gemini-pro-latest 300000 1000'
quote quote litellm-cost "If input_tokens > threshold|for all token types"
on 'python tiered.py gemini/gemini-pro-latest 190000 1000; python tiered.py gemini/gemini-pro-latest 210000 1000'

block modalities
on 'python sheet.py show gemini/gemini-3.5-flash | grep -E "^(supported_|input_cost_per_audio|search_context|google_maps)"'

block access
on 'python sheet.py where gemini-3.5-flash'
