#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of embeddings-vectors, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# The programs are the ones the sections show, written into ~/emb by `put`.
# One file is STAGED and not shown: prices.py, the course's price sheet, is
# copied from beside course.json into ~/emb so that sheet.py can import it.
# It reads LiteLLM's sheet at the pinned commit from ~/.cache/emb-prices.
#
# jina.py talks to labembed, the lab's stand-in provider on 127.0.0.1:8500,
# with the lab's Jina key; no request leaves the machine. Every vector comes
# from all-MiniLM-L6-v2 or WordLlama, run on this machine; lab.sh says where
# each was fetched from. The timings in speed.py are this machine's, measured
# while other programs may have been running.
#
# Recorded on Ubuntu 24.04, Python 3.11, TZ=America/Sao_Paulo, 2026-10-05.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB_SH=${LAB_SH:-../../lab.sh}
COURSE=$(cd "$(dirname "$LAB_SH")" && pwd)
lab() { bash "$LAB_SH" "$@"; }
# on 'command': what ana typed in ~/emb, and what it printed.
on() { printf 'ana@lab:~/emb$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
# put PATH: a file ana wrote in ~/emb, from stdin. Its content is shown in the lesson.
put() { lab exec "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"; }
block() { printf '##### %s\n' "$1"; }
# One capture at a time: every run rebuilds ~/emb from nothing.
exec 9>/var/tmp/emb-capture.lock; flock 9
lab reset >/dev/null

put jina.py <<'EOF_FILE'
import os
import httpx

url = os.environ["JINA_BASE_URL"] + "/embeddings"
headers = {"Authorization": "Bearer " + os.environ["JINA_API_KEY"]}

def jina(texts, task, dimensions=None):
    body = {"model": "lab-wordllama", "task": task, "input": texts}
    if dimensions:
        body["dimensions"] = dimensions
    return httpx.post(url, headers=headers, json=body)
r = jina(["how do I get my money back"], "retrieval.query", dimensions=64)
d = r.json()
print(r.status_code, len(d["data"][0]["embedding"]), d["usage"])
text = ["When your refund arrives"]
q = jina(text, "retrieval.query").json()["data"][0]["embedding"]
p = jina(text, "retrieval.passage").json()["data"][0]["embedding"]
print("query and passage identical:", q == p)
r = jina(text, "retrieval.document")
print(r.status_code, r.json()["error"]["message"])
EOF_FILE
put sheet.py <<'EOF_FILE'
from prices import sheet

d = sheet()
emb = [k for k, v in d.items() if v.get("mode") == "embedding"]
print("embedding rows:", len(emb))
print("rows naming jina:", [(k, v["mode"]) for k, v in d.items() if "jina" in k])
rows = ["voyage/voyage-code-3", "voyage/voyage-law-2", "voyage/voyage-finance-2",
        "mistral/codestral-embed", "fireworks_ai/nomic-ai/nomic-embed-text-v1.5",
        "together_ai/BAAI/bge-base-en-v1.5", "novita/baai/bge-m3"]
for k in rows:
    v = d[k]
    usd = v["input_cost_per_token"] * 1e6
    dims = v.get("output_vector_size") or "-"
    print(f"{k:44} {usd:6.3f} {dims:>5} {v['max_input_tokens']:>6}")
EOF_FILE
put static.py <<'EOF_FILE'
import numpy as np
from wordllama import WordLlama

wl = WordLlama.load()
print(wl.embedding.shape, wl.embedding.dtype)
text = "Is there a cheaper postage option for a single paperback?"
ids = wl.tokenizer.encode(text, add_special_tokens=False).ids
v = wl.embedding[ids].mean(axis=0)
v /= np.linalg.norm(v)
print(len(ids), "tokens")
print("same as embed():", np.allclose(v, wl.embed(text, norm=True)[0], atol=1e-6))
EOF_FILE
put speed.py <<'EOF_FILE'
import json
import time
from minilm import embed
from wordllama import WordLlama

texts = [t["text"] for t in map(json.loads, open("data/tickets.jsonl"))]
wl = WordLlama.load()
def best(f, runs=5):
    times = []
    for _ in range(runs):
        t = time.perf_counter()
        f()
        times.append(time.perf_counter() - t)
    return min(times)
m = best(lambda: embed(texts))
w = best(lambda: wl.embed(texts, norm=True))
print(f"{len(texts)} texts")
print(f"minilm     {m * 1000:7.1f} ms {len(texts) / m:8.0f} texts/s")
print(f"wordllama  {w * 1000:7.1f} ms {len(texts) / w:8.0f} texts/s")
print(f"wordllama is {m / w:.0f} times faster")
EOF_FILE
put quality.py <<'EOF_FILE'
import json
import numpy as np
from minilm import embed
from wordllama import WordLlama

wl = WordLlama.load()
models = {"minilm": embed, "wordllama": lambda t: wl.embed(t, norm=True)}
rows = lambda f: [json.loads(l) for l in open(f)]
help, queries, tickets = rows("data/help.jsonl"), rows("data/queries.jsonl"), rows("data/tickets.jsonl")
train = [t for t in tickets if t["split"] == "train"]
test = [t for t in tickets if t["split"] == "test"]
ids = [h["id"] for h in help]
for name, f in models.items():
    D = f([h["title"] + ". " + h["body"] for h in help])
    Q = f([q["text"] for q in queries])
    top = np.argsort(-(Q @ D.T), axis=1)[:, :3]
    r1 = sum(ids[t[0]] in q["relevant"] for t, q in zip(top, queries))
    r3 = sum(any(ids[i] in q["relevant"] for i in t) for t, q in zip(top, queries))
    A, B = f([t["text"] for t in train]), f([t["text"] for t in test])
    near = (B @ A.T).argmax(axis=1)
    ok = sum(train[j]["label"] == t["label"] for j, t in zip(near, test))
    print(f"{name:10} top-1 {r1}/24  top-3 {r3}/24  tickets {ok}/50")
EOF_FILE
put misses.py <<'EOF_FILE'
import json
from minilm import embed
from wordllama import WordLlama

wl = WordLlama.load()
tickets = [json.loads(l) for l in open("data/tickets.jsonl")]
train = [t for t in tickets if t["split"] == "train"]
A = {"minilm": embed([t["text"] for t in train]),
     "wordllama": wl.embed([t["text"] for t in train], norm=True)}
for t in tickets:
    if t["id"] not in ("t026", "t120"):
        continue
    print(f"{t['id']} [{t['label']}] {t['text']}")
    for name, f in (("minilm", embed), ("wordllama", lambda x: wl.embed(x, norm=True))):
        n = train[int((A[name] @ f([t["text"]])[0]).argmax())]
        print(f"  {name:10} [{n['label']}] {n['text']}")
EOF_FILE
put switch.py <<'EOF_FILE'
import json
import numpy as np
from minilm import embed
from wordllama import WordLlama

help = [json.loads(l) for l in open("data/help.jsonl")]
queries = [json.loads(l) for l in open("data/queries.jsonl")]
ids = [h["id"] for h in help]
D = embed([h["title"] + ". " + h["body"] for h in help])
Q = embed([q["text"] for q in queries])
rng = np.random.default_rng(0)
R, _ = np.linalg.qr(rng.normal(size=(384, 384)))
D2, Q2 = D @ R, Q @ R
def top1(Q, D):
    best = (Q @ D.T).argmax(axis=1)
    return sum(ids[b] in q["relevant"] for b, q in zip(best, queries))

print("A queries, A articles:", top1(Q, D), "/ 24")
print("B queries, B articles:", top1(Q2, D2), "/ 24")
print("B queries, A articles:", top1(Q2, D), "/ 24")
for name, X in (("A against A", Q @ D.T), ("B against A", Q2 @ D.T)):
    print(f"{name}: scores from {X.min():.3f} to {X.max():.3f}")
wl = WordLlama.load()
try:
    wl.embed(["how do I get my money back"], norm=True) @ D.T
except ValueError as e:
    print("ValueError:", e)
EOF_FILE

block jina
on 'python jina.py'

block jina-log
on 'tail -n 4 labembed.jsonl | jq -c "{provider, task, dims, status}"'

block prices
on 'python prices.py'

block sheet
on 'python sheet.py'

block static
on 'python static.py'
on 'ls -l ~/.venvs/emb/lib/python3.12/site-packages/wordllama/weights/ ~/models/all-MiniLM-L6-v2/model.onnx'

block speed
on 'nproc; grep -m1 "model name" /proc/cpuinfo'
on 'python speed.py'

block quality
on 'python quality.py'

block misses
on 'python misses.py'

block langs
on 'jq -r .lang data/help.jsonl | sort | uniq -c'

block switch
on 'python switch.py'
