#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of ai-models, as a script that
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
# WHAT IS MEASURED AND WHAT IS ASSUMED. Prices, windows and features are
# LiteLLM's sheet at its pinned commit. The latencies are measured, for real,
# against standin, whose speeds the course set in lab/standin.py (time to the
# first token and time per token for each of its three models); they show how
# to measure, not how fast any real model is. Before that run standin is told
# to stretch each first token by a random factor with a long tail, seeded by
# the request's number ({"jitter": 0.6} below), so that a median and a 95th
# percentile can differ, as they do on a shared service. The drafting
# reply it streams is written by the course (lab/replies.json). The drafting workload (400
# requests a day, a 5,000-token policy, 60 fresh tokens, 200 out) is the
# COURSE'S ASSUMPTION and the lesson says so.
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

block requirements
on 'sheet pick | sed -n 2p'
on 'sheet pick --needs response_schema --min-window 32000 | sed -n 2p'
on 'sheet pick --needs response_schema --min-window 32000 --max-in 1 | sed -n 2p'

put lab/monthly.py <<'PY'
import json

sheet = json.load(open("/opt/aimodels/share/litellm-21881c57.json"))
CANDIDATES = ["claude-haiku-4-5", "claude-sonnet-5-5", "gemini/gemini-3.5-flash-lite",
              "gpt-5.4-mini", "mistral/mistral-small-latest", "deepseek/deepseek-v3.2"]
# The drafting task, as the course assumes it: the shop's policy is the same
# 5,000 tokens on every request, the e-mail is 60 more, the reply is 200.
PER_DAY, POLICY, FRESH, OUT = 400, 5000, 60, 200
n = PER_DAY * 30


def money(x):
    return f"${x:8.2f}" if x is not None else "       -"


print(f"{'model':30} {'list':>9} {'cached':>9} {'batch':>9}   output share")
for m in CANDIDATES:
    e = sheet[m]
    i, o = e["input_cost_per_token"], e["output_cost_per_token"]
    plain = n * ((POLICY + FRESH) * i + OUT * o)
    read = e.get("cache_read_input_token_cost")
    cached = n * (POLICY * read + FRESH * i + OUT * o) if read else None
    bi, bo = e.get("input_cost_per_token_batches"), e.get("output_cost_per_token_batches")
    batch = n * ((POLICY + FRESH) * bi + OUT * bo) if bi and bo else None
    print(f"{m:30} {money(plain)} {money(cached)} {money(batch)}   {n * OUT * o / plain:6.0%}")
PY

block cost
on 'python lab/monthly.py'

put lab/latency.py <<'PY'
import statistics
import sys
import time

import anthropic

client = anthropic.Anthropic()
email = "Hello, where is my parcel? LB-20488"
print(f"{'model':14} {'first token p50':>16} {'p95':>6} {'whole reply p50':>16} {'p95':>6}")
for model in ("standin-large", "standin-small", "standin-local"):
    first, whole = [], []
    for _ in range(int(sys.argv[1])):
        start = time.perf_counter()
        with client.messages.stream(model=model, max_tokens=300,
                                    messages=[{"role": "user", "content": "Draft a reply: " + email}]) as s:
            for i, _text in enumerate(s.text_stream):
                if i == 0:
                    first.append(time.perf_counter() - start)
        whole.append(time.perf_counter() - start)
    q = lambda xs, p: statistics.quantiles(xs, n=20)[p] if len(xs) > 1 else xs[0]  # noqa: E731
    print(f"{model:14} {statistics.median(first):>15.2f}s {q(first, 18):>5.2f}s "
          f"{statistics.median(whole):>15.2f}s {q(whole, 18):>5.2f}s")
PY

block latency
curl -s -o /dev/null -X POST http://127.0.0.1:8500/lab/config -d '{"jitter": 0.6}'
on 'python lab/latency.py 20'

block context
on 'sheet pick --min-window 1000000 | sed -n 2p'
on 'sheet pick --min-window 200000 | sed -n 2p'
on 'sheet pick --min-window 32000 | sed -n 2p'
on 'sheet compare claude-haiku-4-5 gemini/gemini-3.5-flash-lite gpt-5.4-mini mistral/mistral-small-latest deepseek/deepseek-v3.2'
