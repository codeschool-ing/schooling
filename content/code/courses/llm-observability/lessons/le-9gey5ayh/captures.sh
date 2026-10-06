#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of llm-observability, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# (lab.sh reset), and copying the course's programs into ~/obs from
# ../../lab/code. The programs this lesson writes are put below and shown in
# full.
#
# EVERY TIMING IN THIS LESSON IS labobs', and labobs WAITS BY RULES THE COURSE
# WROTE, at the top of ../../lab/labobs.py: 180 ms plus 0.12 ms per input token
# before the first token, 25 ms per token after it, a log-normal factor per
# request, and a 4 s cold start with probability 0.01. The FAILURES are asked
# for through labobs' /lab/config, which no real provider has. What is measured
# is real: the clocks, the spans, the SDK's behaviour, the retries. Timings
# differ by a few milliseconds from run to run.
#
# Recorded on Ubuntu 24.04, Python 3.11, TZ=America/Sao_Paulo, on 2026-10-06.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
cd "$(dirname "$0")"
LAB_SH=${LAB_SH:-../../lab.sh}
CODE=$(cd "$(dirname "$LAB_SH")" && pwd)/lab/code
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@lab:~/obs$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
put() { lab exec "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"; }
use() { for f in "$@"; do put "$f" < "$CODE/$f"; done; }
block() { printf '##### %s\n' "$1"; }
config() { curl -s -X POST http://127.0.0.1:8600/lab/config -d "$1" >/dev/null; }
exec 9>/var/tmp/llmobs-capture.lock; flock 9
lab reset >/dev/null
use telemetry.py redact.py assistant.py replay.py tree.py costs.py
lab exec 'python assistant.py "warm up" >/dev/null; rm -f spans.jsonl'

put stream.py <<'PY'
"""stream.py: one streamed reply, with the moment each piece arrived."""
import time

from openai import OpenAI

client = OpenAI()
start = time.monotonic()
stream = client.chat.completions.create(model="extract-1", stream=True, messages=[
    {"role": "user", "content": "[1] gift-cards.md\nGift cards are valid for two years from purchase "
     "and cannot be exchanged for cash.\n\nQuestion: How long is a gift card valid?"}])
last = None
for chunk in stream:
    for c in chunk.choices:
        if c.delta.content:
            now = (time.monotonic() - start) * 1000
            gap = f"+{now - last:.0f}" if last is not None else "first"
            print(f"{now:7.0f} ms  {gap:>6}  {c.delta.content!r}")
            last = now
PY

put latency.py <<'PY'
"""latency.py: the week's successful model calls and requests, as percentiles."""
import json

spans = [json.loads(line) for line in open("spans.jsonl")]
chats = [s for s in spans if s["name"].startswith("chat ") and s["status"] != "ERROR"]
asks = [s for s in spans if s["name"] == "ask"]
ms = lambda s: (s["end"] - s["start"]) / 1e6
ttft = lambda s: s["attributes"]["app.time_to_first_token_ms"]
per_token = lambda s: (ms(s) - ttft(s)) / max(s["attributes"]["gen_ai.usage.output_tokens"] - 1, 1)
rows = {"whole request": [ms(s) for s in asks], "model call": [ms(s) for s in chats],
        "first token": [ttft(s) for s in chats], "each token after": [per_token(s) for s in chats]}
print(f"{'':17} {'n':>5} {'mean':>6} {'p50':>6} {'p90':>6} {'p95':>6} {'p99':>6} {'max':>6}   ms")
for name, xs in rows.items():
    xs.sort()
    q = lambda p: xs[min(len(xs) - 1, int(p * len(xs)))]
    print(f"{name:17} {len(xs):5} {sum(xs) / len(xs):6.0f} {q(.5):6.0f} {q(.9):6.0f} {q(.95):6.0f} {q(.99):6.0f} {xs[-1]:6.0f}")
PY

put drivers.py <<'PY'
"""drivers.py: what the length of a model call goes with, in the week's spans."""
import json
from statistics import median

chats = [s for s in map(json.loads, open("spans.jsonl"))
         if s["name"].startswith("chat ") and s["status"] != "ERROR"]
a = lambda s, k: s["attributes"][k]


def table(title, key, value, edges):
    print(title)
    for lo, hi in zip(edges, edges[1:]):
        xs = [value(s) for s in chats if lo <= key(s) < hi]
        if xs:
            print(f"  {lo:4} to {hi - 1:4}  {len(xs):5} calls  median {median(xs):6.0f} ms")


table("whole call, by output tokens", lambda s: a(s, "gen_ai.usage.output_tokens"),
      lambda s: (s["end"] - s["start"]) / 1e6, [0, 20, 40, 60, 80, 100, 200])
table("first token, by input tokens", lambda s: a(s, "gen_ai.usage.input_tokens"),
      lambda s: a(s, "app.time_to_first_token_ms"), [0, 100, 200, 300, 400, 600])
cold = [s for s in chats if a(s, "app.time_to_first_token_ms") > 3000]
print(f"first token over 3 s: {len(cold)} of {len(chats)} calls")
PY

put ten.py <<'PY'
"""ten.py: ten questions through the assistant, one line each."""
import json

import assistant
import telemetry

telemetry.setup()
for q in [x["phrasings"][0] for x in json.load(open("data/topics.json"))[:10]]:
    try:
        reply, _, trace = assistant.ask(q)
        print(f"{trace[:8]}  ok      {reply[:60]}")
    except Exception as e:
        print(f"{'':8}  FAILED  {type(e).__name__}: {e}")
PY

put errors.py <<'PY'
"""errors.py: the model attempts in spans.jsonl, and what became of the requests that made them."""
import json
from collections import Counter

spans = [json.loads(line) for line in open("spans.jsonl")]
chats = [s for s in spans if s["name"].startswith("chat ")]
asks = [s for s in spans if s["name"] == "ask"]
gens = [s for s in spans if s["name"] == "generate"]
print(f"attempts {len(chats)}, failed {sum(s['status'] == 'ERROR' for s in chats)}")
print("requests by attempts needed:", dict(sorted(Counter(s["attributes"]["app.attempts"] for s in gens).items())))
print(f"requests {len(asks)}, failed {sum(s['status'] == 'ERROR' for s in asks)}")
PY

put sdk_retry.py <<'PY'
"""sdk_retry.py: the SDK retrying inside one span, where the trace cannot see it."""
from openai import OpenAI

import telemetry

telemetry.setup()
client = OpenAI(max_retries=2)
with telemetry.span("chat extract-1", **{"gen_ai.request.model": "extract-1"}):
    client.chat.completions.create(model="extract-1", messages=[{"role": "user", "content": "How long is a gift card valid?"}])
PY

put timeout.py <<'PY'
"""timeout.py: one call with a two-second timeout, to a provider that is about to take four."""
import time

from openai import APITimeoutError, OpenAI

client = OpenAI(timeout=2.0, max_retries=0)
start = time.monotonic()
try:
    client.chat.completions.create(model="extract-1", messages=[{"role": "user", "content": "How long is a gift card valid?"}])
    print(f"answered after {time.monotonic() - start:.1f} s")
except APITimeoutError as e:
    print(f"{type(e).__name__} after {time.monotonic() - start:.1f} s: {e}")
PY

block three-clocks
on 'python stream.py'

block week
on 'python replay.py'
on 'python latency.py'

block drivers
on 'python drivers.py'

block failures
config '{"fail_rate": 0.3}'
on 'curl -s -X POST http://127.0.0.1:8600/lab/config -d "{\"fail_rate\": 0.3}"; echo'
on 'rm -f spans.jsonl; python ten.py'
on 'python errors.py'
T=$(lab exec 'python -c "import json; g = [json.loads(l) for l in open(\"spans.jsonl\")]; print(next(s[\"trace\"][:8] for s in g if s[\"name\"] == \"generate\" and s[\"attributes\"][\"app.attempts\"] > 1))"')
on "python tree.py $T"
on "python tree.py --attrs $T | grep -E \"ERROR|attempts\""
config '{"reset": true}'

block sdk-retry
config '{"fail": 2, "status": 503}'
on 'rm -f spans.jsonl; python sdk_retry.py; python tree.py'
on 'tail -3 /var/log/labgen/requests.jsonl | python -c "import json, sys; [print(json.loads(l)[\"n\"], json.loads(l)[\"status\"]) for l in sys.stdin]"'
config '{"reset": true}'

block cut
config '{"cut_after": 6}'
on 'rm -f spans.jsonl; python assistant.py "How long is a gift card valid?"'
on 'python tree.py --attrs | grep -E " ms |ERROR|partial|attempts"'
config '{"reset": true}'

block timeout
config '{"slow_rate": 1.0}'
on 'python timeout.py'
config '{"reset": true}'
