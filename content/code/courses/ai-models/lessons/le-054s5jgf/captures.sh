#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of ai-models, as a script that
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
# Nothing here talks to a model. OpenAI's own pages could not be reached from
# the machine the course was recorded on: the prices, windows and dates are
# LiteLLM's sheet at its pinned commit, and the reasoning settings are read out
# of OpenAI's Python SDK, at the version lesson 1 installs, which is generated from
# OpenAI's API specification.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture-lib.sh

lab reset >/dev/null

block lineup
on 'python sheet.py compare gpt-5.4-nano gpt-5.4-mini gpt-5.4 gpt-5.5 gpt-6-luna gpt-6-sol gpt-6-astra'

block reasoning
on 'python sheet.py compare o1 o3 o3-mini o4-mini'
on 'python sheet.py retiring --provider openai | grep -E "  o[0-9]"'
on 'python -c "import typing, openai.types.shared.reasoning_effort as r; print(typing.get_args(r.ReasoningEffort)[0])"'
on 'python sheet.py show gpt-5.4-mini | grep -E "reasoning"'
on 'python sheet.py show gpt-5.5 | grep -E "reasoning"'

block retirements
on 'python sheet.py retiring --provider openai | grep -E "  gpt-4"'

block access
on 'python sheet.py where gpt-5.4-mini'
on 'python sheet.py show gpt-5.4-mini | grep supported_endpoints'
