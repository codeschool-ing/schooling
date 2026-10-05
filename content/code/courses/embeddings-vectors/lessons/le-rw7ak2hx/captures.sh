#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of embeddings-vectors, as a script
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
# THE 100,000 VECTORS ARE NOT EMBEDDINGS OF 100,000 TEXTS. make_set.py embeds
# the course's own 334 texts with all-MiniLM-L6-v2 and makes each vector a
# blend of two of them, in a random proportion, plus a little noise,
# renormalised; the 1,000 queries are made the same way. uniform.py uses
# uniformly random unit vectors instead. Both come from seeded generators.
# The exact top 10 of every query, the ground truth every recall is measured
# against, comes from FAISS's IndexFlatIP.
#
# Searches are timed on one core (faiss.omp_set_num_threads(1) and hnswlib's
# set_num_threads(1)), as a batch of 1,000 queries divided by 1,000. Builds
# use the machine's four cores. Other captures may have been running at the
# same time, so a time here is this run's and no other's.
#
# FAISS 1.15.1, hnswlib 0.8.0 and pgvector 0.6.0 are the versions pinned in
# lab.sh.
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

put make_set.py <<'EOF_FILE'
import json
import faiss
import numpy as np
from minilm import embed

sources = [("help", "body"), ("queries", "text"), ("tickets", "text"),
           ("books", "blurb"), ("inbox", "text"), ("week2", "text")]
texts = [json.loads(line)[key] for name, key in sources
         for line in open(f"data/{name}.jsonl")]
real = embed(texts)
rng = np.random.default_rng(15)

def blends(n):
    a = real[rng.integers(len(real), size=n)]
    b = real[rng.integers(len(real), size=n)]
    w = rng.random((n, 1))
    v = w * a + (1 - w) * b + rng.normal(scale=0.05, size=(n, 384))
    return (v / np.linalg.norm(v, axis=1, keepdims=True)).astype("float32")

X, Q = blends(100_000), blends(1_000)
exact = faiss.IndexFlatIP(384)
exact.add(X)
scores, truth = exact.search(Q, 10)
np.save("vectors.npy", X)
np.save("queries.npy", Q)
np.save("truth.npy", truth)
print(f"{len(real)} real vectors, {len(X):,} blends, {len(Q):,} queries")
print(f"best score per query, median: {np.median(scores[:, 0]):.3f}")
print(f"10th score per query, median: {np.median(scores[:, 9]):.3f}")
EOF_FILE
put bench.py <<'EOF_FILE'
import time
import faiss
import numpy as np

X = np.load("vectors.npy")
Q = np.load("queries.npy")
truth = np.load("truth.npy")
def recall(I):
    return np.mean([len(set(found) & set(true)) / 10
                    for found, true in zip(I, truth)])
def timed(search):
    faiss.omp_set_num_threads(1)
    start = time.perf_counter()
    I = search(Q)
    ms = (time.perf_counter() - start) * 1000 / len(Q)
    faiss.omp_set_num_threads(4)
    return I, ms
EOF_FILE
put exact.py <<'EOF_FILE'
import faiss
from bench import X, timed

print(f"{'vectors':>9} {'per query':>10} {'per vector':>11}")
for n in (12_500, 25_000, 50_000, 100_000):
    index = faiss.IndexFlatIP(384)
    index.add(X[:n])
    _, ms = timed(lambda Q: index.search(Q, 10)[1])
    print(f"{n:>9,} {ms:>7.3f} ms {ms * 1e6 / n:>8.1f} ns")
EOF_FILE
put recall.py <<'EOF_FILE'
import faiss
import numpy as np
from bench import X, Q, truth, recall

rng = np.random.default_rng(1)
part = rng.choice(len(X), size=10_000, replace=False)
sample = faiss.IndexIDMap(faiss.IndexFlatIP(384))
sample.add_with_ids(X[part], part)
_, I = sample.search(Q, 10)
print(f"exact search over a random tenth: recall@10 {recall(I):.3f}")
hnsw = faiss.index_factory(384, "HNSW32", faiss.METRIC_INNER_PRODUCT)
hnsw.add(X)
S, I = hnsw.search(Q, 10)
per = np.array([len(set(a) & set(b)) / 10 for a, b in zip(I, truth)])
print(f"HNSW32 over everything:          recall@10 {per.mean():.3f}")
print(f"queries with all 10: {np.sum(per == 1)}, with 5 or fewer: {np.sum(per <= 0.5)}")
true_scores = (X[truth] * Q[:, None, :]).sum(axis=2)
print(f"mean score of the 10 returned: exact {true_scores.mean():.4f}, HNSW32 {S.mean():.4f}")
EOF_FILE
put ivf.py <<'EOF_FILE'
import time
import faiss
import numpy as np
from bench import X, recall, timed

cells = faiss.IndexFlatIP(384)
ivf = faiss.IndexIVFFlat(cells, 384, 1024, faiss.METRIC_INNER_PRODUCT)
try:
    ivf.add(X)
except RuntimeError as e:
    print("add before train:", str(e).splitlines()[-1])
start = time.perf_counter()
ivf.train(X)
ivf.add(X)
print(f"k-means into 1024 cells, then add: {time.perf_counter() - start:.1f} s")
sizes = np.array([ivf.invlists.list_size(i) for i in range(1024)])
print(f"vectors per cell: smallest {sizes.min()}, median {np.median(sizes):.0f}, largest {sizes.max()}")
print(f"{'nprobe':>6} {'recall@10':>9} {'per query':>10} {'compared':>9}")
for nprobe in (1, 2, 4, 8, 16, 32, 64):
    ivf.nprobe = nprobe
    faiss.cvar.indexIVF_stats.reset()
    I, ms = timed(lambda Q: ivf.search(Q, 10)[1])
    compared = faiss.cvar.indexIVF_stats.ndis / 1000
    print(f"{nprobe:>6} {recall(I):>9.3f} {ms:>7.3f} ms {compared:>9,.0f}")
EOF_FILE
put uniform.py <<'EOF_FILE'
import faiss
import numpy as np

rng = np.random.default_rng(15)
def uniform(n):
    v = rng.normal(size=(n, 384))
    return (v / np.linalg.norm(v, axis=1, keepdims=True)).astype("float32")
X, Q = uniform(100_000), uniform(1_000)

exact = faiss.IndexFlatIP(384)
exact.add(X)
scores, truth = exact.search(Q, 10)
print(f"best score per query, median: {np.median(scores[:, 0]):.3f}")

ivf = faiss.IndexIVFFlat(faiss.IndexFlatIP(384), 384, 1024, faiss.METRIC_INNER_PRODUCT)
ivf.train(X)
ivf.add(X)
for nprobe in (1, 8, 64):
    ivf.nprobe = nprobe
    _, I = ivf.search(Q, 10)
    r = np.mean([len(set(a) & set(b)) / 10 for a, b in zip(I, truth)])
    print(f"nprobe {nprobe:>2}: recall@10 {r:.3f}")
EOF_FILE
put layers.py <<'EOF_FILE'
import time
import faiss
import numpy as np
from bench import X, Q, truth

index = faiss.IndexHNSWFlat(384, 16, faiss.METRIC_INNER_PRODUCT)
start = time.perf_counter()
index.add(X)
print(f"built in {time.perf_counter() - start:.1f} s")
g = index.hnsw
top = np.bincount(faiss.vector_to_array(g.levels) - 1)
for layer in range(g.max_level, -1, -1):
    print(f"layer {layer}: {top[layer:].sum():>7,} vectors")
offsets = faiss.vector_to_array(g.offsets)
links = faiss.vector_to_array(g.neighbors)
cum = faiss.vector_to_array(g.cum_nneighbor_per_level)

def neighbours(v, layer):
    first, last = offsets[v] + cum[layer], offsets[v] + cum[layer + 1]
    return [n for n in links[int(first):int(last)] if n >= 0]
q = Q[0]
here = g.entry_point
for layer in range(g.max_level, 0, -1):
    path = [here]
    while True:
        best = max(neighbours(here, layer) + [here], key=lambda n: X[n] @ q)
        if best == here:
            break
        here = best
        path.append(here)
    print(f"layer {layer}:", "  ".join(f"{v}={X[v] @ q:.3f}" for v in path))
faiss.cvar.hnsw_stats.reset()
S, I = index.search(Q[:1], 10)
print(f"layer 0: best {I[0][0]}={S[0][0]:.3f} after {faiss.cvar.hnsw_stats.ndis} comparisons in all")
print(f"exact:   best {truth[0][0]}={X[truth[0][0]] @ q:.3f}")
EOF_FILE
put params.py <<'EOF_FILE'
import os
import time
import hnswlib
from bench import X, Q, recall

print(f"{'M':>2} {'ef_construction':>15} {'build':>7} {'bytes/vector':>12} {'recall@10':>9} {'per query':>10}")
for M, ef_construction in ((8, 200), (16, 200), (32, 200), (16, 40)):
    index = hnswlib.Index(space="ip", dim=384)
    index.init_index(max_elements=len(X), M=M, ef_construction=ef_construction)
    start = time.perf_counter()
    index.add_items(X)
    built = time.perf_counter() - start
    index.save_index(f"m{M}-{ef_construction}.bin")
    size = os.path.getsize(f"m{M}-{ef_construction}.bin") / len(X)
    index.set_ef(40)
    index.set_num_threads(1)
    start = time.perf_counter()
    I, _ = index.knn_query(Q, k=10)
    ms = (time.perf_counter() - start) * 1000 / len(Q)
    print(f"{M:>2} {ef_construction:>15} {built:>5.1f} s {size:>12,.0f} {recall(I):>9.3f} {ms:>7.3f} ms")
EOF_FILE
put ef_sweep.py <<'EOF_FILE'
import time
import hnswlib
from bench import X, Q, recall

index = hnswlib.Index(space="ip", dim=384)
index.load_index("m16-200.bin")
index.set_num_threads(1)
print(f"{'ef':>4} {'recall@10':>9} {'per query':>10}")
for ef in (10, 20, 40, 80, 160, 320):
    index.set_ef(ef)
    start = time.perf_counter()
    I, _ = index.knn_query(Q, k=10)
    ms = (time.perf_counter() - start) * 1000 / len(Q)
    print(f"{ef:>4} {recall(I):>9.3f} {ms:>7.3f} ms")
EOF_FILE
put quant.py <<'EOF_FILE'
import time
import faiss
import numpy as np
from bench import X, recall, timed

sample = X[np.random.default_rng(2).choice(len(X), size=40_000, replace=False)]
print(f"{'index':>13} {'bytes/vector':>12} {'train':>7} {'recall@10':>9} {'per query':>10}")
for spec in ("IVF1024,Flat", "IVF1024,SQ8", "IVF1024,PQ96", "IVF1024,PQ48", "IVF1024,PQ16"):
    index = faiss.index_factory(384, spec, faiss.METRIC_INNER_PRODUCT)
    start = time.perf_counter()
    index.train(sample)
    trained = time.perf_counter() - start
    index.add(X)
    index.nprobe = 16
    I, ms = timed(lambda Q: index.search(Q, 10)[1])
    print(f"{spec:>13} {index.code_size:>12} {trained:>5.1f} s {recall(I):>9.3f} {ms:>7.3f} ms")
EOF_FILE

block machine
on 'nproc; grep -m1 "model name" /proc/cpuinfo'

block make
on 'python make_set.py'

block exact
on 'python exact.py'

block recall
on 'python recall.py'

block ivf
on 'python ivf.py'

block uniform
on 'python uniform.py'

block layers
on 'python layers.py'

block params
on 'python params.py'

block ef
on 'python ef_sweep.py'

block quant
on 'python quant.py'

block pg
on 'psql -c "CREATE EXTENSION vector" -c "SHOW hnsw.ef_search" -c "SHOW ivfflat.probes"'
