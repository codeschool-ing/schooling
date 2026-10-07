#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of ai-models, as a script that
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
# NEITHER OLLAMA NOR LM STUDIO RUNS ON THIS MACHINE. Both fetch their models
# from hosts it cannot reach (ollama.com and huggingface.co), and LM Studio is
# a desktop application. What answers on their ports, 11434 and 1234, is
# standin (standin.py), speaking their APIs; its model, standin-local,
# answers from the table in answers.json, and its durations are the
# speeds standin.py gives it. What is real: the `ollama` and `openai`
# libraries and what they send, and the two projects' own documentation, read
# at the commits sources.py pins.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture-lib.sh

lab reset >/dev/null

block two-tools
quote quote ollama-api "Model names follow"
quote quote ollama-readme "Supported backends|llama.cpp\\]"
quote quote lmstudio-tools "llmster is LM Studio|listens on"


give local_chat.py native.md python 1

block native
on 'python local_chat.py'
relay_up
on 'OLLAMA_HOST=http://127.0.0.1:8500 python local_chat.py'
on 'python relay.py show --headers user-agent'
relay_down
on 'python -c "import ollama; [print(m.model, m.expires_at) for m in ollama.ps().models]"'

quote quote ollama-faq "By default models are kept in memory"
on 'python -c "import ollama; print(ollama.generate(model=\"llama3.2:3b\", keep_alive=0).done_reason); print(len(ollama.ps().models), \"models loaded\")"'
quote quote ollama-faq "Ollama runs locally"
quote quote ollama-openai "No Ollama installation required|base_url=\"https://ollama.com"

give context.py context.md python 1

block context
quote quote ollama-faq "By default, Ollama uses a context window"
on 'python context.py'

give two_servers.py openai.md python 1

block openai
on 'python two_servers.py'
quote quote ollama-openai "does not have a way of setting the context size"
