#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of ai-models, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash ../../lab.sh up        # once: Ollama, the models, ~/desk
#   sudo bash captures.sh
#
# A line that starts with ana@desk:~/desk$ is what ana typed and what it
# printed. monthly.py and latency.py are the student's, shown whole in the
# lesson and taken from it here.
#
# WHAT IS MEASURED AND WHAT IS ASSUMED. Prices, windows and features are
# LiteLLM's sheet at its pinned commit. The latencies are measured, for real,
# on llama3.2:3b and llama3.2:1b through Ollama 0.40.0 and Anthropic's library,
# on 2026-10-07, on a machine with four processors and no GPU; the 1b is
# unloaded first, so its first request pays for loading it, as a first request
# does. The drafting replies are the models' own and differ on every run. The
# drafting workload (400 requests a day, a 5,000-token policy, 60 fresh tokens,
# 200 out) is the COURSE'S ASSUMPTION and the lesson says so.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture-lib.sh

lab reset >/dev/null

block requirements
on 'python sheet.py pick | sed -n 2p'
on 'python sheet.py pick --needs response_schema --min-window 32000 | sed -n 2p'
on 'python sheet.py pick --needs response_schema --min-window 32000 --max-in 1 | sed -n 2p'

give monthly.py cost.md python 1
block cost
on 'python monthly.py'

give latency.py latency.md python 1
block latency
lab exec ana 'ollama stop llama3.2:1b' >/dev/null 2>&1 < /dev/null
on 'python latency.py 20'

block context
on 'python sheet.py pick --min-window 1000000 | sed -n 2p'
on 'python sheet.py pick --min-window 200000 | sed -n 2p'
on 'python sheet.py pick --min-window 32000 | sed -n 2p'
on 'python sheet.py compare claude-haiku-4-5 gemini/gemini-3.5-flash-lite gpt-5.4-mini mistral/mistral-small-latest deepseek/deepseek-v3.2'
