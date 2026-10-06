#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of rag, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# chunking.py is lesson 4's, and ingest.py is this lesson's; both live in
# ../../lab/code, where later lessons take them from, and `use` copies them
# into ~/rag. The other programs are written by `put` and shown in the
# sections that run them. The edit to the returns policy in the section on ids
# is made by the `sed` the lesson shows, on the lab's copy in ~/rag; the
# course's corpus is not changed. Every vector comes from all-MiniLM-L6-v2,
# through labgen and labembed, on this machine.
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
use chunking.py ingest.py
put header.py <<'EOF_FILE'
import json

from chunking import load, structured
from minilm import embed

questions = [q for q in map(json.loads, open("data/eval.jsonl")) if q["facts"]]
norm = lambda t: " ".join(t.split())
qv = embed([q["question"] for q in questions])

for size in (60, 120):
    chunks = [(path, text) for _, body in load().values() for path, text in structured(body, size)]
    for label, inputs in (("text only", [t for _, t in chunks]),
                          ("path + text", [p + "\n" + t for p, t in chunks])):
        scores = qv @ embed(inputs).T
        found = sum(any(f in norm(chunks[i][1]) for i in s.argsort()[::-1][:3] for f in q["facts"])
                    for q, s in zip(questions, scores))
        print(f"structured {size:3}, {label:12} found {found}/{len(questions)}")
EOF_FILE
put requests.py <<'EOF_FILE'
import json

for line in open("/var/log/labembed/requests.jsonl"):
    r = json.loads(line)
    print(r.get("status"), r.get("inputs", ""), r.get("error", ""))
EOF_FILE
put check_index.py <<'EOF_FILE'
import sys

import psycopg
from openai import OpenAI
from pgvector.psycopg import register_vector

failures = []
with psycopg.connect() as conn:
    register_vector(conn)
    one = lambda sql: conn.execute(sql).fetchone()[0]
    docs = one("SELECT count(DISTINCT doc_id) FROM chunks")
    if docs != 13:
        failures.append(f"{docs} documents in the index, expected 13")
    if one("SELECT count(*) FROM chunks WHERE vector_dims(embedding) <> 384"):
        failures.append("a vector with the wrong number of dimensions")
    if one("SELECT count(DISTINCT model) FROM chunks") != 1:
        failures.append("vectors from more than one model")
    if one("SELECT max(tokens) FROM chunks") > 400:
        failures.append("a chunk over 400 tokens")
    # A question whose answer is known: the chunk holding it must come first.
    q = OpenAI().embeddings.create(model="lab-minilm", input=["How long is a gift card valid?"]).data[0].embedding
    top = conn.execute("SELECT path FROM chunks ORDER BY embedding <=> %s::vector LIMIT 1", (q,)).fetchone()[0]
    if "Validity" not in top:
        failures.append(f"the gift card question found {top!r}")
print("\n".join(failures) or f"ok: {docs} documents, every check passed")
sys.exit(1 if failures else 0)
EOF_FILE

block header
on 'python header.py'
block provider
on 'python ingest.py'
on 'wc -l < /var/log/labembed/requests.jsonl'
on 'psql -qc "DROP TABLE chunks"'
on 'curl -s -X POST localhost:8500/lab/config -d "{\"fail\": 2, \"status\": 429}"; echo'
on 'python ingest.py'
on 'python requests.py | tail -n 7'
block table
on 'psql -c "\d chunks"'
on 'psql -c "SELECT doc_id, count(*) AS chunks, sum(tokens) AS tokens FROM chunks GROUP BY doc_id ORDER BY doc_id"'
on 'psql -c "SELECT id, path, status, audience FROM chunks WHERE doc_id = '"'"'returns-policy'"'"' ORDER BY position LIMIT 4"'
on 'python check_index.py; echo "exit $?"'
block ids
on 'python ingest.py'
on 'sed -i "s/We refund within three working days/We refund within two working days/" data/docs/returns-policy.md'
on 'python ingest.py'
block delete
on 'sed -i "s/^status: current$/status: superseded/" data/docs/gift-cards.md'
on 'python ingest.py'
on 'psql -c "SELECT status, count(*) FROM chunks GROUP BY status"'
on 'rm data/docs/returns-policy-2025.md'
on 'python ingest.py'
on 'psql -tc "SELECT count(*) FROM chunks WHERE doc_id = '"'"'returns-policy-2025'"'"'"'
block index
on 'psql -c "CREATE INDEX ON chunks USING hnsw (embedding vector_cosine_ops)"'
on 'psql -c "SET enable_seqscan = off" -c "EXPLAIN (COSTS OFF) SELECT path FROM chunks ORDER BY embedding <=> (SELECT embedding FROM chunks LIMIT 1) LIMIT 3"'
block check
on 'python check_index.py; echo "exit $?"'
