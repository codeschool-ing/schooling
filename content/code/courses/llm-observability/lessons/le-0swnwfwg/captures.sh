#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of llm-observability, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo bash captures.sh
#
# What is STAGED rather than typed, and not shown in the lesson: the lab
# (lab.sh reset) and copying the course's programs into ~/obs from
# ../../lab/code. The programs this lesson writes are put below and shown in
# full.
#
# THE RUBRICS AND EVERY HUMAN LABEL ARE WRITTEN BY THE COURSE: ana and bruno
# are people at a shop that does not exist, and their labels of the sixty
# replies are ../../lab/labels.jsonl, written to show what two readers of a
# vague rubric do and what an anchored one changes. They are teaching data,
# not a study. The rubrics are ../../lab/rubrics.
#
# EVERY VERDICT CALLED judge-1's IS judge-1's, the lab's stand-in judge, which
# grades by embedding similarity by rules written at the top of
# ../../lab/labobs.py. It is not a language model. The replies are extract-1's,
# the lab's stand-in assistant model, answering the evaluation set of lesson 8.
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
use telemetry.py redact.py assistant.py checks.py evalrun.py judge.py

put agree.py <<'PY'
"""agree.py: how far two sets of relevance labels agree, beyond what chance alone would give.

    python agree.py relevance-v1/ana relevance-v1/bruno
    python agree.py relevance-v2/agreed judge

A set is RUBRIC/RATER from data/labels.jsonl, or `judge`, the verdicts
judge_runs.py wrote. A reply is named by its question's id and the release
that wrote it, never by its position in a file.
"""
import json
import sys
from collections import Counter

import checks


def kappa(a, b):
    """Cohen's kappa: the agreement observed, the agreement chance would give, and how far beyond it."""
    n = len(a)
    observed = sum(x == y for x, y in zip(a, b)) / n
    ca, cb = Counter(a), Counter(b)
    expected = sum(ca[k] * cb[k] for k in ca) / n / n
    return observed, expected, (observed - expected) / (1 - expected)


def load(name):
    if name == "judge":
        return {(r["case"], r["release"]): r["label"] for r in map(json.loads, open("runs/judged.jsonl"))}
    rubric, rater = name.split("/")
    return {(r["case"], r["release"]): r["label"] for r in map(json.loads, open("data/labels.jsonl"))
            if r["rubric"] == rubric and r["rater"] == rater}


replies = {(r["id"], r["release"]): r["reply"] for run in ("old", "new") for r in map(json.loads, open(f"runs/{run}.jsonl"))}
left, right = load(sys.argv[1]), load(sys.argv[2])
keys = sorted(left)
assert keys == sorted(right) == sorted(replies), "the two sets do not label the same replies"
a, b = [left[k] for k in keys], [right[k] for k in keys]
observed, expected, k = kappa(a, b)
cells = Counter(zip(a, b))
print(f"{len(keys)} replies; rows {sys.argv[1]}, columns {sys.argv[2]}")
print("          pass  fail")
for x in ("pass", "fail"):
    print(f"  {x}  {cells[x, 'pass']:6}{cells[x, 'fail']:6}")
print(f"agreement {observed:.1%}   by chance {expected:.1%}   kappa {k:.2f}")
apart = [key for key in keys if left[key] != right[key]]
refusals = [key for key in apart if checks.is_refusal(replies[key])]
print(f"apart on {len(apart)}: {len(refusals)} refusals, {len(apart) - len(refusals)} other replies")
for key in apart:
    if key not in refusals:
        print(f"  {key[0]} {key[1]}  {left[key]} / {right[key]}  {replies[key][:58]}")
PY

put judge_runs.py <<'PY'
"""judge_runs.py: judge-1's relevance verdict on every reply of the two runs, written where agree.py reads it.

    python judge_runs.py [--refusals-pass]

With --refusals-pass the agreed refusal is passed by rule, as the rubric says,
and never sent to the judge.
"""
import argparse
import json

import checks
import judge
import telemetry

p = argparse.ArgumentParser()
p.add_argument("--refusals-pass", action="store_true")
a = p.parse_args()
telemetry.setup("judge-spans.jsonl", service="judge")
asked = total = 0
with open("runs/judged.jsonl", "w") as out:
    for run in ("old", "new"):
        for r in map(json.loads, open(f"runs/{run}.jsonl")):
            if a.refusals_pass and checks.is_refusal(r["reply"]):
                label = "pass"
            else:
                label = judge.grade("relevance", r["question"], r["reply"], r["sources"])["verdict"]
                asked += 1
            out.write(json.dumps({"case": r["id"], "release": r["release"], "label": label}) + "\n")
            total += 1
print(f"runs/judged.jsonl: {total} replies, {asked} sent to judge-1, {total - asked} passed by rule")
PY

block rubric1
on 'cat data/rubrics/relevance-v1.md'

block labels
on 'head -3 data/labels.jsonl'
on 'wc -l data/labels.jsonl'

block runs
on 'python evalrun.py old --release 2026.09.4'
on 'python evalrun.py new --release 2026.10.1'

block v1
on 'python agree.py relevance-v1/ana relevance-v1/bruno'

block rubric2
on 'cat data/rubrics/relevance-v2.md'

block v2
on 'python agree.py relevance-v2/ana relevance-v2/bruno'

block judge
on 'python judge_runs.py'
on 'python agree.py relevance-v2/agreed judge'

block rule
on 'python judge_runs.py --refusals-pass'
on 'python agree.py relevance-v2/agreed judge'
