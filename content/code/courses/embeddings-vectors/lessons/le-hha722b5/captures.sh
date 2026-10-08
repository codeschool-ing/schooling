#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of embeddings-vectors, as a script
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
# course.json so that ana can run it.
#
# Every request goes to labembed on 127.0.0.1:8500, the lab's stand-in for
# OpenAI's embeddings endpoint, through the real openai 3.24.0 SDK, which
# finds it through OPENAI_BASE_URL in /etc/emb.env. Its vectors come from
# all-MiniLM-L6-v2 and WordLlama, run on this machine; its token counts come
# from those models' own tokenisers. The 429s in "errors-and-retries" are the
# lab's, switched on through its /lab/config route. No request reached OpenAI.
# Prices come from LiteLLM's sheet at commit b9e71e990aed, through prices.py.
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

put request.json <<'EOF_FILE'
{"model": "lab-minilm", "input": "When your refund arrives"}
EOF_FILE
put request-b64.json <<'EOF_FILE'
{"model": "lab-minilm", "input": "When your refund arrives", "encoding_format": "base64"}
EOF_FILE
put first.py <<'EOF_FILE'
from openai import OpenAI

client = OpenAI()
response = client.embeddings.create(
    model="lab-minilm",
    input="When your refund arrives",
)
vector = response.data[0].embedding
print(type(vector).__name__, len(vector), [round(x, 4) for x in vector[:4]])
print(response.usage)
EOF_FILE
put refused.py <<'EOF_FILE'
import openai
from openai import OpenAI

attempts = [
    (OpenAI(api_key="sk-not-the-lab-key"), "lab-minilm"),
    (OpenAI(), "text-embedding-3-small"),
]
for client, model in attempts:
    try:
        client.embeddings.create(model=model, input="When your refund arrives")
    except openai.APIStatusError as e:
        print(type(e).__name__, e.status_code, e.code)
        print("   ", e.body["message"])
EOF_FILE
put response.py <<'EOF_FILE'
import base64
import numpy as np
from openai import OpenAI

client = OpenAI()
texts = ["When your refund arrives", "Tracking a parcel", "Two-step sign-in"]
r = client.embeddings.create(model="lab-minilm", input=texts)
print(r.object, r.model, r.usage)
for d in r.data:
    print(" ", d.object, d.index, len(d.embedding), texts[d.index])
raw = client.embeddings.with_raw_response.create(model="lab-minilm", input=texts[0])
print(raw.http_request.content.decode())
wire = raw.http_response.json()["data"][0]["embedding"]
print(wire[:40], "...", len(wire), "characters")
v = np.frombuffer(base64.b64decode(wire), dtype="<f4")
print(v.shape, v.dtype, "largest difference from the SDK's list:",
      np.abs(v - raw.parse().data[0].embedding).max())
EOF_FILE
put batch.py <<'EOF_FILE'
import json
import tiktoken
from openai import OpenAI

client = OpenAI()
help = [json.loads(l) for l in open("data/help.jsonl")]
texts = [h["title"] + ". " + h["body"] for h in help]
enc = tiktoken.get_encoding("cl100k_base")
counts = [len(enc.encode(t)) for t in texts]
print("cl100k_base tokens:", sum(counts), " longest article:", max(counts))
def embed_all(texts, size=16):
    vectors = []
    for start in range(0, len(texts), size):
        r = client.embeddings.create(model="lab-minilm", input=texts[start:start + size])
        vectors += [d.embedding for d in sorted(r.data, key=lambda d: d.index)]
    return vectors
vectors = embed_all(texts)
print(len(vectors), "vectors from", len(texts), "articles")
EOF_FILE
put limits.py <<'EOF_FILE'
import openai
from openai import OpenAI

client = OpenAI()
tries = [
    ("an empty string", ["Tracking a parcel", ""]),
    ("2,049 inputs", ["Tracking a parcel"] * 2049),
]
for name, batch in tries:
    try:
        client.embeddings.create(model="lab-minilm", input=batch)
    except openai.BadRequestError as e:
        print(f"{name}: {e.status_code} {e.body['message']}")
EOF_FILE
put dims.py <<'EOF_FILE'
import json
import numpy as np
import openai
from openai import OpenAI

client = OpenAI()
help = [json.loads(l) for l in open("data/help.jsonl")]
queries = [json.loads(l) for l in open("data/queries.jsonl")]
ids = [h["id"] for h in help]
docs = [h["title"] + ". " + h["body"] for h in help]
asks = [q["text"] for q in queries]


def embed(texts, **kw):
    r = client.embeddings.create(model="lab-wordllama", input=texts, **kw)
    return np.array([d.embedding for d in r.data], dtype=np.float32)


def recall(D, Q):
    top = np.argsort(-(Q @ D.T), axis=1)[:, :3]
    at1 = sum(ids[t[0]] in q["relevant"] for t, q in zip(top, queries))
    at3 = sum(any(ids[i] in q["relevant"] for i in t) for t, q in zip(top, queries))
    return f"recall@1 {at1}/{len(queries)}  recall@3 {at3}/{len(queries)}"
for dims in (256, 128, 64):
    D, Q = embed(docs, dimensions=dims), embed(asks, dimensions=dims)
    print(f"dimensions={dims:<3}  {D[0].nbytes:4} bytes a vector  {recall(D, Q)}")
D, Q = embed(docs)[:, :64], embed(asks)[:, :64]
lengths = np.linalg.norm(D, axis=1)
print(f"cut to 64 by hand: lengths {lengths.min():.2f} to {lengths.max():.2f}  {recall(D, Q)}")
D /= np.linalg.norm(D, axis=1, keepdims=True)
Q /= np.linalg.norm(Q, axis=1, keepdims=True)
print(f"cut, then renormalised:           {recall(D, Q)}")
try:
    client.embeddings.create(model="lab-minilm", input="Tracking a parcel", dimensions=128)
except openai.BadRequestError as e:
    print("lab-minilm, dimensions=128:", e.status_code, e.body["message"])
EOF_FILE
put cost.py <<'EOF_FILE'
import json
import tiktoken

enc = tiktoken.get_encoding("cl100k_base")
help = [json.loads(l) for l in open("data/help.jsonl")]
tokens = sum(len(enc.encode(h["title"] + ". " + h["body"])) for h in help)
prices = {p["model"]: p for p in json.load(open("prices.json"))}
print("help centre:", tokens, "tokens")
for name in ("text-embedding-3-small", "text-embedding-3-large", "text-embedding-ada-002"):
    p = prices[name]
    batch = p["batch_usd_per_mtok"]
    print(f"{name:23}  help centre ${tokens * p['usd_per_mtok'] / 1e6:.6f}"
          f"  a million 500-token documents ${500 * p['usd_per_mtok']:,.2f}"
          + (f" (batch ${500 * batch:,.2f})" if batch else ""))
EOF_FILE
put retry.py <<'EOF_FILE'
import time
import httpx
import openai
from openai import OpenAI

client = OpenAI()
print("max_retries", client.max_retries, " timeout", client.timeout)


def fail_next(n):  # the lab's switch, not OpenAI's
    httpx.post("http://127.0.0.1:8500/lab/config", json={"fail": n, "status": 429})
fail_next(2)
start = time.monotonic()
r = client.embeddings.create(model="lab-minilm", input="When your refund arrives")
print(f"answered after {time.monotonic() - start:.1f} s with {len(r.data[0].embedding)} numbers")
fail_next(3)
start = time.monotonic()
try:
    client.embeddings.create(model="lab-minilm", input="When your refund arrives")
except openai.RateLimitError as e:
    print(f"gave up after {time.monotonic() - start:.1f} s:", type(e).__name__, e.status_code)
try:
    client.embeddings.create(model="lab-minilm", input="")
except openai.BadRequestError as e:
    print("not retried:", type(e).__name__, e.status_code)
EOF_FILE

block env
on 'env | grep ^OPENAI'

block first
on 'python first.py'
on 'tail -n 1 labembed.jsonl'

block curl
on 'curl -s $OPENAI_BASE_URL/embeddings -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" -d @request.json | cut -c 1-150'

block refused
on 'python refused.py'

block response
on 'python response.py'

block wire
on 'curl -s $OPENAI_BASE_URL/embeddings -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" -d @request.json | wc -c'
on 'curl -s $OPENAI_BASE_URL/embeddings -H "Authorization: Bearer $OPENAI_API_KEY" -H "Content-Type: application/json" -d @request-b64.json | wc -c'

block batch
on 'python batch.py'
on "jq -c '{inputs, tokens, encoding_format}' labembed.jsonl | tail -n 3"

block limits
on 'python limits.py'

block dims
on 'python dims.py'

block prices
on 'python3 prices.py'

block cost
on 'python3 prices.py --json > prices.json'
on 'python cost.py'

block retry
on 'python retry.py'
on "jq -c '{at, status}' labembed.jsonl | tail -n 7"
