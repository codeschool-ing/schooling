#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of ai-models, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash ../../lab.sh up        # once: Ollama, the models, ~/desk
#   sudo bash captures.sh
#
# A line that starts with ana@desk:~/desk$ is what ana typed and what it
# printed. A file or program it uses is the student's, shown whole in the
# lesson and taken from it here; a quotation carries no prompt, and is read
# by lab/sources.py at the commit or on the date it prints.
#
# The answers are llama3.2:3b's, through Ollama. The rate limit is the
# student's relay.py (lesson 9) started with --rpm, because Ollama has none;
# Anthropic's limits and spend caps and OpenRouter's key limits are quoted
# from their documentation, since no key of the course's reaches them
# (openrouter.ai is also refused by this machine's network).
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture-lib.sh

lab reset >/dev/null

give notes.txt keys.md after 'while debugging, `notes.txt`:'
give page/widget.js keys.md javascript 1
give keyscan.py keys.md python 1
give burst.py rate-limits.md python 1
give budget.py budget.md example budget.py

block keys
on 'grep -E "_KEY|_TOKEN" desk.env'
on 'python keyscan.py'

block rate-limits
quote quote claude-rate-limits "measured in requests per minute|token bucket algorithm|continuously replenished|Short bursts"
quote quote claude-rate-limits "Earlier retries will fail"
printf 'ana@desk:~/desk$ python relay.py --rpm 5\n'
relay_up --rpm 5
lab exec ana 'cat relay.out' < /dev/null
on "$RELAY_EXPORT"
via 'python burst.py'
relay_down
relay_up --rpm 5
via 'python burst.py --pace'
relay_down
quote quote claude-rate-limits "^anthropic-ratelimit-requests-remaining|^The number of requests remaining"

block caps
quote quote claude-rate-limits "carries a monthly spend cap|cannot exceed your current tier|You have reached your specified API usage limits"
quote quote openrouter-limits "Per-key credit limits"
quote quote openrouter-limits "openrouter_key_limit. means"
quote quote openrouter-limits "charges a request when it finishes"

block budget
relay_up
via 'python budget.py'
via 'python relay.py show --count 200 | grep -c "^POST /v1/chat/completions -> 200"'
relay_down
