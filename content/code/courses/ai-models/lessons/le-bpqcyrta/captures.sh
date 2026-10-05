#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of ai-models, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash ../../lab.sh up        # once: the machine, the SDKs, the documents
#   bash captures.sh
#
# A line that starts with ana@desk:~/desk$ is what ana typed and what it
# printed. STAGED rather than typed: the lab itself (lab.sh reset) and the
# programs put below, which the lesson shows in full.
#
# WHAT IS REAL AND WHAT IS THE STAND-IN'S. Prices and windows are LiteLLM's
# sheet at its pinned commit. The Cohere and Mistral SDKs are the real ones, at
# the versions lab.sh pins, and `wire` prints what they actually sent. What
# answered them is standin: its reply to the e-mail is the course's table, and
# its "rerank" scores documents by the share of the query's words they contain,
# which is arithmetic, not Cohere's model; the lesson says so beside it.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@desk:~/desk$ %s\n' "$*"; lab exec ana "$*" 2>&1 || true; }
put() { lab exec ana "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"; }
block() { printf '##### %s\n' "$1"; }

lab reset >/dev/null

block cohere
on 'sheet provider cohere_chat'
on 'sheet where command-a-plus'

put lab/rerank.py <<'PY'
import os

import cohere

co = cohere.ClientV2(api_key=os.environ["CO_API_KEY"], base_url=os.environ["CO_API_URL"])
policies = [
    "Orders ship from our warehouse within two working days of payment.",
    "Refunds for damaged or misprinted books are paid to the original card within ten days.",
    "Gift vouchers are sent by e-mail on the date the buyer chooses.",
    "An address can be changed until the order leaves the warehouse.",
]
r = co.rerank(model="rerank-v4.0-pro", query="my book arrived damaged, I want my money back",
              documents=policies, top_n=2)
for hit in r.results:
    print(f"{hit.relevance_score:.4f}  {policies[hit.index]}")
PY

block rerank
on 'sheet show rerank-v4.0-pro | grep -E "^(input_cost_per_query|max_input|mode|source)"'
on 'python-cohere lab/rerank.py'
on 'wire --headers user-agent,authorization'

block mistral
on 'sheet compare mistral/ministral-3b-latest mistral/ministral-8b-latest mistral/mistral-small-latest mistral/mistral-medium-latest mistral/mistral-large-latest mistral/magistral-medium-latest mistral/devstral-latest'

put lab/mistral_sort.py <<'PY'
import os

from mistralai.client import Mistral

client = Mistral(api_key=os.environ["MISTRAL_API_KEY"], server_url=os.environ["MISTRAL_SERVER_URL"])
r = client.chat.complete(model="standin-small", messages=[
    {"role": "system", "content": open("prompts/triage.txt").read()},
    {"role": "user", "content": "Hello, where is my parcel? LB-20488"}])
print(r.choices[0].message.content, r.usage.prompt_tokens, r.usage.completion_tokens)
PY

block mistral-api
on 'python lab/mistral_sort.py'
on 'wire --headers user-agent,authorization'
