#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of llm-observability, as a script
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
# ../../lab/code, and the two runs of the evaluation set, which lesson 10
# shows. The programs this lesson writes are put below and shown in full.
#
# The agreed labels are lesson 10's, WRITTEN BY THE COURSE
# (../../lab/labels.jsonl). Every score called judge-1's is judge-1's, the
# lab's stand-in judge, which grades by embedding similarity by rules written
# at the top of ../../lab/labobs.py; it is not a language model. The replies
# are extract-1's, the lab's stand-in assistant model.
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
use telemetry.py redact.py assistant.py checks.py evalrun.py judge.py facts.py
lab exec 'python evalrun.py old --release 2026.09.4 >/dev/null && python evalrun.py new --release 2026.10.1 >/dev/null'

put sweep.py <<'PY'
"""sweep.py: judge-1's relevance score used to flag irrelevant replies, at six thresholds,
against the agreed labels of lesson 10. A flag is a score below the threshold."""
import json

import checks
import judge
import telemetry

telemetry.setup("judge-spans.jsonl", service="judge")
agreed = {(r["case"], r["release"]): r["label"] for r in map(json.loads, open("data/labels.jsonl"))
          if r["rubric"] == "relevance-v2" and r["rater"] == "agreed"}
scored = []
for run in ("old", "new"):
    for r in map(json.loads, open(f"runs/{run}.jsonl")):
        if checks.is_refusal(r["reply"]):
            continue   # passed by rule, as in lesson 10
        score = judge.grade("relevance", r["question"], r["reply"], r["sources"])["score"]
        scored.append((score, agreed[r["id"], r["release"]] == "fail"))
bad = sum(b for _, b in scored)
print(f"{len(scored)} replies read by the judge, {bad} of them irrelevant by the agreed labels")
print("threshold  flagged  caught  precision  recall")
for t in (0.40, 0.55, 0.60, 0.65, 0.70, 0.75):
    flagged = [b for s, b in scored if s < t]
    caught = sum(flagged)
    precision = f"{caught / len(flagged):9.0%}" if flagged else "        -"
    print(f"     {t:.2f}  {len(flagged):7}  {caught:6}  {precision}  {caught / bad:6.0%}")
PY

put metrics.py <<'PY'
"""metrics.py: five numbers for each run of the evaluation set, each defined in its function.

    python metrics.py old new
"""
import json
import sys

import psycopg

import checks
import judge
import telemetry
from facts import normalised

cases = {c["id"]: c for c in map(json.loads, open("data/eval.jsonl"))}
section = {cid: (doc, path.split(" > ")[-1])
           for cid, doc, path in psycopg.connect().execute("SELECT id, doc_id, path FROM chunks")}


def context_precision(chunks, gold):
    """How high the chunks that belong to a gold section sit among those the model was given:
    the precision at each such chunk's rank, averaged. None when nothing was given."""
    if not chunks:
        return None
    hits = [section[c] in gold for c in chunks]
    at = [sum(hits[:i + 1]) / (i + 1) for i, h in enumerate(hits) if h]
    return sum(at) / len(at) if at else 0.0


def context_recall(chunks, gold):
    """The share of the gold sections that at least one given chunk comes from. None when there is no gold."""
    if not gold:
        return None
    found = {section[c] for c in chunks}
    return sum(g in found for g in gold) / len(gold)


def faithfulness(r):
    """judge-1's share of the reply's sentences supported by its sources; a refusal claims nothing."""
    return judge.grade("faithfulness", r["question"], r["reply"], r["sources"])["score"]


def relevance(r):
    """judge-1's relevance verdict, with the refusal passed by rule as lesson 10 decided."""
    if checks.is_refusal(r["reply"]):
        return 1.0
    return float(judge.grade("relevance", r["question"], r["reply"], r["sources"])["verdict"] == "pass")


def correctness(r, case):
    """Lesson 8's normalised fact check: the fact is in the reply, or an unanswerable question was refused."""
    return float(normalised(r["reply"], case["facts"]))


telemetry.setup("judge-spans.jsonl", service="judge")
mean = lambda xs: sum(x for x in xs if x is not None) / len([x for x in xs if x is not None])
count = lambda xs: len([x for x in xs if x is not None])
print("run  release  " + "".join(f"{h:>16}" for h in ("ctx precision", "ctx recall", "faithfulness", "relevance", "correctness")))
for name in sys.argv[1:]:
    run = [json.loads(line) for line in open(f"runs/{name}.jsonl")]
    cols = {"p": [], "r": [], "f": [], "v": [], "c": []}
    for r in run:
        case = cases[r["id"]]
        gold = {tuple(g) for g in case["gold"]}
        chunks = [s["id"] for s in r["sources"]]
        cols["p"].append(context_precision(chunks, gold))
        cols["r"].append(context_recall(chunks, gold))
        cols["f"].append(faithfulness(r))
        cols["v"].append(relevance(r))
        cols["c"].append(correctness(r, case))
    print(f"{name:4} {run[0]['release']}" + "".join(f"{mean(v):>9.2f} (n={count(v):2})" for v in cols.values()))
PY

block sweep
on 'python sweep.py'

block metrics
on 'python metrics.py old new'
