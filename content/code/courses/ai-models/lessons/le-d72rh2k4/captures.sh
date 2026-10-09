#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of ai-models, as a script that
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
# Nothing here talks to a model. The model cards, the licence and the list of
# releases are Meta's own files at the commit sources.py pins; host prices are
# LiteLLM's sheet at its pinned commit. The 1,000 GB/s in moe.py is the same
# assumption about hardware lesson 3 made, and the lesson says so.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture-lib.sh

lab reset >/dev/null

block generations
# two lines typed in one terminal: the address, then the command that uses it
twice() { printf 'ana@desk:~/desk$ %s\nana@desk:~/desk$ %s\n' "$1" "$2"; lab exec ana "$1; $2" 2>&1 < /dev/null; }
twice 'LLAMA=https://raw.githubusercontent.com/meta-llama/llama-models/0e0b8c519242d5833d8c11bffc1232b77ad7f301' "curl -s \$LLAMA/models/sku_list.py | grep 'description=\"Llama' | grep -o 'Llama [0-9.]* [^\"]*' | sort -u"

block moe
twice 'LLAMA=https://raw.githubusercontent.com/meta-llama/llama-models/0e0b8c519242d5833d8c11bffc1232b77ad7f301' 'curl -s $LLAMA/models/llama4/MODEL_CARD.md | sed -n 23,42p | grep -E "Llama 4|Activated|Total|>[0-9]+M<"'

give moe.py moe.md python 1
on 'python moe.py'

block card
quote quote llama4-card "^\*\*Overview|Data Freshness|^\*\*Supported languages"

block hosts
on 'python sheet.py where llama-4-maverick'
