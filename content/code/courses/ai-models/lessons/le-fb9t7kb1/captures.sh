#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of ai-models, as a script that
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
# generativelanguage.googleapis.com could not be reached from the machine
# this was recorded on. What answers at GOOGLE_GEMINI_BASE_URL, which
# the library reads as its address, is standin
# (lab/standin.py), whose replies come from lab/answers.json and which
# ignores a response schema: it answers from its table either way. What is
# real: the google-genai library at the version lab.sh pins, what it sends,
# what it does with the reply on this side, and the documentation inside it.
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

put lab/gemini_sort.py <<'PY'
import json

from google import genai
from google.genai import types

client = genai.Client()
prompt = open("prompts/triage.txt").read()
case = [json.loads(line) for line in open("cases/triage.jsonl")][4]

r = client.models.generate_content(
    model="standin-small", contents=case["text"],
    config=types.GenerateContentConfig(system_instruction=prompt, max_output_tokens=16, temperature=0))
print(repr(r.text), r.candidates[0].finish_reason)
print(r.usage_metadata.prompt_token_count, "in,", r.usage_metadata.candidates_token_count, "out")
PY

block shape
on 'python lab/gemini_sort.py'
on 'wire --headers x-goog-api-key,user-agent'

put lab/gemini_extract.py <<'PY'
import json

from google import genai
from google.genai import types
from pydantic import BaseModel


class Order(BaseModel):
    order: str | None


client = genai.Client()
prompt = open("prompts/extract.txt").read()
cases = {c["id"]: c for c in map(json.loads, open("cases/triage.jsonl"))}

for cid in ("c01", "c05"):
    text = cases[cid]["text"]
    n = client.models.count_tokens(model="standin-small", contents=text).total_tokens
    r = client.models.generate_content(
        model="standin-small", contents=text,
        config=types.GenerateContentConfig(system_instruction=prompt, temperature=0,
                                           response_mime_type="application/json", response_schema=Order))
    print(cid, f"{n} tokens counted first;", repr(r.parsed), " expected:", cases[cid]["order"])
PY

block structured
on 'python lab/gemini_extract.py'
on 'wire --body | python -c "import json, sys; print(json.dumps(json.load(sys.stdin)[\"generationConfig\"], indent=2))"'

block text-none
on 'python -c "import inspect; from google.genai import types; print(inspect.getsource(types.GenerateContentResponse._get_text))" | head -24'
on 'python -c "from google.genai import types; print(types.FinishReason.__members__.keys())"'
