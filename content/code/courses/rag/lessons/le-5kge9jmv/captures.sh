#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of rag, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# chunking.py, ingest.py and search.py live in ../../lab/code and `use` copies
# them into ~/rag; ingest.py builds the index lesson 5 built, and search.py is
# this lesson's, shown in its sections. The other programs are written by
# `put`. data/identifiers.jsonl, six questions about exact identifiers, was
# written for the course like the rest of data/. The follow-up question in the
# section on rewriting is rewritten by hand, by the course: no model wrote it.
# Every vector and every score was computed on this machine.
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
use chunking.py ingest.py search.py
lab exec 'python ingest.py' >/dev/null
put show.py <<'EOF_FILE'
import sys

import search

method, question = sys.argv[1], sys.argv[2]
for rank, (id, path, text, score) in enumerate(getattr(search, method)(question, 5), 1):
    print(f"{rank}  {score:7.3f}  {path}  | {' '.join(text.split())[:48]}")
EOF_FILE
put measure.py <<'EOF_FILE'
import json

from search import hybrid, lexical, rerank, vector

norm = lambda t: " ".join(t.split())
found = lambda rows, q: any(f in norm(r[2]) for r in rows for f in q["facts"])
methods = {
    "vector": lambda q, k: vector(q, k),
    "lexical": lambda q, k: lexical(q, k),
    "hybrid": lambda q, k: hybrid(q, k),
    "hybrid, reranked": lambda q, k: rerank(q, hybrid(q, 20), k),
}
sets = {name: [q for q in map(json.loads, open(f"data/{name}.jsonl")) if q["facts"]]
        for name in ("eval", "identifiers")}
print(f"{'':18}{'eval @1':>9}{'eval @3':>9}{'ids @1':>8}{'ids @3':>8}")
for name, run in methods.items():
    cells = [f"{sum(found(run(q['question'], k), q) for q in sets[s]):>{w - 3}}/{len(sets[s]):<2}"
             for s, w in (("eval", 9), ("identifiers", 8)) for k in (1, 3)]
    print(f"{name:18}" + "".join(cells[:2]) + "".join(cells[2:]))
EOF_FILE
put reorder.py <<'EOF_FILE'
import sys

from search import hybrid, rerank

question, fact = sys.argv[1], sys.argv[2]
before = hybrid(question, 20)
after = rerank(question, before, 20)
for label, rows in (("hybrid", before), ("reranked", after)):
    print(label)
    for rank, (id, path, text, score) in enumerate(rows[:5], 1):
        mark = "  <- the answer" if fact in " ".join(text.split()) else ""
        print(f"  {rank}  {path}{mark}")
EOF_FILE
put scores.py <<'EOF_FILE'
import json

from search import vector

for line in open("data/eval.jsonl"):
    q = json.loads(line)
    best = vector(q["question"], 1)[0][3]
    print(f"{best:.3f}  {'answerable  ' if q['facts'] else 'unanswerable'}  {q['question']}")
EOF_FILE

block first
on 'python show.py vector "How much is express delivery?"'
block lexical
on 'python show.py vector "What does error E-4104 mean?"'
on 'python show.py lexical "What does error E-4104 mean?"'
on 'python show.py lexical "how do I send a book back"'
block hybrid
on 'python show.py hybrid "What does error E-4104 mean?"'
on 'python measure.py'
block rerank
on 'python reorder.py "How much is express delivery?" "9.90"'
on 'python reorder.py "How many days do I have to return a printed book?" "30 days from delivery"'
block rewrite
on 'python show.py vector "And for e-books?"'
on 'python show.py vector "How long do I have to return an e-book?"'
block filters
on 'python show.py vector "Who pays for the return postage?"'
on 'python -c "from search import vector; [print(r[1]) for r in vector(\"Who pays for the return postage?\", 3, \"status = %s AND audience = %s\", (\"current\", \"public\"))]"'
block threshold
on 'python scores.py | sort -r'
