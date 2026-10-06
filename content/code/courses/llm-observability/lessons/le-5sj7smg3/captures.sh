#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of llm-observability, as a script
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
# ../../lab/code, building version 2 of the evaluation set (lesson 13), and
# the candidate releases of lesson 14 in releases.json. The tests and the
# gate file this lesson writes are put below and shown in full; the second
# gate.json is the first with one decision added, and the lesson shows both.
#
# The GitHub Actions workflow in the lesson is NOT RUN HERE: this machine is
# not a GitHub runner. It is shown as a file, with its actions pinned to the
# commits their tags named on 2026-10-06 (actions/checkout as this
# repository's own ci.yml pins it, actions/setup-python from git ls-remote);
# the commands it runs are the ones run below.
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
use telemetry.py redact.py assistant.py checks.py evalrun.py facts.py costs.py docs.py buildset.py
lab exec 'python buildset.py >/dev/null'
put releases.json <<'JSON'
{
  "2026.09.4": {"from": "2026-09-01T00:00:00", "model": "extract-1", "k": 3, "floor": 0.5},
  "2026.10.1": {"from": "2026-10-02T10:00:00", "model": "extract-1", "k": 3, "floor": 0.62},
  "2026.10.2": {"from": "2099-01-01T00:00:00", "model": "extract-2", "k": 3, "floor": 0.62},
  "2026.10.3": {"from": "2099-01-01T00:00:00", "model": "extract-1", "k": 3, "floor": 0.5},
  "2026.10.4": {"from": "2099-01-01T00:00:00", "model": "extract-2", "k": 3, "floor": 0.5}
}
JSON

put gate.json <<'JSON'
{
  "set": "data/eval-v2.jsonl",
  "manifest": "data/eval-v2.manifest.json",
  "budgets": {"cost": 0.25, "median_ms": 0.25},
  "accepted": {}
}
JSON

put tests/conftest.py <<'PY'
"""The gate's shared pieces: the gate file, the set, and the two runs every regression test compares.

PRODUCTION is the release live now unless the variable names another; CANDIDATE must be named.
"""
import json
import os
import subprocess
from datetime import datetime

import pytest

import assistant

GATE = json.load(open("gate.json"))


@pytest.fixture(scope="session")
def cases():
    return {c["id"]: c for c in map(json.loads, open(GATE["set"]))}


@pytest.fixture(scope="session")
def releases():
    candidate = os.environ.get("CANDIDATE")
    if not candidate:
        raise pytest.UsageError("CANDIDATE is not set: name the release this change would ship")
    production = os.environ.get("PRODUCTION") or assistant.release_at(datetime.now().isoformat())[0]
    return production, candidate


@pytest.fixture(scope="session")
def runs(releases):
    """Both releases answer the set now, so a drift in the model or the prices shows in both."""
    out = {}
    for role, release in zip(("production", "candidate"), releases):
        subprocess.run(["python", "evalrun.py", role, "--set", GATE["set"], "--release", release],
                       check=True, capture_output=True)
        out[role] = {r["id"]: r for r in map(json.loads, open(f"runs/{role}.jsonl"))}
    return out
PY

put tests/test_set.py <<'PY'
"""The evaluation set itself: lesson 13's checks, as tests. No model is called."""
import hashlib
import json
import logging
import re

from presidio_analyzer import AnalyzerEngine

import docs
import redact
from conftest import GATE

logging.disable(logging.WARNING)   # tldextract warns that it could not fetch a list; it uses its own copy
MANIFEST = json.load(open(GATE["manifest"]))
SHOP = docs.load()


def test_the_set_is_the_version_the_manifest_pins():
    digest = hashlib.sha256(open(GATE["set"], "rb").read()).hexdigest()
    assert digest == MANIFEST["sha256"], (
        f"{GATE['set']} is not the version its manifest pins: build it with buildset.py and commit both")


def test_no_id_is_used_twice(cases):
    ids = [line["id"] for line in map(json.loads, open(GATE["set"]))]
    assert len(ids) == len(set(ids)) == len(cases)


def test_every_fact_is_in_its_gold_section(cases):
    squash = lambda t: re.sub(r"\s+", " ", re.sub(r"[^\w\s.]", " ", t.lower())).strip()
    false = [i for i, c in cases.items() if c["facts"]
             and not any(squash(f) in squash(" ".join(SHOP[d][1].get(h, "") for d, h in c["gold"])) for f in c["facts"])]
    assert not false, f"no longer true of the documents: {false}. Retire them and write new cases"


def test_every_document_is_at_the_pinned_version():
    moved = [d for d, v in MANIFEST["documents"].items() if SHOP[d][0]["version"] != v]
    assert not moved, f"changed since the set was checked: {moved}. Re-check the cases that rest on them"


def test_no_question_holds_personal_data(cases):
    analyzer = AnalyzerEngine()
    found = {}
    for i, c in cases.items():
        hits = {c["question"][r.start:r.end] for r in analyzer.analyze(c["question"], language="en",
                                                                         entities=["PERSON", "EMAIL_ADDRESS", "PHONE_NUMBER"])}
        hits |= {m.group() for _, p in redact.PATTERNS for m in p.finditer(c["question"])}
        if hits - set(c.get("synthetic", [])):
            found[i] = sorted(hits - set(c.get("synthetic", [])))
    assert not found, f"personal data in the set: {found}. Replace it, or declare an invented value synthetic"
PY

put tests/test_regression.py <<'PY'
"""The candidate against production on the set: lesson 14's rules, as tests."""
import statistics

import pytest

import checks
import costs
from conftest import GATE
from facts import normalised


def right(r, cases):
    return normalised(r["reply"], cases[r["id"]]["facts"])


def failing(r):
    return {n for n, ok, _ in checks.run(r["reply"], r["sources"]) if not ok}


def test_no_case_that_production_answers_is_broken(runs, cases, releases):
    accepted = GATE["accepted"].get(releases[1], {}).get("broken", {})
    broken = [i for i in cases if right(runs["production"][i], cases) and not right(runs["candidate"][i], cases)]
    unread = [i for i in broken if i not in accepted]
    assert not unread, (f"{releases[1]} breaks {unread} against {releases[0]}: read each one, then fix the "
                        "candidate or accept the case in gate.json with the reason")


def test_no_check_newly_fails(runs, cases):
    new = {i: sorted(failing(runs["candidate"][i]) - failing(runs["production"][i])) for i in cases}
    new = {i: n for i, n in new.items() if n}
    assert not new, f"checks the candidate newly fails: {new}"


@pytest.mark.parametrize("measure", ["cost", "median_ms"])
def test_within_budget(runs, releases, measure):
    spent = {r["trace"]: r for r in costs.requests("eval-spans.jsonl")}
    total = {"cost": lambda run: sum(spent[r["trace"]]["cost"] for r in run.values()),
             "median_ms": lambda run: statistics.median(spent[r["trace"]]["ms"] for r in run.values())}[measure]
    before, after = float(total(runs["production"])), float(total(runs["candidate"]))
    accepted = GATE["accepted"].get(releases[1], {}).get(measure)
    ceiling = accepted["up_to"] if accepted else GATE["budgets"][measure]
    change = (after - before) / before
    assert change <= ceiling, (f"{measure} {before:.6g} -> {after:.6g}, {change:+.0%}, over the {ceiling:+.0%} "
                               "budget: make it cheaper, or accept it in gate.json with the reason")
PY

block tree
on 'find tests -name "*.py" | sort; cat gate.json'

block history
on 'PRODUCTION=2026.09.4 CANDIDATE=2026.10.1 python -m pytest -q --tb=line -p no:cacheprovider tests'

block fix
on 'CANDIDATE=2026.10.3 python -m pytest -q --tb=line -p no:cacheprovider tests'

put gate.json <<'JSON'
{
  "set": "data/eval-v2.jsonl",
  "manifest": "data/eval-v2.manifest.json",
  "budgets": {"cost": 0.25, "median_ms": 0.25},
  "accepted": {
    "2026.10.3": {
      "cost": {"up_to": 1.0, "why": "answers the five questions 2026.10.1 refused; costs what 2026.09.4 did"},
      "median_ms": {"up_to": 7.0, "why": "the same: 2026.10.1 was fast because it refused"}
    }
  }
}
JSON

block accepted
on 'cat gate.json'
on 'CANDIDATE=2026.10.3 python -m pytest -q --tb=line -p no:cacheprovider tests'

block both
on 'CANDIDATE=2026.10.4 python -m pytest -q --tb=line -p no:cacheprovider tests'

block missing
on 'python -m pytest -q --tb=line -p no:cacheprovider tests'
