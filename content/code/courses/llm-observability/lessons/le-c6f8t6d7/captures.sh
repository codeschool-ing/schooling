#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of llm-observability, as a script
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
# ../../lab/code, and the replay of the week, which lesson 3 shows. judge.py
# is shown in the lesson; the programs it writes are put below and shown in
# full.
#
# EVERY VERDICT IN THIS LESSON IS judge-1's, the lab's stand-in judge, which
# grades by embedding similarity by rules written at the top of
# ../../lab/labobs.py. It is not a language model and its verdicts are not a
# model's; the lesson measures what grading a sample costs and how sure a
# sample can be, and those are properties of sampling, not of the judge.
# judge-1's price is the course's, from prices.json.
#
# THE UNIFORM SAMPLE IS A DIFFERENT TENTH ON EVERY RUN OF THIS SCRIPT. It is
# chosen by a hash of the trace id, so grading the same spans twice picks the
# same replies; but the replay gives every request a fresh random trace id, so
# a new replay is a new tenth, and its numbers move inside their intervals.
# Every other block is the same on every run.
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
use telemetry.py redact.py assistant.py replay.py tree.py costs.py judge.py
lab exec 'python assistant.py "warm up" >/dev/null; rm -f spans.jsonl; python replay.py >/dev/null'

put traffic.py <<'PY'
"""traffic.py: the week's replies as records to grade: question, reply, sources, release, and the thumb if any."""
import json
from collections import defaultdict

import psycopg

text = dict(psycopg.connect().execute("SELECT id, text FROM chunks").fetchall())
thumbs = {f["trace"]: f["value"] for f in map(json.loads, open("feedback.jsonl")) if f["kind"] == "thumbs"}


def replies(path="spans.jsonl"):
    by = defaultdict(dict)
    for s in map(json.loads, open(path)):
        by[s["trace"]][s["name"]] = s
    for trace, spans in sorted(by.items(), key=lambda kv: kv[1]["ask"]["start"]):
        a = spans["ask"]["attributes"]
        if a["app.feature"] == "summary":
            continue
        yield {"trace": trace, "release": a["app.release"], "feature": a["app.feature"],
               "question": a["app.question"], "reply": a["app.reply"], "outcome": a["app.outcome"],
               "sources": [{"id": c, "text": text[c]} for c in spans["search"]["attributes"]["app.search.chunks"]],
               "thumb": thumbs.get(trace)}
PY

put one.py <<'PY'
"""one.py: one reply of the week, graded on two criteria by judge-1."""
import judge
import telemetry
import traffic

telemetry.setup("judge-spans.jsonl", service="judge")
r = next(r for r in traffic.replies() if r["question"].startswith("Above what order value"))
print(r["question"], "->", r["reply"])
for criterion in ("relevance", "faithfulness"):
    print(criterion, judge.grade(criterion, r["question"], r["reply"], r["sources"]))
PY

put sample.py <<'PY'
"""sample.py: which replies of the week to grade, by three different rules."""
import hashlib
import random


def keep(trace, share):
    """Random but repeatable: the same trace is in or out on every run, decided by its id."""
    return int(hashlib.sha256(trace.encode()).hexdigest()[:8], 16) / 0xFFFFFFFF < share


def uniform(replies, share):
    return [r for r in replies if keep(r["trace"], share)]


def stratified(replies, per_group, key=lambda r: (r["release"], r["feature"])):
    """The same number from every group, so a small group is not drowned by a large one."""
    groups = {}
    for r in replies:
        groups.setdefault(key(r), []).append(r)
    rng = random.Random(7)
    return [r for g in sorted(groups) for r in rng.sample(groups[g], min(per_group, len(groups[g])))]


def targeted(replies):
    """Every reply somebody already doubted: a thumb down, or a refusal."""
    return [r for r in replies if r["thumb"] == "down" or r["outcome"] == "refused"]
PY

put grade_sample.py <<'PY'
"""grade_sample.py: judge-1 on a sample of the week, pass rates per release with how sure they are."""
import argparse
import json
import math
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor

import judge
import sample
import telemetry
import traffic

p = argparse.ArgumentParser()
p.add_argument("how", choices=["uniform", "stratified", "targeted"])
p.add_argument("--share", type=float, default=0.1)
p.add_argument("--per-group", type=int, default=30)
a = p.parse_args()


def wilson(passed, n, z=1.96):
    """The 95% interval for a pass rate measured on n replies."""
    if n == 0:
        return 0.0, 1.0
    p = passed / n
    centre = (p + z * z / (2 * n)) / (1 + z * z / n)
    half = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / (1 + z * z / n)
    return centre - half, centre + half


replies = list(traffic.replies())
chosen = {"uniform": lambda: sample.uniform(replies, a.share),
          "stratified": lambda: sample.stratified(replies, a.per_group),
          "targeted": lambda: sample.targeted(replies)}[a.how]()
telemetry.setup("judge-spans.jsonl", service="judge")
with ThreadPoolExecutor(8) as pool:   # eight at a time, as replay.py does
    verdicts = list(pool.map(lambda r: judge.grade("relevance", r["question"], r["reply"], r["sources"]), chosen))
passed, seen = defaultdict(int), defaultdict(int)
with open("verdicts.jsonl", "a") as out:
    for r, v in zip(chosen, verdicts):
        out.write(json.dumps({"trace": r["trace"], "criterion": "relevance", "sample": a.how, **v}) + "\n")
        seen[r["release"]] += 1
        passed[r["release"]] += v["verdict"] == "pass"
print(f"{a.how}: {len(chosen)} of {len(replies)} replies graded for relevance")
for rel in sorted(seen):
    lo, hi = wilson(passed[rel], seen[rel])
    print(f"  {rel}  {passed[rel]:4}/{seen[rel]:<4} pass  {passed[rel] / seen[rel]:5.1%}   95% between {lo:5.1%} and {hi:5.1%}")
PY

put judge_cost.py <<'PY'
"""judge_cost.py: what the grading cost, from the judge's own spans, beside what the assistant cost."""
import costs

judged = costs.requests("judge-spans.jsonl")
served = costs.requests("spans.jsonl")
cost = lambda rs: sum(r["cost"] for r in rs)
print(f"judge calls  {len(judged):5}   input {sum(r['input'] for r in judged):7}   output {sum(r['output'] for r in judged):6}"
      f"   US$ {cost(judged):.6f}   per call {cost(judged) / len(judged):.8f}")
print(f"assistant    {len(served):5}   input {sum(r['input'] for r in served):7}   output {sum(r['output'] for r in served):6}"
      f"   US$ {cost(served):.6f}   per request {cost(served) / len(served):.8f}")
PY

block one
on 'python one.py'

block uniform
on 'python grade_sample.py uniform --share 0.1'

block stratified
on 'python grade_sample.py stratified --per-group 30'

block targeted
on 'python grade_sample.py targeted'

block all
on 'python grade_sample.py uniform --share 1.0'

block cost
on 'python judge_cost.py'

block sizes
put sizes.py <<'PY'
"""sizes.py: how close a sample of n replies gets to a true pass rate of 70%, at 95%."""
import math

for n in (50, 100, 400, 1000, 4000):
    print(f"n = {n:5}   a pass rate of 70% is known to within {1.96 * math.sqrt(0.7 * 0.3 / n):5.1%}")
PY
on 'python sizes.py'
