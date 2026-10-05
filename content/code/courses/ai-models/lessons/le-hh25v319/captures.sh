#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of ai-models, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash ../../lab.sh up        # once: the machine, the SDKs, the documents
#   bash captures.sh
#
# A line that starts with ana@desk:~/desk$ is what ana typed and what it
# printed. STAGED rather than typed: the lab itself (lab.sh reset) and
# lab/evalkit.py, which the lesson shows in full.
#
# WHAT IS MEASURED AND WHAT IS WRITTEN BY THE COURSE. The forty cases and the
# labels on them were written by the course (lab/cases.jsonl). So were the
# stand-in's answers to them (lab/answers.json): which cases each of its three
# models gets wrong, how it gets them wrong, and the two cases standin-small
# answers differently from one request to the next above temperature 0. Its
# prices in evalkit.py are the course's too. What is REAL is everything
# evalkit computes from those answers: the scores, the intervals, the
# comparisons, the timings and the token counts.
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
lab exec ana 'mkdir -p runs'

put lab/evalkit.py <<'PY'
"""evalkit: run a task's cases through several models, and score what came back."""
import json
import math
import re
import sys
import time

import openai

client = openai.OpenAI()
# What a million tokens costs on each stand-in, in dollars, in and out. These are
# the course's numbers; standin-local plays a model ana runs herself.
PRICES = {"standin-large": (3.00, 15.00), "standin-small": (0.25, 1.25), "standin-local": (0, 0)}


def score_triage(answer, case):
    strict = answer == case["label"]
    loose = answer.strip().lower().rstrip(".") == case["label"]
    return strict, loose


def score_extract(answer, case):
    try:
        strict = json.loads(answer).get("order") == case["order"]
    except (json.JSONDecodeError, AttributeError):
        strict = False
    found = re.search(r"\{.*\}", answer, re.S)
    try:
        loose = bool(found) and json.loads(found.group(0)).get("order") == case["order"]
    except json.JSONDecodeError:
        loose = False
    return strict, loose


def run(task, models, out, temperature=0.0):
    system = open(f"prompts/{task}.txt").read()
    cases = [json.loads(line) for line in open("cases/triage.jsonl")]
    score = score_triage if task == "triage" else score_extract
    with open(out, "w") as f:
        for model in models:
            for case in cases:
                start = time.perf_counter()
                r = client.chat.completions.create(
                    model=model, max_completion_tokens=50, temperature=temperature,
                    messages=[{"role": "system", "content": system}, {"role": "user", "content": case["text"]}])
                answer = r.choices[0].message.content
                strict, loose = score(answer, case)
                f.write(json.dumps({"task": task, "model": r.model, "case": case["id"], "answer": answer, "strict": strict,
                                    "loose": loose, "seconds": round(time.perf_counter() - start, 3),
                                    "in": r.usage.prompt_tokens, "out": r.usage.completion_tokens}) + "\n")


def wilson(k, n, z=1.96):
    """The 95% interval around k right out of n, by Wilson's formula."""
    p = k / n
    centre = (p + z * z / (2 * n)) / (1 + z * z / n)
    half = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / (1 + z * z / n)
    return centre - half, centre + half


def report(path):
    rows = [json.loads(line) for line in open(path)]
    print(f"{'model':14} {'strict':>7} {'loose':>7} {'loose, 95%':>14} {'p50 s':>6} {'$ per 1k':>9}")
    for model in dict.fromkeys(r["model"] for r in rows):
        mine = [r for r in rows if r["model"] == model]
        n, strict, loose = len(mine), sum(r["strict"] for r in mine), sum(r["loose"] for r in mine)
        lo, hi = wilson(loose, n)
        p_in, p_out = PRICES[model]
        cost = sum(r["in"] * p_in + r["out"] * p_out for r in mine) / 1e6 / n * 1000
        p50 = sorted(r["seconds"] for r in mine)[n // 2]
        print(f"{model:14} {strict:>4}/{n} {loose:>4}/{n} {lo:>7.0%} to {hi:>4.0%} {p50:>6.2f} {cost:>9.4f}")


def compare(path, a, b):
    """Cases where exactly one of the two models was right, and how likely that split is by chance."""
    rows = [json.loads(line) for line in open(path)]
    right = {(r["model"], r["case"]): r["loose"] for r in rows}
    cases = [r["case"] for r in rows if r["model"] == a]
    only_a = [c for c in cases if right[(a, c)] and not right[(b, c)]]
    only_b = [c for c in cases if right[(b, c)] and not right[(a, c)]]
    n, k = len(only_a) + len(only_b), min(len(only_a), len(only_b))
    p = min(1.0, 2 * sum(math.comb(n, i) for i in range(k + 1)) / 2 ** n) if n else 1.0
    print(f"only {a} right: {len(only_a)} {only_a}")
    print(f"only {b} right: {len(only_b)} {only_b}")
    print(f"chance of a split at least this uneven if they were equally good: {p:.3f}")


def errors(path):
    rows = [json.loads(line) for line in open(path)]
    cases = {c["id"]: c for c in map(json.loads, open("cases/triage.jsonl"))}
    for r in rows:
        if not r["strict"]:
            want = cases[r["case"]]["label" if r["task"] == "triage" else "order"]
            mark = "loose ok" if r["loose"] else "wrong"
            print(f"{r['model']:14} {r['case']} {mark:8}  expected {want!s:15} got {r['answer']!r}")


def gate(base, new, model, allowed=1):
    """Fail, with exit status 1, if model's new run is worse than its baseline by more than allowed cases."""
    def score(path):
        return sum(json.loads(line)["loose"] for line in open(path) if json.loads(line)["model"] == model)
    before, after = score(base), score(new)
    verdict = "pass" if after >= before - int(allowed) else "FAIL"
    print(f"{model}: {before} before, {after} now, {int(allowed)} allowed: {verdict}")
    sys.exit(0 if verdict == "pass" else 1)


if __name__ == "__main__":
    cmd, *args = sys.argv[1:]
    if cmd == "run":
        task, out, temperature, models = args[0], args[1], float(args[2]), args[3:]
        run(task, models, out, temperature)
    else:
        {"report": report, "compare": compare, "errors": errors, "gate": gate}[cmd](*args)
PY

block building-the-set
on "python -c \"import json, collections; print(collections.Counter(json.loads(l)['label'] for l in open('cases/triage.jsonl')))\""
on 'grep -c "\"order\": null" cases/triage.jsonl'
on 'grep -E "\"c(20|38)\"" cases/triage.jsonl'

block scoring
on "python -c \"from lab.evalkit import score_triage as s; c = {'label': 'refund'}; print(s('refund', c), s('Refund', c), s('refund.', c), s('order-status', c))\""
on "python -c \"from lab.evalkit import score_extract as s; c = {'order': 'LB-20452'}; print(s('{\\\"order\\\": \\\"LB-20452\\\"}', c), s('Here is the JSON: {\\\"order\\\": \\\"LB-20452\\\"}', c))\""

block harness
on 'time python lab/evalkit.py run triage runs/triage.jsonl 0 standin-large standin-small standin-local'
on 'wc -l runs/triage.jsonl; head -2 runs/triage.jsonl'

block results
on 'python lab/evalkit.py report runs/triage.jsonl'
on 'python lab/evalkit.py compare runs/triage.jsonl standin-large standin-small'
on 'python lab/evalkit.py compare runs/triage.jsonl standin-small standin-local'

block errors
on 'python lab/evalkit.py errors runs/triage.jsonl'

block repeatability
on 'python lab/evalkit.py run triage runs/again.jsonl 0 standin-small && diff <(cut -d, -f4,5 runs/again.jsonl) <(grep standin-small runs/triage.jsonl | cut -d, -f4,5) && echo same answers'
on 'python lab/evalkit.py run triage runs/hot-a.jsonl 1 standin-small; python lab/evalkit.py run triage runs/hot-b.jsonl 1 standin-small'
on 'python lab/evalkit.py report runs/hot-a.jsonl; python lab/evalkit.py report runs/hot-b.jsonl | tail -1'
on 'diff <(cut -d, -f3,4 runs/hot-a.jsonl) <(cut -d, -f3,4 runs/hot-b.jsonl)'

block extraction
on 'python lab/evalkit.py run extract runs/extract.jsonl 0 standin-large standin-small standin-local'
on 'python lab/evalkit.py report runs/extract.jsonl'
on 'python lab/evalkit.py errors runs/extract.jsonl'

block regression
on 'cp runs/triage.jsonl runs/baseline.jsonl'
on 'python lab/evalkit.py gate runs/baseline.jsonl runs/hot-a.jsonl standin-small; echo "exit $?"'
on 'python lab/evalkit.py gate runs/baseline.jsonl runs/hot-b.jsonl standin-small; echo "exit $?"'
