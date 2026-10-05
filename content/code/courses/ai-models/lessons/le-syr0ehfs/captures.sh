#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of ai-models, as a script that
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
# Nothing here talks to a model. The READMEs and licences are the projects'
# own files at the commits sources.py pins; prices, windows and dates are
# LiteLLM's sheet at its pinned commit.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@desk:~/desk$ %s\n' "$*"; lab exec ana "$*" 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }

lab reset >/dev/null

block deepseek
on 'sheet compare deepseek/deepseek-v3.2 deepseek/deepseek-v4-flash deepseek/deepseek-v4-pro deepseek/deepseek-r1'
on 'sheet retiring --provider deepseek'
on 'sheet where deepseek-v4-flash | tail -n +3 | wc -l'
on 'sheet where deepseek-v4-flash | grep -E "^(deepseek/|azure|tencent|scaleway|novita/deepseek/deepseek-v4-flash )"'

block qwen
on 'sources quote qwen3-readme "open-weight models are licensed|license files"'
on 'sheet where qwen3-235b-a22b'
on 'sheet where qwen3-max | head -4'

block gemma
on 'sources lines gemma-readme 7 10'
on 'sheet where google/gemma-4 | grep deepinfra'
