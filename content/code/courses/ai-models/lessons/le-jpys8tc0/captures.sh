#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of ai-models, as a script that
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
# Nothing here talks to a model. The licences are the projects' own files at
# the commits sources.py pins; the prices, windows and deprecation dates are
# LiteLLM's sheet at the commit sheet.py pins, a third party's copy of the
# providers' pages.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@desk:~/desk$ %s\n' "$*"; lab exec ana "$*" 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }

lab reset >/dev/null

block three-kinds
on 'sources quote deepseek-r1-readme "^This code repository and the model weights"'
on 'sources quote llama3.1-licence "Grant of Rights"'

block licences
on 'sources quote llama3.1-licence "700 million"'
on 'sources quote qwen-licence "100 million|improve any other large"'
on 'sources quote llama3.1-licence "Built with Llama"'

block code-and-weights
on 'sources quote deepseek-v3-readme "^This code repository is licensed"'
on 'sources quote deepseek-r1-readme "^- DeepSeek-R1-Distill"'
on 'sources quote mistral-inference-licence "Apache License$|Version 2.0, January"'
on 'sources quote deepseek-v3-licence "use-based restrictions not"'

block cost
on 'sheet where llama-3.3-70b'
on 'sheet where claude-sonnet-5-5'

block retirement
on 'sheet retiring --provider anthropic'
on 'sheet retiring --provider deepseek'
on 'sheet retiring --provider openai | head -6'

block data
on 'sheet where anthropic.claude-sonnet-5-5 | grep -E "^(global|us|eu|jp)\."'
