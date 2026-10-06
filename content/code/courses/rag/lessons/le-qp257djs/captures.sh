#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of rag, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# chunking.py, ingest.py, search.py, answer.py and verify.py live in
# ../../lab/code and are lessons 4 to 8's; context.py, there too, is this
# lesson's, and lessons 13 to 17 import it. The other programs are written by
# `put`. Every reply comes from extract-1, the lab's stand-in generator, which
# is not a language model (lab/labgen.py says what it does): it reads every
# sentence it is given the same way wherever it sits, so nothing in this
# lesson measures how a real model is distracted by extra text or by where a
# fact is placed. Those effects are quoted from the published research the
# sections name. Token counts use tiktoken's cl100k_base.
#
# Recorded on Ubuntu 24.04, Python 3.11, PostgreSQL 16 with pgvector 0.6.0,
# TZ=America/Sao_Paulo, on 2026-10-06.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB_SH=${LAB_SH:-../../lab.sh}
CODE=$(cd "$(dirname "$LAB_SH")" && pwd)/lab/code
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@lab:~/rag$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
put() { lab exec "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"; }
use() { for f in "$@"; do put "$f" < "$CODE/$f"; done; }
block() { printf '##### %s\n' "$1"; }
exec 9>/var/tmp/rag-capture.lock; flock 9
lab reset >/dev/null
use chunking.py ingest.py search.py answer.py verify.py context.py
lab exec 'python ingest.py' >/dev/null
put window.py <<'EOF_FILE'
import sys

from answer import SYSTEM, prompt, sources_for
from context import header, tokens

question = sys.argv[1]
sources = sources_for(question)
print(f"{tokens(SYSTEM):5}  instructions")
for n, s in enumerate(sources, 1):
    print(f"{tokens(header(n, s)):5}  header [{n}]")
    print(f"{tokens(s['text']):5}  text   [{n}] {s['path']}")
print(f"{tokens('Question: ' + question):5}  question")
total = tokens(SYSTEM) + tokens(prompt(question, sources))
print(f"{total:5}  sent, of a window of 8192")
EOF_FILE
put sweep.py <<'EOF_FILE'
import itertools
import json

from context import FLOOR, tokens
from minilm import embed
from search import vector

questions = [q for q in map(json.loads, open("data/eval.jsonl")) if q["facts"]]
norm = lambda t: " ".join(t.replace("|", " ").split())
print(f"{'k':>3} {'found':>6} {'tokens':>7} {'alike':>6} {'above floor':>12}")
for k in (1, 2, 3, 5, 8, 12):
    found, used, alike, kept = 0, 0, 0, 0
    for q in questions:
        top = vector(q["question"], k, "status = %s", ("current",))
        found += any(f in norm(r[2]) for r in top for f in q["facts"])
        used += tokens("\n".join(r[2] for r in top))
        v = embed([r[2] for r in top])
        alike += sum(1 for i, j in itertools.combinations(range(len(top)), 2) if v[i] @ v[j] >= 0.8)
        kept += sum(1 for r in top if r[3] >= FLOOR)
    n = len(questions)
    print(f"{k:3} {found:3}/{n} {used / n:7.0f} {alike:6} {kept / n:12.1f}")
EOF_FILE
put alike.py <<'EOF_FILE'
import sys

from context import candidates, dedupe

found = candidates(sys.argv[1], 10)
for s in found:
    print(f"{s['score']:.3f}  {s['path']}")
print("after dedupe:")
for s in dedupe(found):
    print(f"{s['score']:.3f}  {s['path']}")
EOF_FILE
put removed.py <<'EOF_FILE'
import json

from context import candidates, dedupe

total, removed = 0, 0
for q in map(json.loads, open("data/eval.jsonl")):
    found = candidates(q["question"], 10, "status = %s", ("current",))
    total += len(found)
    removed += len(found) - len(dedupe(found))
print(f"{removed} of {total} sources removed as duplicates, over 30 questions")
EOF_FILE
put squeeze.py <<'EOF_FILE'
import json
import sys

from context import candidates, compress, tokens

split = sys.argv[1]
questions = [q for q in map(json.loads, open("data/eval.jsonl"))
             if q["facts"] and (int(q["id"][1:]) % 3 == 0) == (split == "held-out")]
norm = lambda t: " ".join(t.replace("|", " ").split())
found = {q["id"]: candidates(q["question"], 3, "status = %s", ("current",)) for q in questions}
print(f"{split}: {len(questions)} answerable questions")
print(f"{'keep':>5} {'found':>6} {'tokens':>7}")
for keep in (0.0, 0.35, 0.45, 0.5, 0.6, 1.0):
    hits, used = 0, 0
    for q in questions:
        cut = [compress(q["question"], s, keep) for s in found[q["id"]]]
        hits += any(f in norm(s["text"]) for s in cut for f in q["facts"])
        used += sum(tokens(s["text"]) for s in cut)
    print(f"{keep:5.2f} {hits:3}/{len(questions)} {used / len(questions):7.0f}")
EOF_FILE
put squeezed.py <<'EOF_FILE'
import sys

from context import candidates, compress

question = sys.argv[1]
source = candidates(question, 1)[0]
print(source["path"])
print(" ".join(source["text"].split()))
print("kept:")
print(compress(question, source)["text"])
EOF_FILE
put order.py <<'EOF_FILE'
from context import ends
from haystack import Document
from haystack.components.rankers import LostInTheMiddleRanker

ranked = ["first", "second", "third", "fourth", "fifth"]
print("ends():              ", ends(ranked))
docs = [Document(content=name) for name in ranked]
print("LostInTheMiddleRanker:", [d.content for d in LostInTheMiddleRanker().run(documents=docs)["documents"]])
EOF_FILE
put headers.py <<'EOF_FILE'
import json

from context import header, pack, tokens

questions = [q for q in map(json.loads, open("data/eval.jsonl"))]
heads, texts = 0, 0
for q in questions:
    for n, s in enumerate(pack(q["question"], where="status = %s", params=("current",)), 1):
        heads += tokens(header(n, s))
        texts += tokens(s["text"])
print(f"headers {heads}, texts {texts}: headers are {heads / (heads + texts):.0%} of the sources' tokens")
EOF_FILE
put compare.py <<'EOF_FILE'
import json

import answer as plain
import context as packed
from context import tokens
from verify import check

norm = lambda t: " ".join(t.replace("|", " ").split())
questions = list(map(json.loads, open("data/eval.jsonl")))
where = dict(where="status = %s", params=("current",))
print(f"{'pipeline':8} {'correct':>8} {'refused':>8} {'faithful':>9} {'sources':>8} {'prompt':>7}")
for name, run in (("plain", plain.answer), ("packed", packed.answer)):
    correct, refused, faithful, sources, sent = 0, 0, 0, 0, 0
    for q in questions:
        reply, found = run(q["question"], **where)
        refusal = reply == plain.REFUSAL
        correct += refusal if not q["facts"] else not refusal and any(f in norm(reply) for f in q["facts"])
        refused += refusal and not q["facts"]
        faithful += refusal or all(v.startswith(("quoted", "close")) for _, _, v in check(reply, found))
        sources += len(found)
        sent += tokens(plain.SYSTEM) + tokens(plain.prompt(q["question"], found)) if found else 0
    n = len(questions)
    print(f"{name:8} {correct:5}/{n} {refused:6}/4 {faithful:6}/{n} {sources / n:8.1f} {sent / n:7.0f}")
EOF_FILE

put three.py <<'EOF_FILE'
import sys

from answer import SYSTEM, sources_for
from context import header, pack, tokens
from search import conn, vector

question = sys.argv[1]
rows = vector(question, 12)
updated = dict(conn.execute("SELECT id, updated FROM chunks WHERE id = ANY(%s)", ([r[0] for r in rows],)).fetchall())
near = [{"path": p, "text": t, "updated": updated[i]} for i, p, t, _ in rows]
for name, sources in (("twelve nearest", near), ("lesson 7", sources_for(question)), ("packed", pack(question))):
    heads = sum(tokens(header(n, s)) for n, s in enumerate(sources, 1))
    texts = sum(tokens(s["text"]) for s in sources)
    asked = tokens("Question: " + question)
    print(f"{name:15} instructions {tokens(SYSTEM):3}  headers {heads:3}  sources {texts:3}  question {asked:2}"
          f"  total {tokens(SYSTEM) + heads + texts + asked:4}  ({len(sources)} sources)")
EOF_FILE

block window
on 'python window.py "How long is a gift card valid?"'
block sweep
on 'python sweep.py'
block alike
on 'python alike.py "When can an audiobook be refunded?"'
on 'python removed.py'
block squeeze
on 'python squeeze.py dev'
on 'python squeeze.py held-out'
on 'python squeezed.py "How long after my return arrives will I get the refund?"'
on 'python squeezed.py "Can I return a signed copy?"'
block order
on 'python order.py'
block headers
on 'python headers.py'
block three
on 'python three.py "How long is a gift card valid?"'
block compare
on 'python compare.py'
