#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of llm-observability, as a script
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
# ../../lab/code, and the replay of the week, which lesson 3 shows. The
# programs this lesson writes are put below and shown in full.
#
# THE TWELVE NEW CASES ARE WRITTEN BY THE COURSE (../../lab/eval-additions.jsonl),
# from the questions harvest.py lists: their wording is the customers', with
# every name, address, number and order replaced by values invented for the
# test and declared as such, and their facts and gold sections were written
# from the documents, as a person maintaining the set would. What the
# customers typed was itself written by the course (../../lab/traffic.py).
#
# check_set.py turns Presidio's warnings off, as lesson 2's presidio_try.py
# does: tldextract cannot fetch its list here and falls back to its own copy.
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
use telemetry.py redact.py assistant.py replay.py checks.py
lab exec 'python assistant.py "warm up" >/dev/null; rm -f spans.jsonl; python replay.py >/dev/null'

put harvest.py <<'PY'
"""harvest.py: candidate cases for the evaluation set: every question of the week somebody doubted,
redacted, grouped and counted. Doubted means a thumb down, or a refusal."""
import json
from collections import Counter

import checks
import redact

thumbs = {f["trace"]: f["value"] for f in map(json.loads, open("feedback.jsonl")) if f["kind"] == "thumbs"}
asked, doubted = Counter(), Counter()
for s in map(json.loads, open("spans.jsonl")):
    a = s["attributes"]
    if s["name"] != "ask" or a["app.feature"] == "summary":
        continue
    text = redact.redact(a["app.question"])
    asked[text] += 1
    doubted[text] += thumbs.get(s["trace"]) == "down" or checks.is_refusal(a["app.reply"])
print(f"{len(asked)} different questions after redaction; doubted, of asked:")
for text, n in doubted.most_common(16):
    print(f"{n:4} of {asked[text]:3}  {text}")
PY

put docs.py <<'PY'
"""docs.py: the shop's documents as the evaluation set sees them: front matter, and the text under each heading."""
import glob
import os
import re


def load(folder="data/docs"):
    """{doc id: (front matter, {heading: text})} for every document in the folder."""
    docs = {}
    for path in sorted(glob.glob(os.path.join(folder, "*.md"))):
        _, front, body = open(path).read().split("---\n", 2)
        meta = dict(line.split(": ", 1) for line in front.strip().splitlines())
        sections, current = {}, None
        for line in body.splitlines():
            m = re.match(r"#{2,}\s+(.*)", line)
            if m:
                current = m.group(1).strip()
                sections[current] = ""
            elif current:
                sections[current] += line + "\n"
        docs[meta["id"]] = (meta, sections)
    return docs
PY

put buildset.py <<'PY'
"""buildset.py: version 2 of the evaluation set, version 1 and the additions, and a manifest that pins it."""
import hashlib
import json

import docs

v1 = open("data/eval.jsonl", "rb").read()
cases = [json.loads(line) for line in v1.decode().splitlines()]
cases += [json.loads(line) for line in open("data/eval-additions.jsonl")]
ids = [c["id"] for c in cases]
assert len(ids) == len(set(ids)), "an id is used twice"
for c in cases:   # every third question is held out, decided by its id and nothing else, as in rag
    c["split"] = "held-out" if int(c["id"][1:]) % 3 == 0 else "dev"
body = "".join(json.dumps(c, ensure_ascii=False) + "\n" for c in cases).encode()
open("data/eval-v2.jsonl", "wb").write(body)
shop = docs.load()
manifest = {"set": "marginalia-help", "version": 2, "cases": len(cases),
            "sha256": hashlib.sha256(body).hexdigest(), "parent": hashlib.sha256(v1).hexdigest(),
            "splits": {s: sum(c["split"] == s for c in cases) for s in ("dev", "held-out")},
            "documents": {d: shop[d][0]["version"] for d in sorted({g[0] for c in cases for g in c["gold"]})}}
json.dump(manifest, open("data/eval-v2.manifest.json", "w"), indent=1)
print(json.dumps(manifest, indent=1))
PY

put check_set.py <<'PY'
"""check_set.py: whether an evaluation set is still true of the documents, and holds nobody's data.

    python check_set.py SET [--docs FOLDER]
"""
import argparse
import hashlib
import json
import logging
import re

from presidio_analyzer import AnalyzerEngine

import docs
import redact

logging.disable(logging.WARNING)   # tldextract warns that it could not fetch a list; it uses its own copy
p = argparse.ArgumentParser()
p.add_argument("set")
p.add_argument("--docs", default="data/docs")
a = p.parse_args()
body = open(a.set, "rb").read()
cases = [json.loads(line) for line in body.decode().splitlines()]
manifest = json.load(open("data/eval-v2.manifest.json"))
shop = docs.load(a.docs)
squash = lambda t: re.sub(r"\s+", " ", re.sub(r"[^\w\s.]", " ", t.lower())).strip()
analyzer = AnalyzerEngine()
problems = {"ids": [], "gold sections": [], "facts": [], "personal data": [], "documents": []}
ids = [c["id"] for c in cases]
problems["ids"] = sorted({i for i in ids if ids.count(i) > 1})
for c in cases:
    missing = [g for g in c["gold"] if g[0] not in shop or g[1] not in shop[g[0]][1]]
    if missing:
        problems["gold sections"].append(f"{c['id']} {missing}")
    elif c["facts"]:
        text = " ".join(shop[d][1][h] for d, h in c["gold"])
        if not any(squash(f) in squash(text) for f in c["facts"]):
            problems["facts"].append(f"{c['id']} {c['facts']}")
    allowed = set(c.get("synthetic", []))
    found = [c["question"][r.start:r.end] for r in analyzer.analyze(c["question"], language="en",
                                                                     entities=["PERSON", "EMAIL_ADDRESS", "PHONE_NUMBER"])]
    found += [m.group() for _, pattern in redact.PATTERNS for m in pattern.finditer(c["question"])]
    if set(found) - allowed:
        problems["personal data"].append(f"{c['id']} {sorted(set(found) - allowed)}")
for d, version in manifest["documents"].items():
    if shop[d][0]["version"] != version:
        problems["documents"].append(f"{d} is version {shop[d][0]['version']}, the set was checked against {version}")
pinned = hashlib.sha256(body).hexdigest() == manifest["sha256"]
print(f"{a.set}: {len(cases)} cases, {'the version the manifest pins' if pinned else 'NOT the version the manifest pins'}")
for name, found in problems.items():
    print(f"  {name:14} {'ok' if not found else ''}".rstrip())
    for line in found:
        print(f"    {line}")
PY

block harvest
on 'python harvest.py'

block additions
on 'wc -l data/eval.jsonl data/eval-additions.jsonl'
on 'grep e39 data/eval-additions.jsonl'

block build
on 'python buildset.py'

block check
on 'python check_set.py data/eval-v2.jsonl'

block pasted
on "cp data/eval-v2.jsonl draft.jsonl && echo '{\"id\": \"e43\", \"question\": \"Order [order] - I want to return it. Who pays for the return postage? Tiago Moura, [phone]\", \"gold\": [[\"returns-policy\", \"How to start a return\"]], \"facts\": [\"Returns are free\"]}' >> draft.jsonl"
on 'python check_set.py draft.jsonl'

block stale
on "cp -r data/docs docs-next && sed -i -e 's/free on orders over 40/free on orders over 50/' -e 's/^version: 6$/version: 7/' docs-next/shipping-and-delivery.md"
on 'python check_set.py data/eval-v2.jsonl --docs docs-next'
