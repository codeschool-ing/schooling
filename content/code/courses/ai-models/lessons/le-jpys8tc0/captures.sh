#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of ai-models, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo sudo bash ../../lab.sh up        # once: the machine, the SDKs, the documents
#   bash captures.sh
#
# A line that starts with ana@desk:~/desk$ is what ana typed and what it
# printed. A quotation carries no prompt: the licences are the projects' own
# files at the commits lab/sources.py pins, and the student reads them.
#
# Nothing here talks to a model. The prices, windows and deprecation dates are
# LiteLLM's sheet at the commit sheet.py pins, a third party's copy of the
# providers' pages; sheet.py is the student's, shown whole in the cost section
# and taken from it here, and its first run downloads the sheet.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture-lib.sh

lab reset >/dev/null

block three-kinds
quote quote deepseek-r1-readme "^This code repository and the model weights"
quote quote llama3.1-licence "Grant of Rights"

block licences
quote quote llama3.1-licence "700 million"
quote quote qwen-licence "100 million|improve any other large"
quote quote llama3.1-licence "Built with Llama"

block code-and-weights
quote quote deepseek-v3-readme "^This code repository is licensed"
quote quote deepseek-r1-readme "^- DeepSeek-R1-Distill"
quote quote mistral-inference-licence "Apache License$|Version 2.0, January"
quote quote deepseek-v3-licence "use-based restrictions not"

block cost
give sheet.py cost.md python 1
lab exec ana 'rm -f litellm-*.json'
on 'python sheet.py where llama-3.3-70b'
on 'python sheet.py where claude-sonnet-5-5'

block retirement
on 'python sheet.py retiring --provider anthropic'
on 'python sheet.py retiring --provider deepseek'
on 'python sheet.py retiring --provider openai | head -6'

block data
on 'python sheet.py where anthropic.claude-sonnet-5-5 | grep -E "^(global|us|eu|jp)\."'
