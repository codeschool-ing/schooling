#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of ai-models, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash ../../lab.sh up        # once: Ollama, the models, ~/desk
#   sudo bash captures.sh
#
# A line that starts with ana@desk:~/desk$ is what ana typed and what it
# printed. size.py, volume.py and breakeven.py are the student's, shown whole in
# the lesson and taken from it here; a quotation carries no prompt.
#
# WHAT IS MEASURED AND WHAT IS ASSUMED. The architecture numbers are Meta's,
# from models/sku_list.py at the pinned commit, which size.py reads from
# GitHub, and the parameter counts are computed from them. Token counts are
# llama3.2:3b's, through Ollama 0.40.0 and Anthropic's library, on 2026-10-07.
# Prices are LiteLLM's sheet at its pinned commit. Three numbers are the
# COURSE'S ASSUMPTIONS and the lesson says so where it uses them: 1,000 GB/s of
# memory bandwidth, 400 e-mails a day, and $1,500 a month for a machine.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture-lib.sh

lab reset >/dev/null

give size.py memory.md example size.py

block memory
quote lines llama-skus 235 246
on 'python size.py'

block throughput
on 'python size.py 1000 | cut -c1-17,76-'
on 'python size.py 3000 | cut -c1-17,76-'

give volume.py break-even.md python 1
give breakeven.py break-even.md python 2

block break-even
on 'python volume.py'
on 'python breakeven.py claude-haiku-4-5 1500'
on 'python breakeven.py claude-opus-5-5 1500'
