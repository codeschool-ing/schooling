#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of ai-models, as a script that
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
# huggingface.co could not be reached from the machine this was recorded on.
# What answers at HF_BASE_URL is standin (lab/standin.py), playing Hugging
# Face's router: two models, standin/large offered by standin-east (40 tokens
# a second, $15 per million out) and standin-west (80 a second, $18), and the
# three selection policies Hugging Face documents, applied to those numbers.
# Its replies come from lab/answers.json. What is real: huggingface_hub's
# InferenceClient at the version lab.sh pins and what it sends, and Hugging
# Face's documentation at the commit lab/sources.py pins.
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

put lab/hf_route.py <<'PY'
import json
import os

from huggingface_hub import InferenceClient

client = InferenceClient(base_url=os.environ["HF_BASE_URL"])   # the token comes from HF_TOKEN
prompt = open("prompts/triage.txt").read()
case = [json.loads(line) for line in open("cases/triage.jsonl")][4]

for model in ("standin/large", "standin/large:cheapest", "standin/large:standin-east"):
    r = client.chat_completion(model=model, max_tokens=16, temperature=0, messages=[
        {"role": "system", "content": prompt}, {"role": "user", "content": case["text"]}])
    print(f"{model:28} -> {r.model:14} {r.choices[0].message.content}")
PY

block router
on 'sources lines hf-providers 135 139'
on 'python lab/hf_route.py'
on 'wire --count 3'
on 'wire --headers authorization,user-agent | head -4'

block billing
on 'sources lines hf-pricing 3 3'
on 'sources lines hf-pricing 9 12'
on 'sources lines hf-pricing 24 27'
