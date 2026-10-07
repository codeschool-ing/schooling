#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of ai-models, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo sudo bash ../../lab.sh up        # once: Ollama, the models, ~/desk
#   sudo bash captures.sh
#
# A line that starts with ana@desk:~/desk$ is what ana typed and what it
# printed. or_sort.py is the student's, shown whole in the routing section and
# taken from it here; relay.py is lesson 9's. A quotation carries no prompt.
#
# openrouter.ai was refused by this machine's network, and an OpenRouter key is
# a bill. So the requests go through the relay to Ollama, which answers with
# llama3.2:3b and ignores the fields it does not know: that is what the lesson
# shows, with the request the relay recorded. What OpenRouter does with those
# fields is quoted from its documentation, read at a pinned commit, and nothing
# OpenRouter would have answered is shown as having run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture-lib.sh

lab reset >/dev/null

block one-key
on 'python sheet.py count | head -4'
on 'python sheet.py compare claude-sonnet-4-5 openrouter/anthropic/claude-sonnet-4.5 gemini-2.5-flash openrouter/google/gemini-2.5-flash'
quote quote openrouter-faq "there is no markup|fee when you purchase credits"
quote quote openrouter-fees "getTotalFeeString = |stripe"
quote quote openrouter-usage "upstream_inference_cost.: The|.cost.: The total"

give or_sort.py routing.md python 1
relay_up

block routing
quote quote openrouter-routing "inverse square of the price|9x more likely"
on 'python -c "p = [1, 2, 3]; w = [1 / x**2 for x in p]; print([round(x / sum(w) * 100, 1) for x in w])"'
session <<'CMD'
export OPENROUTER_BASE_URL=http://127.0.0.1:8500/v1 MODEL=llama3.2:3b
python or_sort.py '{"provider": {"order": ["deepinfra", "together"], "allow_fallbacks": false}}'
python relay.py show --body | grep -A6 '"provider"'
CMD
quote quote openrouter-routing "^\| .allow_fallbacks|and then fails if Together fails"

block fallbacks
quote quote openrouter-fallbacks "lets you automatically try other models"
session <<'CMD'
export OPENROUTER_BASE_URL=http://127.0.0.1:8500/v1 MODEL=llama3.2:3b
python or_sort.py '{"models": ["meta-llama/llama-3.3-70b-instruct", "qwen/qwen-2.5-72b-instruct"]}'
python relay.py show --body | grep -A3 '"models"'
CMD
quote quote openrouter-fallbacks "priced using the model that was ultimately used"

block data
quote quote openrouter-routing "^- .allow.: |^- .deny.: |not a definitive source"
session <<'CMD'
export OPENROUTER_BASE_URL=http://127.0.0.1:8500/v1 MODEL=llama3.2:3b
python or_sort.py '{"provider": {"data_collection": "deny"}}'
python relay.py show --body | grep -A2 '"provider"'
CMD

relay_down
