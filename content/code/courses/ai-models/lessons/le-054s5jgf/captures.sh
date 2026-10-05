#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of ai-models, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash ../../lab.sh up        # once: the machine, the SDKs, the documents
#   bash captures.sh
#
# A line that starts with ana@desk:~/desk$ is what ana typed and what it
# printed. STAGED rather than typed: the lab itself (lab.sh reset).
#
# Nothing here talks to a model. OpenAI's own pages could not be reached from
# the machine the course was recorded on: the prices, windows and dates are
# LiteLLM's sheet at its pinned commit, and the reasoning settings are read out
# of OpenAI's Python SDK, at the version lab.sh pins, which is generated from
# OpenAI's API specification.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@desk:~/desk$ %s\n' "$*"; lab exec ana "$*" 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }

lab reset >/dev/null

block lineup
on 'sheet compare gpt-5.4-nano gpt-5.4-mini gpt-5.4 gpt-5.5 gpt-6-luna gpt-6-sol gpt-6-astra'

block reasoning
on 'sheet compare o1 o3 o3-mini o4-mini'
on 'sheet retiring --provider openai | grep -E "  o[0-9]"'
on 'python -c "import typing, openai.types.shared.reasoning_effort as r; print(typing.get_args(r.ReasoningEffort)[0])"'
on 'sheet show gpt-5.4-mini | grep -E "reasoning"'
on 'sheet show gpt-5.5 | grep -E "reasoning"'

block retirements
on 'sheet retiring --provider openai | grep -E "  gpt-4"'

block access
on 'sheet where gpt-5.4-mini'
on 'sheet show gpt-5.4-mini | grep supported_endpoints'
