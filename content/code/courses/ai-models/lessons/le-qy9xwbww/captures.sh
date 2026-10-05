#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of ai-models, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash ../../lab.sh up        # once: the machine, the SDKs, the documents
#   bash captures.sh
#
# A line that starts with ana@desk:~/desk$ is what ana typed and what it
# printed. STAGED rather than typed: the lab itself (lab.sh reset), the
# programs put below, which the lesson shows in full, and the outage: `outage`
# below tells standin that one of its upstream providers is down, through
# its /lab/config, where in the world a provider would simply fail.
#
# openrouter.ai could not be reached from the machine this was recorded on.
# What answers at OPENROUTER_BASE_URL is standin (lab/standin.py): two models,
# standin/large served by standin-east and standin-west and standin/small by
# standin-east alone, at the prices in its ROUTES table, and standin-east
# marked as a provider that keeps what it is sent. What is real: the openai
# library and what it sends, the model sheet, and OpenRouter's own
# documentation at the commit lab/sources.py pins.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@desk:~/desk$ %s\n' "$*"; lab exec ana "$*" 2>&1 || true; }
put() { lab exec ana "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"; }
block() { printf '##### %s\n' "$1"; }
outage() { curl -s -o /dev/null -d "{\"down\": $1}" http://127.0.0.1:8500/lab/config; }

lab reset >/dev/null

block one-key
on 'sheet count | head -4'
on 'sheet compare claude-sonnet-4-5 openrouter/anthropic/claude-sonnet-4.5 gemini-2.5-flash openrouter/google/gemini-2.5-flash'
on 'sources quote openrouter-faq "there is no markup|fee when you purchase credits"'
on 'sources quote openrouter-fees "getTotalFeeString = |stripe"'

put lab/or_sort.py <<'PY'
import json
import os
import sys

from openai import OpenAI, APIStatusError

client = OpenAI(base_url=os.environ["OPENROUTER_BASE_URL"], api_key=os.environ["OPENROUTER_API_KEY"])
prompt = open("prompts/triage.txt").read()
case = [json.loads(line) for line in open("cases/triage.jsonl")][4]

# the request's extra fields, as JSON on the command line: {"provider": {...}} or {"models": [...]}
extra = json.loads(sys.argv[1]) if len(sys.argv) > 1 else {}
try:
    r = client.chat.completions.create(
        model="standin/large", extra_body=extra,
        messages=[{"role": "system", "content": prompt}, {"role": "user", "content": case["text"]}])
except APIStatusError as e:
    sys.exit(f"{e.status_code}: {e.body['message']}")
print(f"{r.choices[0].message.content:6} model={r.model} provider={r.provider} cost=${r.usage.cost:.6f}")
PY

block routing
on 'sources quote openrouter-routing "inverse square of the price|9x more likely"'
on 'python -c "p = [1, 2, 3]; w = [1 / x**2 for x in p]; print([round(x / sum(w) * 100, 1) for x in w])"'
on 'python lab/or_sort.py'
on 'python lab/or_sort.py '"'"'{"provider": {"order": ["standin-west"]}}'"'"
outage '["standin-east"]'
on 'python lab/or_sort.py'
on 'python lab/or_sort.py '"'"'{"provider": {"order": ["standin-east"], "allow_fallbacks": false}}'"'"
outage '[]'

block fallbacks
on 'sources quote openrouter-fallbacks "lets you automatically try other models"'
outage '["standin-east"]'
on 'python lab/or_sort.py '"'"'{"models": ["standin/small", "standin/large"]}'"'"
on 'wire --count 1'
outage '[]'

block data
on 'sources quote openrouter-routing "^- .allow.: |^- .deny.: |not a definitive source"'
on 'python lab/or_sort.py '"'"'{"provider": {"data_collection": "deny"}}'"'"
on 'python lab/or_sort.py '"'"'{"models": ["standin/small"], "provider": {"data_collection": "deny"}}'"'"

put lab/or_cost.py <<'PY'
import json
import os

import httpx
from openai import OpenAI

base, key = os.environ["OPENROUTER_BASE_URL"], os.environ["OPENROUTER_API_KEY"]
models = httpx.get(f"{base}/models", headers={"Authorization": f"Bearer {key}"}).json()["data"]
price = {m["id"]: m["pricing"] for m in models}["standin/large"]
print("standin/large, dollars per token:", price["prompt"], "in,", price["completion"], "out")

client = OpenAI(base_url=base, api_key=key)
prompt = open("prompts/triage.txt").read()
case = [json.loads(line) for line in open("cases/triage.jsonl")][4]
u = client.chat.completions.create(model="standin/large", messages=[
    {"role": "system", "content": prompt}, {"role": "user", "content": case["text"]}]).usage
listed = u.prompt_tokens * float(price["prompt"]) + u.completion_tokens * float(price["completion"])
print(f"{u.prompt_tokens} in, {u.completion_tokens} out, at the listed prices: ${listed:.6f}")
print(f"usage.cost in the response:          ${u.cost:.6f}")
PY

block cost
on 'sources quote openrouter-usage "upstream_inference_cost.: The|.cost.: The total"'
on 'python lab/or_cost.py'
