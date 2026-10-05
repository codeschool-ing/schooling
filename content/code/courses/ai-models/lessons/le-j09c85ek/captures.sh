#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of ai-models, as a script that
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
# api.openai.com could not be reached from the machine this was recorded on.
# What answers at OPENAI_BASE_URL is standin (lab/standin.py), speaking the
# Responses API: its replies come from lab/answers.json and lab/replies.json,
# it keeps stored responses in memory until it is restarted, and its error
# messages are its own. What is real: the openai library at the version
# lab.sh pins, what it sends, and the parameter documentation that ships
# inside it, which is what the lesson quotes.
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

# The parameter documentation the openai library carries, one parameter at a
# time, from the docstring of Responses.create.
put lab/doc.py <<'PY'
import re
import sys

import openai.resources.responses.responses as module

# the docstring of Responses.create, as the installed library carries it
source = open(module.__file__).read()
for name in sys.argv[1:]:
    m = re.search(rf"^ {{10}}{name}: .*?(?=\n\n {{10}}\w+: )", source, re.S | re.M)
    print(re.sub(r"(?m)^ {10}", "", m.group(0)) if m else f"{name}: not documented")
PY

put lab/resp_sort.py <<'PY'
import json

from openai import OpenAI

client = OpenAI()
prompt = open("prompts/triage.txt").read()
case = [json.loads(line) for line in open("cases/triage.jsonl")][4]

r = client.responses.create(model="standin-small", instructions=prompt, input=case["text"])
print(r.output_text)
print([item.type for item in r.output], [part.type for part in r.output[0].content])
print(r.usage.input_tokens, "in,", r.usage.output_tokens, "out, of which reasoning:",
      r.usage.output_tokens_details.reasoning_tokens)
PY

block shape
on 'python lab/resp_sort.py'
on 'wire --body'

put lab/chain.py <<'PY'
import json

from openai import OpenAI

client = OpenAI()
prompt = open("prompts/triage.txt").read()
cases = {c["id"]: c for c in map(json.loads, open("cases/triage.jsonl"))}

first = client.responses.create(model="standin-small", instructions=prompt, input=cases["c05"]["text"])
print("first: ", first.id, first.output_text, first.usage.input_tokens, "tokens in")

# the next turn sends only what is new, and the id of what came before
second = client.responses.create(model="standin-small", previous_response_id=first.id,
                                 input=cases["c12"]["text"])
print("second:", second.id, second.usage.input_tokens, "tokens in, instructions:", second.instructions)

third = client.responses.create(model="standin-small", previous_response_id=first.id,
                                instructions=prompt, input=cases["c12"]["text"])
print("third: ", third.id, third.output_text, third.usage.input_tokens, "tokens in")
PY

block state
on 'python lab/doc.py previous_response_id instructions'
on 'python lab/chain.py'
on 'wire --body | head -9'

put lab/forget.py <<'PY'
import json

from openai import OpenAI, NotFoundError, BadRequestError

client = OpenAI()
prompt = open("prompts/triage.txt").read()
case = [json.loads(line) for line in open("cases/triage.jsonl")][4]

kept = client.responses.create(model="standin-small", instructions=prompt, input=case["text"])
print("stored:   ", client.responses.retrieve(kept.id).output_text)
client.responses.delete(kept.id)
try:
    client.responses.retrieve(kept.id)
except NotFoundError as e:
    print("deleted:  ", e.status_code, e.body["message"])

once = client.responses.create(model="standin-small", instructions=prompt, input=case["text"], store=False)
try:
    client.responses.create(model="standin-small", previous_response_id=once.id, input="Thanks.")
except BadRequestError as e:
    print("store=False:", e.status_code, e.body["message"])
PY

block store
on 'python lab/doc.py store'
on 'python lab/forget.py'

put lab/long.py <<'PY'
import json
import sys

from openai import OpenAI, BadRequestError

client = OpenAI()
prompt = open("prompts/triage.txt").read()
cases = [json.loads(line) for line in open("cases/triage.jsonl")]

# thirty rounds of every case as a worked example: far more than standin-small's window
items = []
for _ in range(30):
    for c in cases[:39]:
        items += [{"role": "user", "content": c["text"]}, {"role": "assistant", "content": c["label"]}]
items.append({"role": "user", "content": cases[39]["text"]})

extra = {"truncation": sys.argv[1]} if len(sys.argv) > 1 else {}
try:
    r = client.responses.create(model="standin-small", instructions=prompt, input=items, **extra)
    print(f"{len(items)} items sent, {r.usage.input_tokens} tokens read -> {r.output_text}")
except BadRequestError as e:
    print(f"{len(items)} items sent -> {e.status_code}: {e.body['message']}")
PY

block truncation
on 'python lab/doc.py truncation'
on 'python lab/long.py'
on 'python lab/long.py auto'

put lab/parse.py <<'PY'
import json

from openai import OpenAI
from pydantic import BaseModel


class Order(BaseModel):
    order: str | None


client = OpenAI()
prompt = open("prompts/extract.txt").read()
cases = {c["id"]: c for c in map(json.loads, open("cases/triage.jsonl"))}

for cid in ("c01", "c05"):
    r = client.responses.parse(model="standin-small", instructions=prompt, input=cases[cid]["text"],
                               text_format=Order)
    print(cid, repr(r.output_parsed), " expected:", cases[cid]["order"])
PY

block structured
on 'python lab/doc.py text'
on 'python lab/parse.py'
on 'wire --body | python -c "import json, sys; print(json.dumps(json.load(sys.stdin)[\"text\"], indent=2))"'
