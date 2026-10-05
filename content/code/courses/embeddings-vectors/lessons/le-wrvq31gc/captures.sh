#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of embeddings-vectors, as a script
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
# factory.py's 20,000 vectors are not embeddings of 20,000 texts: they are
# noisy copies of the 310 all-MiniLM-L6-v2 vectors of the course's own texts,
# from a seeded generator, renormalised. The section says so.
#
# FAISS 1.15.1, LanceDB 0.39.0 and qdrant-client 1.19.1 are the versions
# pinned in lab.sh. Qdrant ran in the client's LOCAL MODE, a Python
# implementation inside the process; the Qdrant server was not run.
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

put flat.py <<'EOF_FILE'
import json
import faiss
from minilm import embed

help = [json.loads(line) for line in open("data/help.jsonl")]
ids = [h["id"] for h in help]
X = embed([h["title"] + ". " + h["body"] for h in help])
index = faiss.IndexFlatIP(384)
index.add(X)
print(index.ntotal, "vectors of", index.d, "dimensions")
D, I = index.search(embed("how do I get my money back"), 3)
print("positions:", I[0], " scores:", D[0].round(4))
print("articles: ", [ids[i] for i in I[0]])
EOF_FILE
put ids.py <<'EOF_FILE'
import json
import os
import faiss
import numpy as np
from minilm import embed

help = [json.loads(line) for line in open("data/help.jsonl")]
X = embed([h["title"] + ". " + h["body"] for h in help])
q = embed("how do I get my money back")
index = faiss.IndexIDMap(faiss.IndexFlatIP(384))
index.add_with_ids(X, np.array([int(h["id"][1:]) for h in help]))
print("ids:", index.search(q, 3)[1][0])
index.remove_ids(np.array([18]))
print("ids:", index.search(q, 3)[1][0], "of", index.ntotal)
faiss.write_index(index, "help.faiss")
again = faiss.read_index("help.faiss")
print(again.ntotal, "vectors read back,", os.path.getsize("help.faiss"), "bytes on disk")
EOF_FILE
put wrong.py <<'EOF_FILE'
import faiss
import numpy as np

index = faiss.IndexFlatIP(384)
try:
    index.add(np.zeros((1, 256), dtype="float32"))
except Exception as e:
    print(type(e).__name__, repr(str(e)))
EOF_FILE
put factory.py <<'EOF_FILE'
import json
import faiss
import numpy as np
from minilm import embed

texts = [json.loads(line)[k] for f, k in [("help", "body"), ("tickets", "text"),
         ("books", "blurb"), ("inbox", "text"), ("week2", "text")]
         for line in open(f"data/{f}.jsonl")]
base = embed(texts)
rng = np.random.default_rng(15)
def copies(n):
    v = base[rng.integers(len(base), size=n)] + rng.normal(scale=0.04, size=(n, 384))
    return (v / np.linalg.norm(v, axis=1, keepdims=True)).astype("float32")
X, Q = copies(20000), copies(100)
print(len(base), "real vectors,", len(X), "noisy copies,", len(Q), "queries")
exact = faiss.IndexFlatIP(384)
exact.add(X)
_, truth = exact.search(Q, 10)
faiss.write_index(exact, "random.faiss")
for spec in ("Flat", "HNSW32", "IVF64,Flat", "IVF64,PQ16"):
    index = faiss.index_factory(384, spec, faiss.METRIC_INNER_PRODUCT)
    needs = not index.is_trained
    index.train(X)
    index.add(X)
    _, I = index.search(Q, 10)
    recall = np.mean([len(set(a) & set(b)) / 10 for a, b in zip(I, truth)])
    size = faiss.serialize_index(index).nbytes
    print(f"{spec:11} needs training: {str(needs):5}  {size:>11,} bytes  recall@10 {recall:.3f}")
EOF_FILE
put mem.py <<'EOF_FILE'
import resource
import faiss

before = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
index = faiss.read_index("random.faiss")
after = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
print(index.ntotal, "vectors;", (after - before) // 1024, "MB more memory in this process")
EOF_FILE
put lance_load.py <<'EOF_FILE'
import json
import lancedb
from minilm import embed

help = [json.loads(line) for line in open("data/help.jsonl")]
X = embed([h["title"] + ". " + h["body"] for h in help])
db = lancedb.connect("lance")
table = db.create_table("help", data=[
    {"id": h["id"], "category": h["category"], "lang": h["lang"],
     "title": h["title"], "vector": v} for h, v in zip(help, X)])
print(table.count_rows(), "rows, version", table.version)
print(table.schema.field("vector"))
q = embed("how do I get my money back")[0]
for r in table.search(q).limit(3).to_list():
    print(f"{r['_distance']:.4f}  {r['id']}  {r['title']}")
for r in (table.search(q).distance_type("cosine")
          .where("category = 'ebooks'").limit(3).to_list()):
    print(f"{r['_distance']:.4f}  {r['id']}  {r['title']}")
EOF_FILE
put lance_versions.py <<'EOF_FILE'
import lancedb
from minilm import embed

table = lancedb.connect("lance").open_table("help")
table.add([{"id": "h41", "category": "payments", "lang": "en",
            "title": "Gift cards by email", "vector": embed("Gift cards by email")[0]}])
print("after add:   ", table.count_rows(), "rows, version", table.version)
table.delete("id = 'h41'")
print("after delete:", table.count_rows(), "rows, version", table.version)
for v in table.list_versions():
    m = v["metadata"]
    print("version", v["version"], ":", m["total_rows"], "rows in", m["total_data_files"], "data file(s)")
table.checkout(2)
print("checked out version 2:", table.count_rows(), "rows")
table.checkout_latest()
EOF_FILE
put qd.py <<'EOF_FILE'
import json
from qdrant_client import QdrantClient
from qdrant_client.models import (Distance, FieldCondition, Filter, MatchValue,
                                  PointStruct, VectorParams)
from minilm import embed

help = [json.loads(line) for line in open("data/help.jsonl")]
X = embed([h["title"] + ". " + h["body"] for h in help])
client = QdrantClient(path="qdrant")
client.create_collection("help", vectors_config=VectorParams(size=384, distance=Distance.COSINE))
client.upsert("help", points=[
    PointStruct(id=int(h["id"][1:]), vector=v.tolist(),
                payload={"article": h["id"], "category": h["category"], "title": h["title"]})
    for h, v in zip(help, X)])
print(client.count("help").count, "points")
q = embed("how do I get my money back")[0].tolist()
for p in client.query_points("help", query=q, limit=3).points:
    print(f"{p.score:.4f}  {p.id}  {p.payload['title']}")
ebooks = Filter(must=[FieldCondition(key="category", match=MatchValue(value="ebooks"))])
for p in client.query_points("help", query=q, query_filter=ebooks, limit=3).points:
    print(f"{p.score:.4f}  {p.id}  {p.payload['title']}")
EOF_FILE
put qd_local.py <<'EOF_FILE'
import warnings
from qdrant_client import QdrantClient
from qdrant_client.models import PayloadSchemaType, PointStruct

client = QdrantClient(path="qdrant")
try:
    client.upsert("help", points=[PointStruct(id="h15", vector=[0.0] * 384)])
except Exception as e:
    print(type(e).__name__ + ":", e)
try:
    client.query_points("help", query=[0.1] * 256, limit=3)
except Exception as e:
    print(type(e).__name__ + ":", e)
with warnings.catch_warnings(record=True) as said:
    warnings.simplefilter("always")
    client.create_payload_index("help", field_name="category",
                                field_schema=PayloadSchemaType.KEYWORD)
print("warning:", said[0].message)
print("indexed vectors:", client.get_collection("help").indexed_vectors_count)
EOF_FILE
put two.py <<'EOF_FILE'
import subprocess
from qdrant_client import QdrantClient

mine = QdrantClient(path="qdrant")
other = subprocess.run(
    ["python", "-c", "from qdrant_client import QdrantClient; QdrantClient(path='qdrant')"],
    capture_output=True, text=True)
print("second process:", other.stderr.strip().splitlines()[-1])
EOF_FILE

block flat
on 'python flat.py'

block ids
on 'python ids.py'

block wrong
on 'python wrong.py'

block factory
on 'python factory.py'

block mem
on 'ls -l random.faiss'
on 'python mem.py'

block lance
on 'python lance_load.py'

block versions
on 'python lance_versions.py'

block lance-files
on 'find lance -type f | sort'

block qdrant
on 'python qd.py'

block qdrant-local
on 'python qd_local.py'

block qdrant-files
on 'find qdrant -type f | sort'

block two
on 'python two.py'
