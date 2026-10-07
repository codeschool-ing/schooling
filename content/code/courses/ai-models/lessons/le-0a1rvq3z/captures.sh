#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of ai-models, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash ../../lab.sh up        # once: Ollama, the models, ~/desk
#   sudo bash captures.sh
#
# A line that starts with ana@desk:~/desk$ is what ana typed and what it
# printed. card.py is the student's, shown whole in the lineup section and
# taken from it here.
#
# Nothing here talks to a model. The comparison table is Anthropic's own models
# page, which card.py reads on the day it runs and says so; THE PAGE MOVES, so
# a new run can change the table and the prose has to be read against it. The
# prices and cache fields are LiteLLM's sheet at its pinned commit.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture-lib.sh

lab reset >/dev/null

give card.py lineup.md python 1

block lineup
on 'python card.py all "Claude API ID" "Comparative latency" Pricing'
on 'python sheet.py provider anthropic | grep -v -- "-20[0-9]*  "'

block dates
on 'python card.py all "Reliable knowledge cutoff" Retirement'
on 'python sheet.py retiring --provider anthropic'

block platforms
on 'python card.py "Claude Haiku 4.5" "Claude API ID" "Claude API alias" "Amazon Bedrock ID" "Google Cloud ID" "Microsoft Foundry ID"'

block features
on 'python card.py all Thinking "Default effort" "Context window" "Max output"'
on 'python sheet.py show claude-haiku-4-5 | grep -E "^(input_cost_per_token|cache|prompt_cache|output_cost_per_token)"'
on 'python sheet.py show claude-sonnet-5-5 | grep -E "^prompt_cache_min"'
