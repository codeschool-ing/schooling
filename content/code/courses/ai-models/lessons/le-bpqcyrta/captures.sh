#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of ai-models, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo sudo bash ../../lab.sh up        # once: Ollama, the models, ~/desk
#   sudo bash captures.sh
#
# A line that starts with ana@desk:~/desk$ is what ana typed and what it
# printed. relay.py, rerank.py and mistral_sort.py are the student's, shown
# whole in the lesson and taken from it here; the relay runs in the
# background, as it runs in a second terminal for the student.
#
# No Cohere or Mistral key: neither provider's API can be reached from this
# machine, and a key is a bill. Cohere's SDK is pointed at the relay, and Ollama
# answers its rerank request with a 404, which is what the lesson shows; the
# request is the SDK's own. Mistral's SDK reaches llama3.2:3b through the relay,
# because Ollama answers OpenAI's shape, on 2026-10-07. Prices and windows are
# LiteLLM's sheet at its pinned commit.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture-lib.sh

lab reset >/dev/null

block cohere
on 'python sheet.py provider cohere_chat'
on 'python sheet.py where command-a-plus'

block rerank
on 'python sheet.py show rerank-v4.0-pro | grep -E "^(input_cost_per_query|max_input|mode|source)"'
on 'pip install -q cohere==7.2.0; pip list | grep -iE "^(cohere|huggingface)"'
on 'python3 -m venv .venv-cohere && .venv-cohere/bin/pip install -q cohere==7.2.0'
on 'rm -rf .venv && python3 -m venv .venv && .venv/bin/pip install -q openai==3.24.0 anthropic==1.11.0 ollama==0.6.3 google-genai==2.28.0 mistralai==3.0.0 huggingface_hub==2.1.1 && .venv/bin/pip list | grep -iE "^(cohere|huggingface)"'
give relay.py rerank.md python 1
give rerank.py rerank.md python 2
printf 'ana@desk:~/desk$ python relay.py\n'
relay_up
lab exec ana 'cat relay.out' < /dev/null
on '.venv-cohere/bin/python rerank.py 2>&1 | tail -1'
on 'python relay.py show --headers user-agent,authorization'
on ".venv-cohere/bin/python -c \"import cohere; print(list(cohere.V2RerankResponseResultsItem.model_fields))\""
relay_down

block mistral
on 'python sheet.py compare mistral/ministral-3b-latest mistral/ministral-8b-latest mistral/mistral-small-latest mistral/mistral-medium-latest mistral/mistral-large-latest mistral/magistral-medium-latest mistral/devstral-latest'

give mistral_sort.py mistral-api.md python 1
block mistral-api
relay_up
on 'python mistral_sort.py'
on 'python relay.py show --headers user-agent,authorization'
relay_down
