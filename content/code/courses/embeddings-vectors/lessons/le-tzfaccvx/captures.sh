#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of embeddings-vectors, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# The programs are the ones the sections show, written into ~/emb by `put`.
# Nothing is staged. brute.py searches random unit vectors, not text: random
# vectors cost exactly what real ones do to multiply, and a million of them
# take seconds to make where a million embedded texts would take hours. It
# runs NumPy's matrix library on one thread, so its timings are one core's.
# Every other vector comes from all-MiniLM-L6-v2 (WordLlama in refuse.py),
# run on this machine; lab.sh says where each was fetched from. Timings were
# measured while other programs may have been running on the machine.
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

put brute.py <<'EOF_FILE'
import os
os.environ["OPENBLAS_NUM_THREADS"] = "1"
import time
import numpy as np

rng = np.random.default_rng(11)
d = 384
q = rng.standard_normal(d).astype(np.float32)
q /= np.linalg.norm(q)
print(f"{'vectors':>9} {'memory':>9} {'per query':>10} {'queries/s':>9} {'multiply-adds':>14}")
for n in (10_000, 100_000, 1_000_000):
    D = rng.standard_normal((n, d), dtype=np.float32)
    D /= np.linalg.norm(D, axis=1, keepdims=True)
    times = []
    for _ in range(50):
        t = time.perf_counter()
        scores = D @ q
        top = np.argpartition(-scores, 10)[:10]
        times.append(time.perf_counter() - t)
    s = min(times)
    print(f"{n:>9,} {D.nbytes / 1e6:>6.0f} MB {s * 1000:>7.2f} ms {1 / s:>9.0f} {n * d:>14,}")
EOF_FILE
put tinystore.py <<'EOF_FILE'
import json
import os
import numpy as np


class Store:
    """A collection: one model, one dimension, records of id + vector + metadata + text."""
    def __init__(self, path, model, dim):
        self.path, self.model, self.dim = path, model, dim
        self.ids, self.meta, self.docs = [], [], []
        self.vecs = np.zeros((0, dim), dtype=np.float32)
        self.alive = np.zeros(0, dtype=bool)
        self.where = {}                                  # id -> row
    def upsert(self, id, vec, meta, doc):
        vec = np.asarray(vec, dtype=np.float32)
        if vec.shape != (self.dim,):
            raise ValueError(f"{self.model} vectors have {self.dim} numbers, got {vec.shape}")
        vec = vec / np.linalg.norm(vec)
        if id in self.where:                             # same id: replace in place
            self.alive[self.where[id]] = False
        self.where[id] = len(self.ids)
        self.ids.append(id); self.meta.append(meta); self.docs.append(doc)
        self.vecs = np.vstack([self.vecs, vec])
        self.alive = np.append(self.alive, True)
    def delete(self, id):
        self.alive[self.where.pop(id)] = False           # a tombstone, not a removal
    def search(self, q, k=3, model=None, **filters):
        if model != self.model:
            raise ValueError(f"this collection holds {self.model} vectors, not {model}")
        ok = self.alive.copy()
        for key, value in filters.items():
            ok &= np.array([m.get(key) == value for m in self.meta], dtype=bool)
        scores = np.where(ok, self.vecs @ q, -np.inf)
        best = np.argsort(-scores)[:k]
        return [(self.ids[i], float(scores[i])) for i in best if ok[i]]
    def save(self):
        keep = np.flatnonzero(self.alive)                # compaction drops the tombstones
        os.makedirs(self.path, exist_ok=True)
        np.save(os.path.join(self.path, "vectors.npy"), self.vecs[keep])
        with open(os.path.join(self.path, "records.json"), "w") as f:
            json.dump({"model": self.model, "dim": self.dim,
                       "records": [{"id": self.ids[i], "meta": self.meta[i], "doc": self.docs[i]}
                                   for i in keep]}, f)

    @classmethod
    def load(cls, path):
        info = json.load(open(os.path.join(path, "records.json")))
        s = cls(path, info["model"], info["dim"])
        for r, v in zip(info["records"], np.load(os.path.join(path, "vectors.npy"))):
            s.upsert(r["id"], v, r["meta"], r["doc"])
        return s
EOF_FILE
put index.py <<'EOF_FILE'
import json
from minilm import embed
from tinystore import Store

help = [json.loads(l) for l in open("data/help.jsonl")]
texts = [h["title"] + ". " + h["body"] for h in help]
store = Store("store", "all-MiniLM-L6-v2", 384)
for h, text, vec in zip(help, texts, embed(texts)):
    meta = {"category": h["category"], "lang": h["lang"], "updated": h["updated"]}
    store.upsert(h["id"], vec, meta, text)
store.save()
print(len(store.ids), "records saved")
EOF_FILE
put ask.py <<'EOF_FILE'
import sys
from minilm import embed
from tinystore import Store

store = Store.load("store")
q = embed(sys.argv[1])[0]
for id, score in store.search(q, k=3, model="all-MiniLM-L6-v2"):
    print(f"{score:.3f}  {id}  {store.docs[store.where[id]][:58]}")
EOF_FILE
put refuse.py <<'EOF_FILE'
from minilm import embed
from wordllama import WordLlama
from tinystore import Store

store = Store.load("store")
print(store.model, store.dim, len(store.ids), "records")
other = WordLlama.load().embed(["how do I get my money back"], norm=True)[0]
try:
    store.upsert("h99", other, {}, "how do I get my money back")
except ValueError as e:
    print("ValueError:", e)
q = embed("how do I get my money back")[0]
try:
    store.search(q, model="lab-minilm")
except ValueError as e:
    print("ValueError:", e)
EOF_FILE
put writes.py <<'EOF_FILE'
import json
from minilm import embed
from tinystore import Store

store = Store.load("store")
ask = lambda: [id for id, _ in store.search(q, k=3, model="all-MiniLM-L6-v2")]
q = embed("how do I get my money back")[0]
print("before:      ", ask(), "rows", len(store.ids), "alive", int(store.alive.sum()))
help = {h["id"]: h for h in map(json.loads, open("data/help.jsonl"))}
h = help["h15"]
text = h["title"] + ". " + h["body"].replace("three working days", "five working days")
store.upsert("h15", embed(text)[0], {"category": "returns", "lang": "en", "updated": "2026-10-05"}, text)
print("after edit:  ", ask(), "rows", len(store.ids), "alive", int(store.alive.sum()))
store.delete("h18")
print("after delete:", ask(), "rows", len(store.ids), "alive", int(store.alive.sum()))
store.save()
print("saved:       ", len(Store.load("store").ids), "records")
EOF_FILE
put path.py <<'EOF_FILE'
import time
from minilm import embed
from tinystore import Store

store = Store.load("store")
question = "my parcel says delivered but it never came"
for run in range(2):                       # print the second, warm run
    t0 = time.perf_counter()
    q = embed(question)[0]
    t1 = time.perf_counter()
    hits = store.search(q, k=3, model="all-MiniLM-L6-v2", lang="en")
    t2 = time.perf_counter()
    texts = [store.docs[store.where[id]] for id, _ in hits]
    t3 = time.perf_counter()
print(f"embed the question  {(t1 - t0) * 1000:7.3f} ms")
print(f"search {len(store.ids)} vectors   {(t2 - t1) * 1000:7.3f} ms")
print(f"fetch the texts     {(t3 - t2) * 1000:7.3f} ms")
print(hits[0][0], texts[0][:50])
EOF_FILE

block brute
on 'nproc; grep -m1 "model name" /proc/cpuinfo'
on 'python brute.py'

block index
on 'python index.py'
on 'ls -l store'

block ask
on 'python ask.py "how do I get my money back"'

block refuse
on 'python refuse.py'

block writes
on 'python writes.py'
on 'ls -l store'

block path
on 'python path.py'
