#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of llm-observability, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# (lab.sh reset), copying the course's programs into ~/obs from
# ../../lab/code, and the replay of the week, which lesson 3 shows.
# evalrun.py and checks.py are shown in the lesson; the programs it writes are
# put below and shown in full.
#
# Every reply comes from extract-1, the lab's stand-in model, which copies
# sentences from its sources by rules (rag's lab/labgen.py). data/eval.jsonl is
# rag's test set, written by that course. The three replies in normalise.py
# are WRITTEN BY THE COURSE to show what a comparison does with a paraphrase;
# no model wrote them, and the lesson says so.
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
exec 9>/var/tmp/llmobs-capture.lock; flock 9
lab reset >/dev/null
use telemetry.py redact.py assistant.py replay.py tree.py costs.py evalrun.py checks.py
lab exec 'python assistant.py "warm up" >/dev/null; rm -f spans.jsonl; python replay.py >/dev/null'

put facts.py <<'PY'
"""facts.py: a run graded against the facts of the evaluation set, two ways."""
import json
import re
import sys

REFUSAL = "I could not find that in our documents."
cases = {c["id"]: c for c in map(json.loads, open("data/eval.jsonl"))}


def exact(reply, facts):
    return reply == REFUSAL if not facts else any(f in reply for f in facts)


def normalised(reply, facts):
    squash = lambda t: re.sub(r"\s+", " ", re.sub(r"[^\w\s.]", " ", t.lower())).strip()
    return reply == REFUSAL if not facts else any(squash(f) in squash(reply) for f in facts)


if __name__ == "__main__":
    run = [json.loads(line) for line in open(f"runs/{sys.argv[1]}.jsonl")]
    for name, grade in (("exact", exact), ("normalised", normalised)):
        right = [r["id"] for r in run if grade(r["reply"], cases[r["id"]]["facts"])]
        print(f"{name:10} {len(right)}/{len(run)} right")
    wrong = [r for r in run if not normalised(r["reply"], cases[r["id"]]["facts"])]
    for r in wrong:
        print(f"  {r['id']}  {r['question'][:52]:52}  {r['reply'][:60]}")
PY

put normalise.py <<'PY'
"""normalise.py: three replies the course wrote, against one fact, compared two ways."""
from facts import exact, normalised

fact = ["30 days from delivery"]
for reply in ["You have 30 days from delivery to return a printed book. [1]",
              "You have 30 days  from Delivery to return it. [1]",
              "You have thirty days after delivery to return it. [1]"]:
    print(f"exact {exact(reply, fact)!s:5}  normalised {normalised(reply, fact)!s:5}  {reply}")
PY

put check_run.py <<'PY'
"""check_run.py: every check in checks.py on every reply of a run, counted, and the failures listed."""
import json
import sys
from collections import Counter

import checks

run = [json.loads(line) for line in open(f"runs/{sys.argv[1]}.jsonl")]
failed, examples = Counter(), {}
for r in run:
    for name, ok, why in checks.run(r["reply"], r["sources"]):
        if not ok:
            failed[name] += 1
            examples.setdefault(name, f"{r['id']}: {why}")
for c in checks.CHECKS:
    print(f"{c.__name__:22} {len(run) - failed[c.__name__]:3}/{len(run)} pass   {examples.get(c.__name__, '')}")
PY

put check_week.py <<'PY'
"""check_week.py: the checks on every reply of the replayed week, from the spans, per release."""
import json
from collections import Counter, defaultdict

import psycopg

import checks

text = dict(psycopg.connect().execute("SELECT id, text FROM chunks").fetchall())
by_trace = defaultdict(dict)
for s in map(json.loads, open("spans.jsonl")):
    by_trace[s["trace"]][s["name"]] = s["attributes"]
seen, failed = Counter(), defaultdict(Counter)
for spans in by_trace.values():
    root = spans["ask"]
    if root["app.feature"] == "summary":
        continue
    sources = [{"id": c, "text": text[c]} for c in spans["search"]["app.search.chunks"]]
    release = root["app.release"]
    seen[release] += 1
    for name, ok, _ in checks.run(root["app.reply"], sources):
        failed[release][name] += not ok
print(f"{'check':22}" + "".join(f"{r:>12}" for r in sorted(seen)))
for c in checks.CHECKS:
    print(f"{c.__name__:22}" + "".join(f"{failed[r][c.__name__]:6} fail" for r in sorted(seen)))
print(f"{'replies':22}" + "".join(f"{seen[r]:12}" for r in sorted(seen)))
PY

put broken.py <<'PY'
"""broken.py: five replies the course wrote, each breaking one rule, through every check."""
import checks

source = [{"id": "shipping-and-delivery:ca3796df6832",
           "text": "standard three to five working days 4.90, free on orders over 40 express next working day 9.90"}]
for reply in ["Standard delivery is free on orders over 40.",
              "Standard delivery is free on orders over 40. [2]",
              "Express delivery costs 12.90. [1]",
              "Joana, we sent the details to joana.prado@example.com. [1]",
              "Sorry, I could not find anything about that."]:
    failed = [f"{name}: {why}" for name, ok, why in checks.run(reply, source) if not ok]
    print(f"{reply}\n    {'; '.join(failed) or 'passes every check'}")
PY

block run
on 'python evalrun.py current'
on 'head -c 600 runs/current.jsonl; echo'

block facts
on 'python facts.py current'

block normalise
on 'python normalise.py'

block checks
on 'python check_run.py current'

block broken
on 'python broken.py'

block week
on 'python check_week.py'
