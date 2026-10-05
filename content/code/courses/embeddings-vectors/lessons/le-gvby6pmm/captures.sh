#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of embeddings-vectors, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# The programs are the ones the sections show, written into ~/emb by `put`.
# Nothing is staged: every program that runs is shown in the lesson.
#
# The 2,000 rows of `points` (fill.py) and the hnswlib index in ef.py are
# random unit vectors from a seeded generator, not embeddings of any text: the
# behaviour they show belongs to the index, not to the data. Every other vector
# comes from all-MiniLM-L6-v2 or WordLlama, run on this machine.
#
# Recorded on Ubuntu 24.04, Python 3.11, PostgreSQL 16 with pgvector 0.6.0,
# TZ=America/Sao_Paulo, on 2026-10-05.
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

put search.py <<'EOF_FILE'
import json
import numpy as np
from minilm import embed

help = [json.loads(line) for line in open("data/help.jsonl")]
ids = [h["id"] for h in help]
D = embed([h["title"] + ". " + h["body"] for h in help])
def search(text, k=3):
    scores = D @ embed(text)[0]
    top = np.argsort(-scores)[:k]
    return [(float(scores[i]), ids[i], help[i]["title"]) for i in top]
EOF_FILE
put topk.py <<'EOF_FILE'
from search import search

for question in ["the box never showed up", "do you sell concert tickets?"]:
    print(question)
    for score, id, title in search(question, k=3):
        print(f"  {score:.3f}  {id}  {title}")
EOF_FILE
put recall_k.py <<'EOF_FILE'
import json
import numpy as np
import tiktoken
from minilm import embed
from wordllama import WordLlama

help = [json.loads(line) for line in open("data/help.jsonl")]
ids = [h["id"] for h in help]
texts = [h["title"] + ". " + h["body"] for h in help]
queries = [json.loads(line) for line in open("data/queries.jsonl")]
wl = WordLlama.load()
models = {"minilm": embed, "wordllama": lambda t: wl.embed(t, norm=True)}
ranks = {}
for name, f in models.items():
    S = f([q["text"] for q in queries]) @ f(texts).T
    ranks[name] = np.argsort(-S, axis=1)
def found(rank, k):
    return sum(any(ids[j] in q["relevant"] for j in r[:k])
               for r, q in zip(rank, queries))
enc = tiktoken.get_encoding("cl100k_base")
tokens = np.array([len(enc.encode(t)) for t in texts])
print(" k  minilm  wordllama  tokens")
for k in range(1, 11):
    t = tokens[ranks["minilm"][:, :k]].sum(axis=1).mean()
    print(f"{k:2}  {found(ranks['minilm'], k):3}/24  {found(ranks['wordllama'], k):6}/24  {t:6.0f}")
for r, q in zip(ranks["minilm"], queries):
    first = min(list(r).index(ids.index(a)) for a in q["relevant"]) + 1
    if first > 3:
        print(f"minilm puts the answer to {q['text']!r} at {first}")
EOF_FILE
put threshold.py <<'EOF_FILE'
import json
import numpy as np
from minilm import embed
from wordllama import WordLlama

help = [json.loads(line) for line in open("data/help.jsonl")]
ids = [h["id"] for h in help]
texts = [h["title"] + ". " + h["body"] for h in help]
queries = [json.loads(line) for line in open("data/queries.jsonl")]
off_topic = ["do you sell concert tickets?", "what is the weather in Lisbon tomorrow",
             "recommend a good pizza place", "how do I renew my driving licence",
             "is the shop open on Sundays", "I want to speak to a human",
             "who won the football last night", "translate hello into French"]
wl = WordLlama.load()
models = {"minilm": embed, "wordllama": lambda t: wl.embed(t, norm=True)}
for name, f in models.items():
    D = f(texts)
    S = f([q["text"] for q in queries]) @ D.T
    answer = np.array([max(S[i, ids.index(r)] for r in q["relevant"])
                       for i, q in enumerate(queries)])
    off = (f(off_topic) @ D.T).max(axis=1)
    print(name)
    print("  the right article: ", " ".join(f"{s:.3f}" for s in sorted(answer)))
    print("  best for off-topic:", " ".join(f"{s:.3f}" for s in sorted(off)))
    for cut in (0.20, 0.25, 0.30, 0.35):
        print(f"  cut-off {cut:.2f}: keeps {(answer >= cut).sum():2}/24 answers,"
              f" turns away {(off < cut).sum()}/8 off-topic questions")
EOF_FILE
put fill.py <<'EOF_FILE'
import numpy as np
import psycopg
from pgvector.psycopg import register_vector

rng = np.random.default_rng(16)
V = rng.standard_normal((2000, 384)).astype(np.float32)
V /= np.linalg.norm(V, axis=1, keepdims=True)

with psycopg.connect(autocommit=True) as conn:
    conn.execute("CREATE EXTENSION IF NOT EXISTS vector")
    register_vector(conn)
    conn.execute("CREATE TABLE points (id int PRIMARY KEY, embedding vector(384))")
    with conn.cursor().copy("COPY points FROM STDIN WITH (FORMAT BINARY)") as copy:
        copy.set_types(["int4", "vector"])
        for i, v in enumerate(V):
            copy.write_row((i, v))
    conn.execute("CREATE INDEX ON points USING hnsw (embedding vector_cosine_ops)")
EOF_FILE
put top100.sql <<'EOF_FILE'
SELECT count(*) AS returned
FROM (SELECT id FROM points
      ORDER BY embedding <=> (SELECT embedding FROM points WHERE id = 7)
      LIMIT 100) AS top;
EOF_FILE
put ef.py <<'EOF_FILE'
import hnswlib
import numpy as np

rng = np.random.default_rng(16)
V = rng.standard_normal((2000, 384)).astype(np.float32)
V /= np.linalg.norm(V, axis=1, keepdims=True)
index = hnswlib.Index(space="cosine", dim=384)
index.init_index(max_elements=2000)
index.add_items(V, np.arange(2000))
index.set_ef(10)
labels, distances = index.knn_query(V[7], k=100)
print("ef:", index.ef, " asked for 100, got", labels.shape[1])
EOF_FILE
put rerank.py <<'EOF_FILE'
import json
import numpy as np
from minilm import embed
from wordllama import WordLlama

help = [json.loads(line) for line in open("data/help.jsonl")]
ids = [h["id"] for h in help]
texts = [h["title"] + ". " + h["body"] for h in help]
queries = [json.loads(line) for line in open("data/queries.jsonl")]
qtexts = [q["text"] for q in queries]

def found(ranked, k):
    return sum(any(ids[j] in q["relevant"] for j in r[:k])
               for r, q in zip(ranked, queries))
D, Q = embed(texts), embed(qtexts)
codes = np.packbits(D > 0, axis=1)
qcodes = np.packbits(Q > 0, axis=1)
print("bytes per article:", D[0].nbytes, "as floats,", codes[0].nbytes, "as bits")
def first_pass(qc, n):
    differing = np.unpackbits(codes ^ qc, axis=1).sum(axis=1)
    return np.argsort(differing, kind="stable")[:n]

def rerank(candidates, score):
    return candidates[np.argsort(-score[candidates])]
print("                        @1  @3")
exact = [np.argsort(-(D @ q)) for q in Q]
print("float, every article   ", found(exact, 1), found(exact, 3))
print("bits only              ", *(found([first_pass(c, 40) for c in qcodes], k) for k in (1, 3)))
for n in (5, 10, 20):
    ranked = [rerank(first_pass(c, n), D @ q) for c, q in zip(qcodes, Q)]
    print(f"bits {n:2}, rerank floats ", found(ranked, 1), found(ranked, 3))
wl = WordLlama.load()
W, WQ = wl.embed(texts, norm=True), wl.embed(qtexts, norm=True)
wordllama = [np.argsort(-(W @ q)) for q in WQ]
print("wordllama only         ", found(wordllama, 1), found(wordllama, 3))
both = [rerank(r[:10], D @ q + W @ wq) for r, q, wq in zip(wordllama, Q, WQ)]
print("wordllama 10, rerank   ", found(both, 1), found(both, 3))
EOF_FILE

block topk
on 'python topk.py'

block recall
on 'python recall_k.py'

block threshold
on 'python threshold.py'

block fill
on 'python fill.py'
on 'psql -c "SHOW hnsw.ef_search"'
on 'psql -f top100.sql -c "SHOW hnsw.ef_search"'

block explain
on 'psql -c "EXPLAIN (COSTS OFF) SELECT id FROM points ORDER BY embedding <=> (SELECT embedding FROM points WHERE id = 7) LIMIT 100"'

block ef100
on 'psql -c "SET hnsw.ef_search = 100" -f top100.sql'
on 'psql -c "SET enable_indexscan = off" -f top100.sql'

block hnswlib
on 'python ef.py'

block rerank
on 'python rerank.py'
