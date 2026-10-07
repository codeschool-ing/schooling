#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of ai-models, as a script that
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
# lab/sources.py at the commit or on the date it prints.
#
# compat.py goes to every provider's real address with no key of the
# course's. api.anthropic.com and generativelanguage.googleapis.com answer
# and refuse the key; api.openai.com, api.mistral.ai, openrouter.ai and
# router.huggingface.co are refused by this machine's network, whose proxy
# answers 403 in their place, and the lesson says so. Ollama answers.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture-lib.sh

lab reset >/dev/null

give compat.py one-client.md python 1
give limit.py ignored.md python 1
give chatdoc.py ignored.md python 2

block one-client
on 'python compat.py'

block ignored
quote quote claude-openai-compat "silently ignored|not considered a long-term"
quote lines claude-openai-compat 283 284
quote lines claude-openai-compat 293 294
quote quote claude-openai-compat "Values greater than 1|Prompt caching is not supported"
on 'python limit.py'
on 'python chatdoc.py max_tokens'
quote quote ollama-openai "does not have a way of setting the context size"
