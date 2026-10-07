#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of ai-models, as a script that
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
# Nothing here talks to a model. The READMEs and licences are the projects'
# own files at the commits sources.py pins; prices, windows and dates are
# LiteLLM's sheet at its pinned commit.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture-lib.sh

lab reset >/dev/null

block deepseek
on 'python sheet.py compare deepseek/deepseek-v3.2 deepseek/deepseek-v4-flash deepseek/deepseek-v4-pro deepseek/deepseek-r1'
on 'python sheet.py retiring --provider deepseek'
on 'python sheet.py where deepseek-v4-flash | tail -n +3 | wc -l'
on 'python sheet.py where deepseek-v4-flash | grep -E "^(deepseek/|azure|tencent|scaleway|novita/deepseek/deepseek-v4-flash )"'

block qwen
quote quote qwen3-readme "open-weight models are licensed|license files"
on 'python sheet.py where qwen3-235b-a22b'
on 'python sheet.py where qwen3-max | head -4'

block gemma
quote lines gemma-readme 7 10
on 'python sheet.py where google/gemma-4 | grep deepinfra'
