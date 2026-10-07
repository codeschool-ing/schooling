#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of embeddings-vectors, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# The programs are the ones the sections show, written into ~/emb by `put`.
# One file is STAGED and not shown: prices.py, copied into ~/emb from beside
# course.json so that compare.py can import it.
#
# Every request goes to labembed on 127.0.0.1:8500, the lab's stand-in for
# Google's and Cohere's endpoints, through the real google-genai 2.28.0 and
# cohere 7.2.0 SDKs. Its vectors come from all-MiniLM-L6-v2 and WordLlama, run
# on this machine; it ignores task types and input types, and its int8 and
# binary encodings are its own arithmetic (labembed.py, which lesson 7 shows, says how). No
# request reached Google or Cohere.
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

put gemini.py <<'EOF_FILE'
import os
import numpy as np
from google import genai
from google.genai import types

client = genai.Client(
    api_key=os.environ["GEMINI_API_KEY"],
    http_options=types.HttpOptions(base_url=os.environ["GEMINI_BASE_URL"]),
)
r = client.models.embed_content(model="lab-minilm", contents="When your refund arrives")
v = np.array(r.embeddings[0].values, dtype=np.float32)
print(len(r.embeddings), v.shape)
titles = ["Tracking a parcel", "Payment methods we accept", "Audiobooks"]
r = client.models.embed_content(
    model="lab-wordllama",
    contents=titles,
    config=types.EmbedContentConfig(
        task_type="RETRIEVAL_DOCUMENT",
        output_dimensionality=128,
    ),
)
V = np.array([e.values for e in r.embeddings], dtype=np.float32)
print(V.shape, np.linalg.norm(V, axis=1).round(4))
V = V / np.linalg.norm(V, axis=1, keepdims=True)
EOF_FILE
put gemini_errors.py <<'EOF_FILE'
import os
from google import genai
from google.genai import errors, types

client = genai.Client(
    api_key=os.environ["GEMINI_API_KEY"],
    http_options=types.HttpOptions(base_url=os.environ["GEMINI_BASE_URL"]),
)
tries = [
    ("gemini-embedding-001", None),
    ("lab-minilm", types.EmbedContentConfig(output_dimensionality=128)),
    ("lab-minilm", types.EmbedContentConfig(task_type="SEARCH_QUERY")),
]
for model, config in tries:
    try:
        client.models.embed_content(model=model, contents="Audiobooks", config=config)
    except errors.ClientError as e:
        print(e.code, e.status, "|", e.message)
EOF_FILE
put tasks.py <<'EOF_FILE'
import os
import numpy as np
from google import genai
from google.genai import types

client = genai.Client(
    api_key=os.environ["GEMINI_API_KEY"],
    http_options=types.HttpOptions(base_url=os.environ["GEMINI_BASE_URL"]),
)
text = "can I pay in three parts"
def as_task(task):
    r = client.models.embed_content(
        model="lab-minilm", contents=text,
        config=types.EmbedContentConfig(task_type=task),
    )
    return np.array(r.embeddings[0].values, dtype=np.float32)
q = as_task("RETRIEVAL_QUERY")
for task in ["RETRIEVAL_DOCUMENT", "SEMANTIC_SIMILARITY", "CLASSIFICATION"]:
    d = as_task(task)
    print(f"{task:20} max difference from RETRIEVAL_QUERY: {np.abs(q - d).max()}")
EOF_FILE
put cohere_embed.py <<'EOF_FILE'
import json
import os
import cohere

co = cohere.ClientV2(api_key=os.environ["CO_API_KEY"], base_url=os.environ["CO_API_URL"])
help = [json.loads(line) for line in open("data/help.jsonl")]
r = co.embed(
    model="lab-minilm",
    texts=[h["title"] + ". " + h["body"] for h in help],
    input_type="search_document",
    embedding_types=["float"],
)
print(len(r.embeddings.float_), len(r.embeddings.float_[0]))
print("billed:", int(r.meta.billed_units.input_tokens), "tokens")
def embed_all(texts, input_type, size=96):
    out = []
    for i in range(0, len(texts), size):
        r = co.embed(model="lab-minilm", texts=texts[i:i + size],
                     input_type=input_type, embedding_types=["float"])
        out += r.embeddings.float_
        print(f"  call {i // size + 1}: {len(texts[i:i + size])} texts")
    return out
tickets = [json.loads(line)["text"] for line in open("data/tickets.jsonl")]
vectors = embed_all(tickets, "classification")
print(len(vectors), "vectors")
EOF_FILE
put cohere_errors.py <<'EOF_FILE'
import os
import cohere

co = cohere.ClientV2(api_key=os.environ["CO_API_KEY"], base_url=os.environ["CO_API_URL"])
try:
    co.embed(model="lab-minilm", texts=["Audiobooks"])
except TypeError as e:
    print("TypeError:", e)
try:
    co.embed(model="lab-minilm", texts=["Audiobooks"] * 97, input_type="search_document")
except cohere.errors.BadRequestError as e:
    print(e.status_code, e.body)
EOF_FILE
put no-type.json <<'EOF_FILE'
{"model": "lab-minilm", "texts": ["Audiobooks"]}
EOF_FILE
put search.py <<'EOF_FILE'
import json
import os
import numpy as np
import cohere

co = cohere.ClientV2(api_key=os.environ["CO_API_KEY"], base_url=os.environ["CO_API_URL"])
help = [json.loads(line) for line in open("data/help.jsonl")]
queries = [json.loads(line) for line in open("data/queries.jsonl")]
ids = [h["id"] for h in help]
def embed(texts, input_type):
    r = co.embed(model="lab-minilm", texts=texts, input_type=input_type,
                 embedding_types=["float"])
    return np.array(r.embeddings.float_, dtype=np.float32)
def found(D, Q, k):
    hits = 0
    for q, row in zip(queries, Q @ D.T):
        top = [ids[j] for j in np.argsort(-row)[:k]]
        hits += any(t in q["relevant"] for t in top)
    return hits
D = embed([h["title"] + ". " + h["body"] for h in help], "search_document")
for qtype in ["search_query", "search_document", "clustering"]:
    Q = embed([q["text"] for q in queries], qtype)
    print(f"queries as {qtype:16} top 1: {found(D, Q, 1)}/24  top 3: {found(D, Q, 3)}/24")
EOF_FILE
put quantised.py <<'EOF_FILE'
import json
import os
import numpy as np
import cohere

co = cohere.ClientV2(api_key=os.environ["CO_API_KEY"], base_url=os.environ["CO_API_URL"])
help = [json.loads(line) for line in open("data/help.jsonl")]
queries = [json.loads(line) for line in open("data/queries.jsonl")]
ids = [h["id"] for h in help]
KINDS = {"float": np.float32, "int8": np.int8, "ubinary": np.uint8}
def embed(model, texts, input_type):
    r = co.embed(model=model, texts=texts, input_type=input_type,
                 embedding_types=list(KINDS))
    e = r.embeddings
    return {"float": np.array(e.float_, dtype=np.float32),
            "int8": np.array(e.int8, dtype=np.int8),
            "ubinary": np.array(e.ubinary, dtype=np.uint8)}
def scores(kind, Q, D):
    if kind == "ubinary":
        q, d = np.unpackbits(Q, axis=1), np.unpackbits(D, axis=1)
        return -(q[:, None, :] != d[None, :, :]).sum(axis=2)
    if kind == "int8":
        return Q.astype(np.int32) @ D.astype(np.int32).T
    return Q @ D.T
print(f"{'model':14} {'type':8} {'bytes':>5}  top 1  top 3  tied at 1")
for model in ["lab-minilm", "lab-wordllama"]:
    D = embed(model, [h["title"] + ". " + h["body"] for h in help], "search_document")
    Q = embed(model, [q["text"] for q in queries], "search_query")
    for kind in KINDS:
        S = scores(kind, Q[kind], D[kind])
        top = np.argsort(-S, axis=1, kind="stable")[:, :3]
        one = sum(ids[t[0]] in q["relevant"] for t, q in zip(top, queries))
        three = sum(any(ids[j] in q["relevant"] for j in t) for t, q in zip(top, queries))
        ties = sum(int(row[t[0]] == row[t[1]]) for row, t in zip(S, top))
        print(f"{model:14} {kind:8} {D[kind][0].nbytes:5}  {one:5}  {three:5}  {ties:9}")
EOF_FILE
put compare.py <<'EOF_FILE'
from prices import rows

TOKENS = 1_000_000 * 500
print(f"{'model':28} {'USD/MTok':>8} {'dims':>5} {'max in':>7} {'bytes':>6} {'500M tokens':>12} {'1M vecs GB':>10}")
for r in rows():
    if r["provider"] not in ("openai", "gemini", "cohere"):
        continue
    dims = r["dims"] or "-"
    size = r["dims"] * 4 if r["dims"] else "-"
    gb = f"{r['dims'] * 4 * 1e6 / 1e9:.2f}" if r["dims"] else "-"
    cost = TOKENS / 1e6 * r["usd_per_mtok"]
    print(f"{r['model']:28} {r['usd_per_mtok']:8.3f} {dims:>5} {r['max_input_tokens']:>7} {size:>6} {cost:12.2f} {gb:>10}")
EOF_FILE

block gemini
on 'python gemini.py'
on "jq -c '{path, inputs, dims, task_type}' labembed.jsonl"

block gemini-errors
on 'python gemini_errors.py'

block tasks
on 'python tasks.py'
on "jq -c '{inputs, task_type}' labembed.jsonl | tail -n 4"

block cohere
on 'python cohere_embed.py'

block cohere-errors
on 'python cohere_errors.py'

block cohere-curl
on 'cat no-type.json'
on 'curl -s -w " %{http_code}\n" -H "authorization: Bearer $CO_API_KEY" -H "content-type: application/json" -d @no-type.json $CO_API_URL/v2/embed'

block search
on 'python search.py'

block quantised
on 'python quantised.py'

block prices
on 'python3 prices.py'

block compare
on 'python compare.py'
