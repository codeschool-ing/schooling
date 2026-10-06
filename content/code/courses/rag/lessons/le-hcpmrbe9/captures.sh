#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of rag, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# chunking.py, ingest.py, search.py and answer.py live in ../../lab/code and
# are lessons 4 to 7's; access.py and policy.sql, there too, are this
# lesson's. policy.sql creates a PostgreSQL role called assistant, which is
# cluster-wide and survives `lab.sh reset`; the script creates it only if it
# is missing. The roles a reader can have (customer, agent, finance and the
# rest) are a dictionary in access.py standing in for the shop's sign-in.
# Every reply comes from extract-1, the lab's stand-in generator, which is not
# a language model (lab/labgen.py says what it does).
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
use chunking.py ingest.py search.py answer.py access.py policy.sql
lab exec 'python ingest.py' >/dev/null
put roles.py <<'EOF_FILE'
import sys

import access
from answer import FLOOR, REFUSAL, ask
from search import conn as loader

assistant = access.connect()
question = sys.argv[1]
print(question)
for role in sys.argv[2:]:
    found = [r for r in access.search(assistant, role, question) if r[4] >= FLOOR]
    updated = dict(loader.execute("SELECT id, updated FROM chunks WHERE id = ANY(%s)", ([r[0] for r in found],)))
    sources = [{"path": p, "text": t, "updated": updated[i]} for i, p, t, _, _ in found]
    print(f"{role:9} {', '.join(f'{r[1]} ({r[3]}, {r[4]:.3f})' for r in found) or 'nothing above the floor'}")
    print(f"{'':9} {ask(question, sources) if sources else REFUSAL}")
EOF_FILE
put after.py <<'EOF_FILE'
import sys

import access
from minilm import embed
from search import conn

role, question = sys.argv[1], sys.argv[2]
q = embed(question)[0]
top = conn.execute("SELECT path, audience, 1 - (embedding <=> %s) FROM chunks WHERE status = 'current'"
                   " ORDER BY embedding <=> %s LIMIT 3", (q, q)).fetchall()
print("the three nearest, for anybody:")
for path, audience, score in top:
    print(f"  {score:.3f}  {audience:8} {path}")
kept = [row for row in top if row[1] in access.audiences(role)]
print(f"then dropped for {role}: {len(kept)} of 3 left")
EOF_FILE
put asassistant.py <<'EOF_FILE'
import sys

import psycopg

with psycopg.connect(user="assistant") as conn:
    if len(sys.argv) > 1:
        conn.execute("SELECT set_config('rag.audiences', %s, true)", (sys.argv[1],))
    rows = conn.execute("SELECT audience, count(*) FROM chunks GROUP BY audience ORDER BY audience").fetchall()
    print(rows or "no rows")
EOF_FILE
put index.py <<'EOF_FILE'
import sys

from minilm import embed
from search import conn

q = embed(sys.argv[1])[0]
for scan in ("on", "off"):
    with conn.transaction():
        conn.execute("SELECT set_config('enable_seqscan', %s, true)", (scan,))
        rows = conn.execute("SELECT path FROM chunks WHERE audience = 'finance'"
                            " ORDER BY embedding <=> %s LIMIT 5", (q,)).fetchall()
    print(f"sequential scan {scan:3}: {len(rows)} of 5")
EOF_FILE
put narrow.py <<'EOF_FILE'
import sys

import access

role, only, question = sys.argv[1], sys.argv[2].split(","), sys.argv[3]
found = access.search(access.connect(), role, question, only=only)
print(f"{role}, asking for {only}: {[p for _, p, _, _, _ in found] or 'nothing'}")
EOF_FILE
put audit.py <<'EOF_FILE'
import json
import sys

import access
from minilm import embed
from search import conn as loader


def careless(conn, role, question, k):
    """A search written without the role, through a connection the policy does not limit."""
    q = embed(question)[0]
    return loader.execute("SELECT id, path, text, audience, 1 - (embedding <=> %s) FROM chunks"
                          " ORDER BY embedding <=> %s LIMIT %s", (q, q, k)).fetchall()


search = careless if "--careless" in sys.argv else access.search
assistant = access.connect()
questions = [q["question"] for q in map(json.loads, open("data/eval.jsonl"))]
questions += [q["question"] for q in map(json.loads, open("data/identifiers.jsonl"))]
leaks, seen = 0, 0
for role in access.ROLES:
    for question in questions:
        for row in search(assistant, role, question, 5):
            seen += 1
            leaks += row[3] not in access.audiences(role)
print(f"{len(access.ROLES)} roles x {len(questions)} questions, {seen} rows returned, {leaks} outside the role")
EOF_FILE
put deleted.py <<'EOF_FILE'
import access
from search import conn

QUESTION = "What is a SEV-2 incident?"
chunks = conn.execute("SELECT count(*) FROM chunks WHERE doc_id = 'warehouse-runbook'").fetchone()[0]
found = [r[1] for r in access.search(access.connect(), "agent", QUESTION, 5)]
from_it = [p for p in found if p.startswith("Warehouse on-call runbook")]
print(f"chunks of warehouse-runbook in the table: {chunks}")
print(f"of the agent's 5 nearest for {QUESTION!r}, from the runbook: {len(from_it)}")
EOF_FILE

block after
on 'python after.py agent "When does an order get held for manual fraud review?"'
block rls
on 'psql -q -f policy.sql'
on 'python asassistant.py'
on 'python asassistant.py public'
on 'python asassistant.py public,staff'
block roles
on 'python roles.py "When does an order get held for manual fraud review?" customer agent finance'
on 'python roles.py "What happens to an order that looks fraudulent?" agent finance'
block index
on 'psql -qc "CREATE INDEX ON chunks USING hnsw (embedding vector_cosine_ops)"'
on 'python index.py "When does an order get held for manual fraud review?"'
on 'psql -qc "DROP INDEX chunks_embedding_idx"'
block flag
on 'python roles.py "How many refunds can I get before my account is flagged?" customer finance'
block narrow
on 'python narrow.py customer finance "How many refunds can I get before my account is flagged?"'
on 'python narrow.py seller sellers "How long do I have to dispatch an order?"'
block audit
on 'python audit.py'
on 'python audit.py --careless'
block deleted
on 'python deleted.py'
on 'rm data/docs/warehouse-runbook.md && python ingest.py'
on 'python deleted.py'
