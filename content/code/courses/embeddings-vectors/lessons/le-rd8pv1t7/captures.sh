#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of embeddings-vectors, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# The programs and SQL files are the ones the sections show, written into ~/emb
# by `put`. Nothing is staged: every table in the database `shop` is created by
# a command below. The table `noise` holds 20,000 random unit vectors of 384
# dimensions, drawn by NumPy with seed 14, with no text behind them; it exists
# only to make a table big enough for the planner to want an index.
#
# Supabase and MongoDB Atlas are hosted services this machine cannot reach, so
# supabase_search.py, atlas_setup.py and atlas_search.py are shown in the
# lesson and are NOT run here. match.sql, the SQL function the Supabase section
# calls, is plain PostgreSQL and is run below.
#
# Every vector comes from all-MiniLM-L6-v2 or WordLlama, run on this machine,
# and is stored by pgvector 0.6.0 in PostgreSQL 16; lab.sh says where each
# came from.
#
# Recorded on Ubuntu 24.04, Python 3.11, PostgreSQL 16, pgvector 0.6.0,
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

put schema.sql <<'EOF_FILE'
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE articles (
    id        text PRIMARY KEY,
    category  text NOT NULL,
    lang      text NOT NULL,
    title     text NOT NULL,
    body      text NOT NULL,
    embedding vector(384) NOT NULL
);

CREATE TABLE queries (
    id        text PRIMARY KEY,
    text      text NOT NULL,
    relevant  text[] NOT NULL,
    embedding vector(384) NOT NULL
);
EOF_FILE
put load.py <<'EOF_FILE'
import json
import psycopg
from pgvector.psycopg import register_vector
from minilm import embed

help = [json.loads(line) for line in open("data/help.jsonl")]
queries = [json.loads(line) for line in open("data/queries.jsonl")]
A = embed([h["title"] + ". " + h["body"] for h in help])
Q = embed([q["text"] for q in queries])
with psycopg.connect() as conn:
    register_vector(conn)
    cur = conn.cursor()
    cur.executemany(
        "INSERT INTO articles (id, category, lang, title, body, embedding)"
        " VALUES (%s, %s, %s, %s, %s, %s)",
        [(h["id"], h["category"], h["lang"], h["title"], h["body"], v)
         for h, v in zip(help, A)])
    cur.executemany(
        "INSERT INTO queries (id, text, relevant, embedding) VALUES (%s, %s, %s, %s)",
        [(q["id"], q["text"], q["relevant"], v) for q, v in zip(queries, Q)])
print(len(help), "articles and", len(queries), "queries written")
EOF_FILE
put search.py <<'EOF_FILE'
import sys
import psycopg
from pgvector.psycopg import register_vector
from minilm import embed

q = embed(sys.argv[1])[0]
with psycopg.connect() as conn:
    register_vector(conn)
    rows = conn.execute(
        "SELECT id, title, embedding <=> %(q)s AS distance FROM articles"
        " ORDER BY embedding <=> %(q)s LIMIT 3", {"q": q}).fetchall()
for id, title, distance in rows:
    print(f"{distance:.3f}  {1 - distance:.3f}  {id}  {title}")
EOF_FILE
put ops.sql <<'EOF_FILE'
SELECT a.id,
       a.embedding <-> q.embedding AS l2,
       a.embedding <=> q.embedding AS cosine_distance,
       a.embedding <#> q.embedding AS negative_inner_product
FROM articles a, queries q
WHERE q.id = 'q01'
ORDER BY a.embedding <=> q.embedding
LIMIT 3;
EOF_FILE
put recall.sql <<'EOF_FILE'
SELECT q.id, q.text, top.id AS first, q.relevant
FROM queries q
CROSS JOIN LATERAL (
    SELECT a.id FROM articles a
    ORDER BY a.embedding <=> q.embedding
    LIMIT 1
) AS top
WHERE NOT top.id = ANY (q.relevant)
ORDER BY q.id;
EOF_FILE
put noise.py <<'EOF_FILE'
import numpy as np
import psycopg
from pgvector.psycopg import register_vector

rng = np.random.default_rng(14)
X = rng.standard_normal((20000, 384)).astype(np.float32)
X /= np.linalg.norm(X, axis=1, keepdims=True)
with psycopg.connect() as conn:
    conn.execute("CREATE TABLE noise (id integer PRIMARY KEY, embedding vector(384) NOT NULL)")
    register_vector(conn)
    cur = conn.cursor()
    with cur.copy("COPY noise (id, embedding) FROM STDIN WITH (FORMAT BINARY)") as copy:
        copy.set_types(["integer", "vector"])
        for i, v in enumerate(X):
            copy.write_row((i, v))
    print(conn.execute("SELECT count(*) FROM noise").fetchone()[0], "rows in noise")
EOF_FILE
put before.sql <<'EOF_FILE'
EXPLAIN (ANALYZE, COSTS OFF)
SELECT id FROM noise
ORDER BY embedding <=> (SELECT embedding FROM noise WHERE id = 7)
LIMIT 3;
EOF_FILE
put after.sql <<'EOF_FILE'
\timing on
CREATE INDEX ON noise USING hnsw (embedding vector_cosine_ops);
\timing off
EXPLAIN (ANALYZE, COSTS OFF)
SELECT id FROM noise
ORDER BY embedding <=> (SELECT embedding FROM noise WHERE id = 7)
LIMIT 3;
EOF_FILE
put unused.sql <<'EOF_FILE'
EXPLAIN (COSTS OFF)
SELECT id FROM noise
ORDER BY embedding <-> (SELECT embedding FROM noise WHERE id = 7)
LIMIT 3;

EXPLAIN (COSTS OFF)
SELECT id FROM noise
ORDER BY 1 - (embedding <=> (SELECT embedding FROM noise WHERE id = 7)) DESC
LIMIT 3;
EOF_FILE
put match.sql <<'EOF_FILE'
CREATE FUNCTION match_articles(
    query_embedding vector(384),
    match_threshold float,
    match_count int
)
RETURNS TABLE (id text, title text, similarity float)
LANGUAGE sql STABLE
AS $$
    SELECT a.id, a.title, 1 - (a.embedding <=> query_embedding)
    FROM articles a
    WHERE a.embedding <=> query_embedding < 1 - match_threshold
    ORDER BY a.embedding <=> query_embedding
    LIMIT match_count;
$$;

SELECT * FROM match_articles(
    (SELECT embedding FROM queries WHERE id = 'q01'), 0.4, 3);
EOF_FILE
put edit.py <<'EOF_FILE'
import psycopg
from pgvector.psycopg import register_vector
from wordllama import WordLlama

body = "We refund within two working days of the return reaching our warehouse."
wl = WordLlama.load()
try:
    with psycopg.connect() as conn:
        register_vector(conn)
        conn.execute("UPDATE articles SET body = %s WHERE id = 'h15'", (body,))
        v = wl.embed(["When your refund arrives. " + body], norm=True)[0]
        conn.execute("UPDATE articles SET embedding = %s WHERE id = 'h15'", (v,))
except psycopg.Error as e:
    print(type(e).__name__ + ":", e)
with psycopg.connect() as conn:
    print(conn.execute("SELECT left(body, 49) FROM articles WHERE id = 'h15'").fetchone()[0])
EOF_FILE

block schema
on 'psql -f schema.sql'
on 'psql -c "SELECT extversion FROM pg_extension WHERE extname = '"'"'vector'"'"'"'
on 'psql -c "\d articles"'

block load
on 'python load.py'
on 'psql -c "SELECT id, vector_dims(embedding) AS dims, round(vector_norm(embedding)::numeric, 4) AS length, pg_column_size(embedding) AS bytes FROM articles LIMIT 3"'

block wrongdims
on 'psql -c "INSERT INTO queries VALUES ('"'"'q99'"'"', '"'"'test'"'"', '"'"'{}'"'"', '"'"'[0.1,0.2,0.3]'"'"')"'

block ops
on 'psql -f ops.sql'

block search
on 'python search.py "how do I get my money back"'

block recall
on 'psql -f recall.sql'

block small
on 'psql -c "CREATE INDEX ON articles USING hnsw (embedding vector_cosine_ops)"'
on 'psql -c "EXPLAIN (COSTS OFF) SELECT id FROM articles ORDER BY embedding <=> (SELECT embedding FROM queries WHERE id = '"'"'q01'"'"') LIMIT 3"'

block noise
on 'python noise.py'

block before
on 'psql -e -f before.sql'

block after
on 'psql -e -f after.sql'

block unused
on 'psql -e -f unused.sql'

block ivfflat
on 'psql -c "CREATE INDEX ON articles USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100)"'
on 'python search.py "how do I get my money back"'

block probes
on 'psql -c "SELECT count(*) AS returned FROM (SELECT id FROM articles ORDER BY embedding <=> (SELECT embedding FROM queries WHERE id = '"'"'q01'"'"') LIMIT 3) AS top" -c "SHOW ivfflat.probes"'

block ivfplan
on 'psql -c "\d articles"'
on 'psql -c "EXPLAIN (COSTS OFF) SELECT id FROM articles ORDER BY embedding <=> (SELECT embedding FROM queries WHERE id = '"'"'q01'"'"') LIMIT 3"'

block dropivf
on 'psql -c "DROP INDEX articles_embedding_idx1"'
on 'python search.py "how do I get my money back"'

block match
on 'psql -f match.sql'

block matchdims
on 'psql -c "SELECT * FROM match_articles(array_fill(0.1::real, ARRAY[256])::vector, 0.4, 3)"'

block edit
on 'python edit.py'
