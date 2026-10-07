#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of embeddings-vectors, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# The programs are the ones the sections show, written into ~/emb by `put`.
# One file is STAGED and not shown: prices.py, the course's price sheet (it
# sits beside course.json), copied into ~/emb so that ana can run it there.
#
# The 20,000 vectors that every size and build time is measured on are
# random unit vectors from synth.py, not embeddings of text: a float32 takes
# four bytes whatever it holds. The recall figures come from all-MiniLM-L6-v2
# and WordLlama, run on this machine over data/. Build times are wall-clock
# on a machine shared with other work, and they vary from run to run.
#
# Recorded on Ubuntu 24.04, Python 3.11, PostgreSQL 16 with pgvector 0.6.0,
# 4 cores, TZ=America/Sao_Paulo, on 2026-10-05.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
# on 'command': what ana typed in ~/emb, and what it printed.
on() { printf 'ana@lab:~/emb$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
# put PATH: a file ana wrote in ~/emb, from stdin. Its content is shown in the lesson.
put() { lab exec "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"; }
block() { printf '##### %s\n' "$1"; }
# One capture at a time: every run rebuilds ~/emb from nothing.
exec 9>/var/tmp/emb-capture.lock; flock 9
lab reset >/dev/null

put synth.py <<'EOF_FILE'
import numpy as np


def unit_vectors(n, d, seed=18):
    """n random vectors of d float32 numbers, each of length 1."""
    rng = np.random.default_rng(seed)
    X = rng.standard_normal((n, d), dtype=np.float32)
    return X / np.linalg.norm(X, axis=1, keepdims=True)
EOF_FILE
put files.py <<'EOF_FILE'
import os
import faiss
import numpy as np
from synth import unit_vectors

N = 20_000
for d in (384, 1536):
    X = unit_vectors(N, d)
    np.save(f"v{d}.npy", X)
    flat = faiss.IndexFlatIP(d)
    flat.add(X)
    faiss.write_index(flat, f"flat{d}.faiss")
    print(f"{d:5} dims  in memory {X.nbytes:>11,}  {X.nbytes // N:>5} per vector")
    for f in (f"v{d}.npy", f"flat{d}.faiss"):
        size = os.path.getsize(f)
        print(f"{f:>16}  {size:>11,}  {size / N:>7.1f} per vector")
EOF_FILE
put load.py <<'EOF_FILE'
import sys
import numpy as np
import psycopg
from pgvector.psycopg import register_vector

d = int(sys.argv[1])
X = np.load(f"v{d}.npy")
with psycopg.connect(autocommit=True) as conn:
    conn.execute("CREATE EXTENSION IF NOT EXISTS vector")
    register_vector(conn)
    conn.execute(f"CREATE TABLE v{d} (id bigint PRIMARY KEY, embedding vector({d}))")
    copy = f"COPY v{d} (id, embedding) FROM STDIN WITH (FORMAT BINARY)"
    with conn.cursor().copy(copy) as cp:
        cp.set_types(["int8", "vector"])
        for i, v in enumerate(X):
            cp.write_row((i, v))
    conn.execute(f"VACUUM ANALYZE v{d}")
    print(f"v{d}: {len(X)} rows")
EOF_FILE
put sizes.sql <<'EOF_FILE'
SELECT c.relname                          AS "table",
       c.reltuples::bigint                AS "rows",
       pg_relation_size(c.oid)            AS heap,
       pg_relation_size(c.reltoastrelid)  AS toast,
       pg_indexes_size(c.oid)             AS indexes,
       pg_total_relation_size(c.oid) / c.reltuples::bigint AS per_row
  FROM pg_class c
 WHERE c.relname IN ('v384', 'v1536')
 ORDER BY 1 DESC;
EOF_FILE
put index.sql <<'EOF_FILE'
SET maintenance_work_mem = '512MB';
\timing on
CREATE INDEX v384_hnsw  ON v384  USING hnsw (embedding vector_cosine_ops);
CREATE INDEX v1536_hnsw ON v1536 USING hnsw (embedding vector_cosine_ops);
CREATE INDEX v384_ivf   ON v384  USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
CREATE INDEX v1536_ivf  ON v1536 USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);
\timing off
SELECT i.indexrelid::regclass         AS "index",
       pg_relation_size(i.indexrelid) AS bytes,
       pg_relation_size(i.indexrelid) / c.reltuples::bigint AS per_row
  FROM pg_index i JOIN pg_class c ON c.oid = i.indrelid
 WHERE c.relname IN ('v384', 'v1536')
 ORDER BY 1;
EOF_FILE
put graphs.py <<'EOF_FILE'
import os
import time
import faiss
import hnswlib
import numpy as np

N = 20_000
for d in (384, 1536):
    X = np.load(f"v{d}.npy")
    flat = os.path.getsize(f"flat{d}.faiss")
    t = time.perf_counter()
    h = hnswlib.Index(space="ip", dim=d)
    h.init_index(max_elements=N, M=16, ef_construction=64)
    h.add_items(X, np.arange(N))
    h.save_index(f"hnsw{d}.bin")
    took = time.perf_counter() - t
    t = time.perf_counter()
    ivf = faiss.index_factory(d, "IVF100,Flat", faiss.METRIC_INNER_PRODUCT)
    ivf.train(X)
    ivf.add(X)
    faiss.write_index(ivf, f"ivf{d}.faiss")
    took_ivf = time.perf_counter() - t
    for f, s in ((f"hnsw{d}.bin", took), (f"ivf{d}.faiss", took_ivf)):
        size = os.path.getsize(f)
        print(f"{f:>14}  {size:>11,}  {size / N:7.1f} per vector  "
              f"{size / flat:5.2f}x flat  built in {s:5.2f} s")
EOF_FILE
put shrink.py <<'EOF_FILE'
import json
import numpy as np
from minilm import embed
from wordllama import WordLlama

rows = lambda f: [json.loads(l) for l in open(f"data/{f}.jsonl")]
help, queries = rows("help"), rows("queries")
ids = [h["id"] for h in help]
articles = [h["title"] + ". " + h["body"] for h in help]
asked = [q["text"] for q in queries]
others = [b["title"] + ". " + b["blurb"] for b in rows("books")] + [t["text"] for t in rows("tickets")]
def forms(X):
    yield "float32", X, X.nbytes
    h = X.astype(np.float16)
    yield "float16", h.astype(np.float32), h.nbytes
    s = (np.abs(X).max(axis=1, keepdims=True) / 127).astype(np.float32)
    q = np.round(X / s).astype(np.int8)
    yield "int8", q * s, q.nbytes + s.nbytes
    b = np.packbits(X > 0, axis=1)
    yield "binary", np.where(X > 0, 1.0, -1.0), b.nbytes
def recall(D, Q):
    tops = [[ids[i] for i in np.argsort(-(D @ q), kind="stable")[:3]] for q in Q]
    r1 = sum(t[0] in q["relevant"] for t, q in zip(tops, queries))
    r3 = sum(any(i in q["relevant"] for i in t) for t, q in zip(tops, queries))
    return r1, r3

def top10(E):
    S = E @ E.T
    np.fill_diagonal(S, -np.inf)
    return np.argsort(-S, axis=1, kind="stable")[:, :10]
def report(model, X, full):
    exact = top10(full)
    n = len(articles) + len(asked)
    for form, E, size in forms(X):
        r1, r3 = recall(E[:len(articles)], E[len(articles):n])
        mine = top10(E)
        kept = np.mean([len(set(a) & set(b)) / 10 for a, b in zip(mine, exact)])
        print(f"{model:14} {form:8} {size // len(X):5} B  r@1 {r1:2}/24  r@3 {r3:2}/24  "
              f"top-10 kept {kept:.3f}")
texts = articles + asked + others
M = embed(texts)
report("minilm 384", M, M)
wl = WordLlama.load()
W = wl.embed(texts, norm=True)
report("wordllama 256", W, W)
for k in (128, 64):
    Wk = W[:, :k] / np.linalg.norm(W[:, :k], axis=1, keepdims=True)
    report(f"wordllama {k}", Wk, W)
EOF_FILE
put reembed.py <<'EOF_FILE'
import json
import time
import tiktoken
from minilm import embed

rows = lambda f: [json.loads(l) for l in open(f"data/{f}.jsonl")]
texts = ([h["title"] + ". " + h["body"] for h in rows("help")]
         + [b["title"] + ". " + b["blurb"] for b in rows("books")]
         + [t["text"] for t in rows("tickets")])
enc = tiktoken.get_encoding("cl100k_base")
tokens = sum(len(enc.encode(t)) for t in texts)
print(f"{len(texts)} texts, {tokens:,} tokens, {tokens / len(texts):.1f} per text")
t = time.perf_counter()
embed(texts)
took = time.perf_counter() - t
rate = len(texts) / took
print(f"all-MiniLM-L6-v2 on one core: {took:.2f} s, {rate:.0f} texts per second")
N = 1_000_000
per = tokens / len(texts)
print(f"{N:,} texts like these = {N * per:,.0f} tokens")
print(f"  here, one core:  {N / rate / 3600:5.1f} hours")
for p in json.load(open("prices.json")):
    if p["model"].startswith(("text-embedding-3", "gemini", "cohere", "voyage")):
        print(f"  {p['model']:28} ${N * per / 1e6 * p['usd_per_mtok']:8.2f}")
EOF_FILE
put rebuild.py <<'EOF_FILE'
import time
import hnswlib
import numpy as np
from synth import unit_vectors

for n in (5_000, 10_000, 20_000, 40_000):
    X = unit_vectors(n, 384, seed=n)
    t = time.perf_counter()
    h = hnswlib.Index(space="ip", dim=384)
    h.init_index(max_elements=n, M=16, ef_construction=64)
    h.add_items(X, np.arange(n))
    took = time.perf_counter() - t
    print(f"{n:>7,} vectors  {took:6.2f} s  {took / n * 1e6:6.1f} µs per vector")
EOF_FILE
put tombstones.py <<'EOF_FILE'
import os
import hnswlib
import numpy as np
from synth import unit_vectors

X = np.load("v384.npy")
N = len(X)
h = hnswlib.Index(space="ip", dim=384)
h.init_index(max_elements=N, M=16, ef_construction=64, allow_replace_deleted=True)
h.add_items(X, np.arange(N))
h.save_index("live.bin")
print("built:   ", h.get_current_count(), "elements", os.path.getsize("live.bin"), "bytes")
for i in range(0, N, 2):
    h.mark_deleted(i)
h.save_index("live.bin")
print("deleted: ", h.get_current_count(), "elements", os.path.getsize("live.bin"), "bytes")
labels, _ = h.knn_query(X[:100], k=10)
print("deleted ids among 1,000 results:", int((labels % 2 == 0).sum()))
new = unit_vectors(5_000, 384, seed=5)
try:
    h.add_items(new, np.arange(N, N + 5_000))
except RuntimeError as e:
    print("add:     ", e)
h.add_items(new, np.arange(N, N + 5_000), replace_deleted=True)
h.save_index("live.bin")
print("replaced:", h.get_current_count(), "elements", os.path.getsize("live.bin"), "bytes")
EOF_FILE
put vacuum.sql <<'EOF_FILE'
SET maintenance_work_mem = '512MB';
CREATE VIEW space AS
SELECT (SELECT count(*) FROM v384)              AS "rows",
       pg_relation_size(to_regclass('v384'))      AS heap,
       pg_relation_size(to_regclass('v384_hnsw')) AS hnsw,
       pg_relation_size(to_regclass('v384_ivf'))  AS ivf;
TABLE space;
DELETE FROM v384 WHERE id % 2 = 0;
TABLE space;
\timing on
VACUUM v384;
\timing off
TABLE space;
\timing on
REINDEX TABLE CONCURRENTLY v384;
\timing off
TABLE space;
EOF_FILE
put alias.py <<'EOF_FILE'
import json
from qdrant_client import QdrantClient, models
from minilm import embed
from wordllama import WordLlama

help = [json.loads(l) for l in open("data/help.jsonl")]
texts = [h["title"] + ". " + h["body"] for h in help]
wl = WordLlama.load()
MODEL = {"help_v1": embed, "help_v2": lambda t: wl.embed(t, norm=True)}
client = QdrantClient(path="qdrant")
def build(name):
    V = MODEL[name](texts)
    client.create_collection(name, vectors_config=models.VectorParams(
        size=V.shape[1], distance=models.Distance.COSINE))
    client.upsert(name, [models.PointStruct(id=i, vector=v.tolist(), payload={"id": h["id"]})
                         for i, (h, v) in enumerate(zip(help, V))])
def point_alias(name):
    ops = [models.CreateAliasOperation(create_alias=models.CreateAlias(
        collection_name=name, alias_name="help"))]
    if behind_alias():
        ops.insert(0, models.DeleteAliasOperation(delete_alias=models.DeleteAlias(alias_name="help")))
    client.update_collection_aliases(change_aliases_operations=ops)

def behind_alias():
    return {a.alias_name: a.collection_name for a in client.get_aliases().aliases}.get("help")
def search(question, embed_with):
    hit = client.query_points("help", query=embed_with([question])[0].tolist(), limit=1).points[0]
    return hit.payload["id"], round(hit.score, 3)

q = "how do I get my money back"
build("help_v1"); point_alias("help_v1")
print(behind_alias(), search(q, embed))
build("help_v2"); point_alias("help_v2")
print(behind_alias(), search(q, MODEL[behind_alias()]))
try:
    print(search(q, embed))
except Exception as e:
    print(type(e).__name__, str(e)[:90])
client.close()
EOF_FILE
put budget.py <<'EOF_FILE'
import json
import psycopg

prices = {p["model"]: p for p in json.load(open("prices.json"))}
small, large = prices["text-embedding-3-small"], prices["text-embedding-3-large"]
CHUNKS, PER = 2_000_000, 300
tokens = CHUNKS * PER
GB = 1e9
with psycopg.connect() as conn:
    row, hnsw = conn.execute("""SELECT pg_table_size('v1536') / 20000.0,
                                       pg_relation_size('v1536_hnsw') / 20000.0""").fetchone()
print(f"measured at 1536 dims: {row:.0f} B a row, {hnsw:.0f} B a row of HNSW")
print(f"{CHUNKS:,} chunks x {PER} tokens = {tokens:,} tokens")
print(f"embed once, {small['model']}:  ${tokens / 1e6 * small['usd_per_mtok']:.2f}"
      f"  (batch ${tokens / 1e6 * small['batch_usd_per_mtok']:.2f})")
print(f"raw float32 vectors:     {CHUNKS * small['dims'] * 4 / GB:6.2f} GB")
print(f"table in Postgres:       {CHUNKS * float(row) / GB:6.2f} GB")
print(f"HNSW index in Postgres:  {CHUNKS * float(hnsw) / GB:6.2f} GB")
churn = 0.05
print(f"re-embed {churn:.0%} a month:     ${tokens * churn / 1e6 * small['usd_per_mtok']:.2f}")
print(f"move to {large['model']}: ${tokens / 1e6 * large['usd_per_mtok']:.2f}"
      f"  raw vectors {CHUNKS * large['dims'] * 4 / GB:.2f} GB,"
      f" {CHUNKS * (small['dims'] + large['dims']) * 4 / GB:.2f} GB while both exist")
EOF_FILE

block files
on 'python files.py'

block load
on 'python load.py 384 && python load.py 1536'
on 'psql -f sizes.sql'

block index
on 'psql -f index.sql'

block limit
on 'psql -c "CREATE TABLE v3072 (embedding vector(3072))" -c "CREATE INDEX ON v3072 USING hnsw (embedding vector_cosine_ops)"'

block graphs
on 'python graphs.py'

block shrink
on 'python shrink.py'

block prices
on 'python3 prices.py'
on 'python3 prices.py --json > prices.json'

block reembed
on 'python reembed.py'

block rebuild
on 'nproc'
on 'python rebuild.py'

block tombstones
on 'python tombstones.py'

block vacuum
on 'psql -f vacuum.sql'

block alias
on 'python alias.py'

block budget
on 'python budget.py'
