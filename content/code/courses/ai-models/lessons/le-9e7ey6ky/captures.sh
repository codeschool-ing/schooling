#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of ai-models, as a script that
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
# api.anthropic.com is reachable from the machine this was recorded on, but a
# key is a bill a course cannot hand out, so what answers at
# ANTHROPIC_BASE_URL is Ollama, which speaks Anthropic's /v1/messages, with
# llama3.2:3b behind it. Every request goes through the student's relay.py
# (lesson 9), whose --fail makes the 529s that the retries are about. What is
# Anthropic's own: the anthropic library at the version the lesson pins and
# what it sends and retries, the model sheet, and Anthropic's documentation,
# read on the date sources.py prints.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture-lib.sh

lab reset >/dev/null

give claude_sort.py shape.md python 1

relay_up
block shape
on "$RELAY_EXPORT"
via 'python claude_sort.py prompts/triage.txt c05 16'
via 'python relay.py show --headers anthropic-version,x-api-key,user-agent'
quote quote claude-versioning "anthropic-version: 2023"
via 'python claude_sort.py prompts/extract.txt c01 64'
via 'python claude_sort.py prompts/extract.txt c01 8'

give retries.py errors.md python 1

block errors
quote quote claude-errors "overloaded_error|529 errors can occur|automatically retries"
relay_down
printf 'ana@desk:~/desk$ python relay.py --fail 529:2\n'
relay_up --fail 529:2
lab exec ana 'cat relay.out' < /dev/null
via 'python retries.py 2'
via 'python relay.py show --count 3'
relay_down
printf 'ana@desk:~/desk$ python relay.py --fail 529:1\n'
relay_up --fail 529:1
lab exec ana 'cat relay.out' < /dev/null
via 'python retries.py 0'
relay_down
relay_up

give cache.py caching.md python 1

block caching
quote quote claude-caching "Shorter prompts cannot be cached|processed without caching|To verify whether"
tty 'ollama stop llama3.2:3b'
via 'python cache.py'
on 'python sheet.py show claude-sonnet-4-5 | grep -E "^(input_cost_per_token|cache_creation_input_token_cost|cache_read_input_token_cost|prompt_cache_min_tokens) "'
on 'python -c "print(f\"uncached {1167 * 3e-6 * 1000:.2f}  cached {(1166 * 3e-7 + 1 * 3e-6) * 1000:.2f}  dollars per 1,000 e-mails, input only\")"'
relay_down
