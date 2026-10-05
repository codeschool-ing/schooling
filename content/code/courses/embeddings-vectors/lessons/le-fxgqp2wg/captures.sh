#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of embeddings-vectors, as a script
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
# The 5,000 rows of `messages` (messages.py) and the 200,000 vectors of
# prefilter_cost.py are random unit vectors from a seeded generator, with a
# language assigned by row number, not embeddings of any text: what they show
# belongs to the index and the filter, not to the data. The three Folio
# articles in shops.py are written for the course, like the rest of data/;
# Folio, a second shop, does not exist. policy.sql creates the role helpdesk,
# which outlives `lab reset` because roles belong to the cluster; it is created
# only if it is missing. Every other vector comes from all-MiniLM-L6-v2, run on
# this machine.
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
put store.py <<'EOF_FILE'
import json
import numpy as np
from minilm import embed

help = [json.loads(line) for line in open("data/help.jsonl")]
ids = [h["id"] for h in help]
D = embed([h["title"] + ". " + h["body"] for h in help])
meta = {key: np.array([h[key] for h in help]) for key in ("lang", "category", "updated")}
def post_filter(text, k, key, value):
    scores = D @ embed(text)[0]
    top = np.argsort(-scores)[:k]
    return [(ids[i], round(float(scores[i]), 3)) for i in top if meta[key][i] == value]
def pre_filter(text, k, key, value):
    allowed = np.flatnonzero(meta[key] == value)
    scores = D[allowed] @ embed(text)[0]
    top = np.argsort(-scores)[:k]
    return [(ids[allowed[j]], round(float(scores[j]), 3)) for j in top]
EOF_FILE
put filtered.py <<'EOF_FILE'
from store import post_filter, pre_filter

for text, key, value in [("I was charged twice", "category", "payments"),
                         ("how do I return a book", "lang", "pt")]:
    print(f"{text!r} where {key} = {value!r}, k = 3")
    print("  post-filter:", post_filter(text, 3, key, value))
    print("  pre-filter: ", pre_filter(text, 3, key, value))
EOF_FILE
put messages.py <<'EOF_FILE'
import numpy as np
import psycopg
from pgvector.psycopg import register_vector

rng = np.random.default_rng(17)
V = rng.standard_normal((5000, 384)).astype(np.float32)
V /= np.linalg.norm(V, axis=1, keepdims=True)
lang = ["pt" if i % 50 == 0 else "es" if i % 10 == 1 else "en" for i in range(5000)]

with psycopg.connect(autocommit=True) as conn:
    conn.execute("CREATE EXTENSION IF NOT EXISTS vector")
    register_vector(conn)
    conn.execute("CREATE TABLE messages (id int PRIMARY KEY, lang text, embedding vector(384))")
    with conn.cursor().copy("COPY messages FROM STDIN WITH (FORMAT BINARY)") as copy:
        copy.set_types(["int4", "text", "vector"])
        for i, v in enumerate(V):
            copy.write_row((i, lang[i], v))
    conn.execute("CREATE INDEX ON messages USING hnsw (embedding vector_cosine_ops)")
    conn.execute("ANALYZE messages")
EOF_FILE
put ten.sql <<'EOF_FILE'
SELECT q.id AS query_row,
       (SELECT count(*) FROM (SELECT m.id FROM messages m WHERE m.lang = 'pt'
                              ORDER BY m.embedding <=> q.embedding LIMIT 10) AS t) AS pt,
       (SELECT count(*) FROM (SELECT m.id FROM messages m WHERE m.lang = 'es'
                              ORDER BY m.embedding <=> q.embedding LIMIT 10) AS t) AS es
FROM messages q WHERE q.id BETWEEN 1 AND 8 ORDER BY q.id;
EOF_FILE
put prefilter_cost.py <<'EOF_FILE'
import timeit
import numpy as np

rng = np.random.default_rng(17)
N = 200_000
D = rng.standard_normal((N, 384), dtype=np.float32)
D /= np.linalg.norm(D, axis=1, keepdims=True)
row = np.arange(N)
lang = np.where(row % 100 == 0, "pt", np.where(row % 10 == 1, "es", "en"))
q = D[7]
def pre_filter(value, k=10):
    allowed = np.flatnonzero(lang == value)
    scores = D[allowed] @ q
    top = np.argpartition(-scores, k)[:k]
    return allowed[top[np.argsort(-scores[top])]]
for value in ("pt", "es", "en"):
    seconds = min(timeit.repeat(lambda: pre_filter(value), number=1, repeat=20))
    print(f"lang = {value!r}: {np.sum(lang == value):7,} rows searched  {seconds * 1000:6.1f} ms")
EOF_FILE
put chroma_filter.py <<'EOF_FILE'
import chromadb
from minilm import embed
from store import help, ids, D

client = chromadb.PersistentClient(path="chroma")
col = client.create_collection("help", configuration={"hnsw": {"space": "cosine"}})
col.add(ids=ids, embeddings=D,
        metadatas=[{"lang": h["lang"], "category": h["category"]} for h in help])
q = embed("how do I return a book")
r = col.query(query_embeddings=q, n_results=3, where={"lang": "pt"})
print(r["ids"][0])
r = col.query(query_embeddings=q, n_results=3,
              where={"$and": [{"lang": "en"}, {"category": "returns"}]})
print(r["ids"][0])
EOF_FILE
put lance_filter.py <<'EOF_FILE'
import lancedb
from minilm import embed
from store import help, D

db = lancedb.connect("lance")
table = db.create_table("help", [{"id": h["id"], "lang": h["lang"], "vector": v}
                                 for h, v in zip(help, D)])
q = embed("how do I return a book")[0]
for prefilter in (True, False):
    rows = (table.search(q).metric("cosine")
            .where("lang = 'pt'", prefilter=prefilter).limit(3).to_list())
    print(f"prefilter={prefilter}:", [r["id"] for r in rows])
EOF_FILE
put qdrant_filter.py <<'EOF_FILE'
from qdrant_client import QdrantClient, models
from minilm import embed
from store import help, D

client = QdrantClient(path="qdrant")
client.create_collection("help", vectors_config=models.VectorParams(
    size=384, distance=models.Distance.COSINE))
client.upsert("help", points=[
    models.PointStruct(id=i, vector=v.tolist(), payload={"article": h["id"], "lang": h["lang"]})
    for i, (h, v) in enumerate(zip(help, D))])
client.create_payload_index("help", "lang", models.PayloadSchemaType.KEYWORD)
only_pt = models.Filter(must=[models.FieldCondition(key="lang", match=models.MatchValue(value="pt"))])
hits = client.query_points("help", query=embed("how do I return a book")[0].tolist(),
                           query_filter=only_pt, limit=3)
print([p.payload["article"] for p in hits.points])
EOF_FILE
put shops.py <<'EOF_FILE'
import psycopg
from pgvector.psycopg import register_vector
from minilm import embed
from store import help, D

folio = [("f01", "Returning a book to Folio", "Post it back within 30 days with the slip from the parcel."),
         ("f02", "Folio delivery times", "Orders leave our shop in two working days."),
         ("f03", "Your Folio account", "Change your password from the account page.")]
F = embed([title + ". " + body for _, title, body in folio])
with psycopg.connect(autocommit=True) as conn:
    conn.execute("CREATE EXTENSION IF NOT EXISTS vector")
    register_vector(conn)
    conn.execute("""CREATE TABLE articles (id text PRIMARY KEY, shop text NOT NULL,
                    title text, embedding vector(384))""")
    for h, v in zip(help, D):
        conn.execute("INSERT INTO articles VALUES (%s, 'marginalia', %s, %s)", (h["id"], h["title"], v))
    for (id, title, _), v in zip(folio, F):
        conn.execute("INSERT INTO articles VALUES (%s, 'folio', %s, %s)", (id, title, v))
EOF_FILE
put policy.sql <<'EOF_FILE'
ALTER TABLE articles ENABLE ROW LEVEL SECURITY;
CREATE POLICY one_shop ON articles USING (shop = current_setting('app.shop'));
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'helpdesk') THEN
    CREATE ROLE helpdesk;
  END IF;
END $$;
GRANT SELECT ON articles TO helpdesk;
EOF_FILE
put tenant_search.py <<'EOF_FILE'
import sys
import psycopg
from pgvector.psycopg import register_vector
from minilm import embed

shop = sys.argv[1] if len(sys.argv) > 1 else None
with psycopg.connect() as conn:
    register_vector(conn)
    conn.execute("SET ROLE helpdesk")
    if shop:
        conn.execute("SELECT set_config('app.shop', %s, false)", (shop,))
    rows = conn.execute("""SELECT id, title FROM articles
                           ORDER BY embedding <=> %s LIMIT 3""",
                        (embed("how do I return a book")[0],)).fetchall()
    for id, title in rows:
        print(id, title)
EOF_FILE

block meta
on 'jq -r .lang data/help.jsonl | sort | uniq -c'
on 'jq -r .category data/help.jsonl | sort | uniq -c'

block filtered
on 'python filtered.py'

block messages
on 'python messages.py'
on 'psql -f ten.sql'

block explain
on 'psql -c "EXPLAIN (COSTS OFF) SELECT id FROM messages WHERE lang = '"'"'pt'"'"' ORDER BY embedding <=> (SELECT embedding FROM messages WHERE id = 1) LIMIT 10"'

block ef400
on 'psql -c "SET hnsw.ef_search = 400" -f ten.sql'

block partial
on 'psql -c "CREATE INDEX ON messages USING hnsw (embedding vector_cosine_ops) WHERE lang = '"'"'pt'"'"'"'
on 'psql -f ten.sql'

block cost
on 'python prefilter_cost.py'

block chroma
on 'python chroma_filter.py'

block lance
on 'python lance_filter.py'

block qdrant
on 'python qdrant_filter.py'

block shops
on 'python shops.py'
on 'psql -f policy.sql'
on 'python tenant_search.py marginalia'
on 'python tenant_search.py folio'
on 'python tenant_search.py'
