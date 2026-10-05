#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of ai-models, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash ../../lab.sh up        # once: the machine, the SDKs, the documents
#   bash captures.sh
#
# A line that starts with ana@desk:~/desk$ is what ana typed and what it
# printed. STAGED rather than typed: the lab itself (lab.sh reset), the files
# put below, which the lesson shows in full, and two settings made through
# standin's /lab/config, where in the world they would be made in a
# provider's console: a limit of 5 requests a minute (`limit 5`) and a
# credit limit of $0.0005 on the OpenRouter key (`keycap 0.0005`).
#
# Every provider here is standin (lab/standin.py): its answers come from
# lab/answers.json, its rate limit is a sliding minute, its OpenRouter key
# spends at the prices in its ROUTES table, and its error messages are its
# own. What is real: the anthropic, openai and httpx libraries and what they
# send and receive, the programs' arithmetic and timings, the model sheet, and
# Anthropic's and OpenRouter's documentation, read on the date or at the
# commit lab/sources.py prints.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@desk:~/desk$ %s\n' "$*"; lab exec ana "$*" 2>&1 || true; }
put() { lab exec ana "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"; }
block() { printf '##### %s\n' "$1"; }
config() { curl -s -o /dev/null -d "$1" http://127.0.0.1:8500/lab/config; }
limit() { config "{\"rpm\": $1, \"clear\": true}"; }
keycap() { config "{\"or_key_limit\": $1}"; }

lab reset >/dev/null

# Two files of ana's from a week of work: a note made while debugging, and the
# start of a support widget for the shop's website.
put notes.txt <<'TXT'
2026-09-30 OpenRouter test - works with the key below, move it to the env file later
  sk-or-lab-key-0001
TXT
put page/widget.js <<'JS'
// Sort the customer's message in the browser before it is sent to us.
const OPENROUTER_KEY = "sk-or-lab-key-0001";
export async function sortMessage(text) {
  const r = await fetch("https://openrouter.ai/api/v1/chat/completions", {
    method: "POST",
    headers: { Authorization: `Bearer ${OPENROUTER_KEY}`, "Content-Type": "application/json" },
    body: JSON.stringify({ model: "standin/small", messages: [{ role: "user", content: text }] }),
  });
  return (await r.json()).choices[0].message.content;
}
JS

put lab/keyscan.py <<'PY'
import pathlib
import re

# the shapes of the keys this course has used: OpenRouter's sk-or-, Hugging Face's hf_, the lab's own
SHAPES = re.compile(r"\b(sk-or-[\w-]{6,}|sk-[\w-]{16,}|hf_\w{8,}|lab-[a-z]+-key-\d+)")
for path in sorted(pathlib.Path(".").rglob("*")):
    if not path.is_file() or "node_modules" in path.parts:
        continue
    for n, line in enumerate(path.read_text(errors="ignore").splitlines(), 1):
        for key in SHAPES.findall(line):
            print(f"{path}:{n}: {key[:6]}{'*' * (len(key) - 6)}")
PY

block keys
on 'grep -oE "^[A-Z_]+(KEY|TOKEN)=" /etc/aimodels.env'
on 'python lab/keyscan.py'

put lab/burst.py <<'PY'
import calendar
import json
import sys
import time

import anthropic

client = anthropic.Anthropic(max_retries=0)
prompt = open("prompts/triage.txt").read()
cases = [json.loads(line) for line in open("cases/triage.jsonl")][:8]
pace = sys.argv[1:] == ["--pace"]

start = time.monotonic()
for c in cases:
    raw = None
    try:
        raw = client.messages.with_raw_response.create(
            model="standin-small", max_tokens=16, system=prompt,
            messages=[{"role": "user", "content": c["text"]}])
        h = raw.headers
        print(f"{time.monotonic() - start:5.1f}s {c['id']} {raw.parse().content[0].text:16} "
              f"remaining {h['anthropic-ratelimit-requests-remaining']}, full at {h['anthropic-ratelimit-requests-reset']}")
    except anthropic.RateLimitError as e:
        print(f"{time.monotonic() - start:5.1f}s {c['id']} 429, retry-after {e.response.headers['retry-after']}")
    if pace and raw is not None and raw.headers["anthropic-ratelimit-requests-remaining"] == "0":
        # out of requests: wait until the limit says it is full again
        reset = time.strptime(raw.headers["anthropic-ratelimit-requests-reset"], "%Y-%m-%dT%H:%M:%SZ")
        wait = max(0.0, calendar.timegm(reset) - time.time())
        print(f"       waiting {wait:.0f}s")
        time.sleep(wait)
PY

block rate-limits
on 'sources quote claude-rate-limits "measured in requests per minute|token bucket algorithm|continuously replenished|Short bursts"'
on 'sources lines claude-rate-limits 686 687'
limit 5
on 'python lab/burst.py'
limit 5
on 'python lab/burst.py --pace'
limit 50

block caps
on 'sources quote claude-rate-limits "carries a monthly spend cap|cannot exceed your current tier|You have reached your specified API usage limits"'
on 'sources quote openrouter-limits "Per-key credit limits"'

put lab/or_spend.py <<'PY'
import json
import os

import httpx
from openai import OpenAI, APIStatusError

base, key = os.environ["OPENROUTER_BASE_URL"], os.environ["OPENROUTER_API_KEY"]
client = OpenAI(base_url=base, api_key=key)
prompt = open("prompts/triage.txt").read()
cases = [json.loads(line) for line in open("cases/triage.jsonl")]

for n, c in enumerate(cases, 1):
    try:
        r = client.chat.completions.create(model="standin/large", messages=[
            {"role": "system", "content": prompt}, {"role": "user", "content": c["text"]}])
    except APIStatusError as e:
        print(f"request {n}: {e.status_code} {e.body['message']} ({e.body['metadata']['limit_source']})")
        break
info = httpx.get(f"{base}/key", headers={"Authorization": f"Bearer {key}"}).json()["data"]
print({k: info[k] for k in ("limit", "usage", "limit_remaining")})
PY

keycap 0.0005
on 'python lab/or_spend.py'
keycap null

put lab/budget.py <<'PY'
import json

from openai import OpenAI

# gpt-5.4-mini's prices from lesson 8's sheet, dollars per million tokens
PRICE_IN, PRICE_OUT = 0.75, 4.50
LABELS = {"order-status", "refund", "address-change", "product-question", "other"}


class Budget:
    """Adds up what each response says it used; refuses the next call once the money is gone."""

    def __init__(self, dollars):
        self.left, self.calls = dollars, 0

    def charge(self, usage):
        self.calls += 1
        self.left -= (usage.prompt_tokens * PRICE_IN + usage.completion_tokens * PRICE_OUT) / 1e6
        if self.left < 0:
            raise RuntimeError(f"budget spent after {self.calls} calls")


client = OpenAI()
budget = Budget(dollars=0.002)
prompt = open("prompts/triage.txt").read()
cases = [json.loads(line) for line in open("cases/triage.jsonl")]

try:
    for c in cases:
        label = None
        while label not in LABELS:   # the bug: ask again until the answer is a label
            r = client.chat.completions.create(model="standin-small", temperature=0, messages=[
                {"role": "system", "content": prompt}, {"role": "user", "content": c["text"]}])
            budget.charge(r.usage)
            label = r.choices[0].message.content
        print(c["id"], label)
except RuntimeError as e:
    print(f"stopped at {c['id']}, whose last answer was {label!r}: {e}")
PY

block budget
on 'python lab/budget.py'
on 'wire --count 200 | grep -c "^POST /v1/chat/completions -> 200"'
