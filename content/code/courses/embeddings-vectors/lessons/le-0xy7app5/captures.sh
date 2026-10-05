#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of embeddings-vectors, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# The programs are the ones the sections show, written into ~/emb by `put`.
# Two things are STAGED and not shown:
#   - Chroma's default embedding function fetches all-MiniLM-L6-v2 from
#     Chroma's bucket into ~/.cache/chroma on first use. It is pointed at the
#     copy lab.sh fetched from that same bucket and checked against the same
#     SHA-256, so the capture needs no network.
#   - After `chroma run` is started in the background, the script waits until
#     its heartbeat answers, and stops it at the end.
#
# grow.py stores 1,040 random vectors from a seeded generator, not embeddings
# of any text: what it shows belongs to the files, not to the data.
#
# Chroma 1.5.9 is the version pinned in lab.sh. Pinecone and Weaviate are not
# here at all: their code in the lesson was not run (see the sections).
#
# Recorded on Ubuntu 24.04, Python 3.11, TZ=America/Sao_Paulo, 2026-10-05.
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
lab exec 'd=~/.cache/chroma/onnx_models/all-MiniLM-L6-v2; mkdir -p $d; [ -e $d/onnx ] || ln -s $MINILM_DIR $d/onnx'

put load.py <<'EOF_FILE'
import json
import chromadb

help = [json.loads(line) for line in open("data/help.jsonl")]
client = chromadb.PersistentClient(path="chroma")
col = client.create_collection("help", configuration={"hnsw": {"space": "cosine"}})
col.add(
    ids=[h["id"] for h in help],
    documents=[h["title"] + ". " + h["body"] for h in help],
    metadatas=[{"category": h["category"], "lang": h["lang"], "updated": h["updated"]}
               for h in help],
)
print(col.count(), "records in", col.name)
EOF_FILE
put same.py <<'EOF_FILE'
import chromadb
from minilm import embed

col = chromadb.PersistentClient(path="chroma").get_collection("help")
got = col.get(ids=["h15"], include=["documents", "embeddings"])
stored = got["embeddings"][0]
mine = embed(got["documents"][0])[0]
print(stored.shape, abs(stored - mine).max())
EOF_FILE
put ask.py <<'EOF_FILE'
import chromadb

col = chromadb.PersistentClient(path="chroma").get_collection("help")
question = "how do I get my money back"
r = col.query(query_texts=[question], n_results=3)
for i, d, doc in zip(r["ids"][0], r["distances"][0], r["documents"][0]):
    print(f"{d:.4f}  {i}  {doc[:44]}")
r = col.query(query_texts=[question], n_results=3,
              where={"category": {"$in": ["payments", "ebooks"]}})
print("payments or e-books:", r["ids"][0])
r = col.query(query_texts=[question], n_results=3,
              where_document={"$contains": "card"})
print("text says card:     ", r["ids"][0])
EOF_FILE
put dims.py <<'EOF_FILE'
import chromadb
from wordllama import WordLlama

col = chromadb.PersistentClient(path="chroma").get_collection("help")
v = WordLlama.load().embed(["how do I get my money back"], norm=True)
try:
    col.query(query_embeddings=v, n_results=3)
except Exception as e:
    print(type(e).__name__ + ":", e)
EOF_FILE
put change.py <<'EOF_FILE'
import chromadb

col = chromadb.PersistentClient(path="chroma").get_collection("help")
meta = {"category": "payments", "lang": "en", "updated": "2026-10-05"}
show = lambda: print(col.count(), col.get(ids=["h41"])["documents"])
col.add(ids=["h41"], documents=["Gift cards by email."], metadatas=[meta])
show()
col.add(ids=["h41"], documents=["Gift cards by post."], metadatas=[meta])
show()
col.upsert(ids=["h41"], documents=["Gift cards by email or by post."], metadatas=[meta])
show()
col.update(ids=["h99"], documents=["An article nobody wrote."])
col.delete(ids=["h41"])
show()
EOF_FILE
put distances.py <<'EOF_FILE'
import chromadb
from minilm import embed

client = chromadb.PersistentClient(path="chroma")
cos = client.get_collection("help")
everything = cos.get(include=["documents", "embeddings"])
l2 = client.create_collection("help_l2")
ip = client.create_collection("help_ip", configuration={"hnsw": {"space": "ip"}})
for c in (l2, ip):
    c.add(ids=everything["ids"], embeddings=everything["embeddings"],
          documents=everything["documents"])
    print(c.name, "space:", c.configuration["hnsw"]["space"])
q = embed("how do I get my money back")[0]
for c in (cos, ip, l2):
    r = c.query(query_embeddings=[q], n_results=3)
    print(f"{c.name:8}", "  ".join(f"{i} {d:.4f}" for i, d in zip(r["ids"][0], r["distances"][0])))
vec = dict(zip(everything["ids"], everything["embeddings"]))
print(f"{'dot':8}", "  ".join(f"{i} {float(vec[i] @ q):.4f}" for i in r["ids"][0]))
EOF_FILE
put space.py <<'EOF_FILE'
import chromadb

col = chromadb.PersistentClient(path="chroma").get_collection("help")
try:
    col.modify(configuration={"hnsw": {"space": "l2"}})
except Exception as e:
    print(type(e).__name__ + ":", e)
EOF_FILE
put inside.py <<'EOF_FILE'
import sqlite3

db = sqlite3.connect("chroma/chroma.sqlite3")
for table in ("embeddings", "embedding_metadata", "embedding_fulltext_search",
              "embeddings_queue"):
    print(f"{table:26}", db.execute(f"SELECT count(*) FROM {table}").fetchone()[0])
rows = db.execute("SELECT key, string_value FROM embedding_metadata m "
                  "JOIN embeddings e ON e.id = m.id WHERE e.embedding_id = 'h15'")
for key, value in rows:
    print(f"  {key:16} {value[:50]}")
vector = db.execute("SELECT vector FROM embeddings_queue WHERE id = 'h15'").fetchone()[0]
print("queued vector:", len(vector), "bytes")
ops = {0: "add", 1: "update", 2: "upsert", 3: "delete"}
rows = db.execute("SELECT seq_id, operation, id FROM embeddings_queue "
                  "ORDER BY seq_id DESC LIMIT 5")
print("last five writes:", [(seq, ops[op], i) for seq, op, i in rows][::-1])
EOF_FILE
put remote.py <<'EOF_FILE'
import chromadb

client = chromadb.HttpClient(host="localhost", port=8012)
col = client.get_collection("help")
r = col.query(query_texts=["how do I get my money back"], n_results=3)
print(col.count(), r["ids"][0], [round(d, 4) for d in r["distances"][0]])
EOF_FILE
put grow.py <<'EOF_FILE'
import glob
import os
import chromadb
import numpy as np

col = chromadb.PersistentClient(path="grow").create_collection(
    "random", configuration={"hnsw": {"space": "cosine"}})
print("sync_threshold:", col.configuration["hnsw"]["sync_threshold"])
rng = np.random.default_rng(12)
for n in (40, 900, 100):
    start = col.count()
    col.add(ids=[f"r{start + i}" for i in range(n)],
            embeddings=rng.normal(size=(n, 384)).astype("float32"))
    size = os.path.getsize(glob.glob("grow/*/data_level0.bin")[0])
    print(f"{col.count():5} records   data_level0.bin {size:>9,} bytes")
EOF_FILE

block load
on 'python load.py'

block same
on 'python same.py'

block ask
on 'python ask.py'

block dims
on 'python dims.py'

block change
on 'python change.py'

block disk
on 'ls -l chroma chroma/*/'
on 'du -sh chroma'

block inside
on 'python inside.py'

block grow
on 'python grow.py'

block distances
on 'python distances.py'

block space
on 'python space.py'

block server
on 'chroma run --path chroma --port 8012 > chroma.log 2>&1 &'
lab exec 'for i in $(seq 100); do curl -s -o /dev/null localhost:8012/api/v2/heartbeat && break; sleep 0.2; done'
on 'curl -s localhost:8012/api/v2/heartbeat; echo'
on 'python remote.py'
fuser -k 8012/tcp >/dev/null 2>&1 || true
