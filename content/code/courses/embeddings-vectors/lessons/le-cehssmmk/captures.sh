#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of embeddings-vectors, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# The programs are the ones the sections show, written into ~/emb by `put`.
# Nothing is staged: the two figures are drawn from what cosine.py and
# crowded.py print.
#
# Every vector comes from all-MiniLM-L6-v2 or WordLlama, run on this machine;
# lab.sh says where each was fetched from. The random rotation and the random
# vectors are drawn with fixed seeds, so a second run prints the same numbers.
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

put rotate.py <<'EOF_FILE'
import json
import numpy as np
from minilm import embed

help = [json.loads(line) for line in open("data/help.jsonl")]
D = embed([h["title"] + ". " + h["body"] for h in help])
rng = np.random.default_rng(2)
Q, _ = np.linalg.qr(rng.standard_normal((384, 384)))
R = D @ Q
print("before:", D[0, :4].round(4))
print("after: ", R[0, :4].round(4))
change = np.abs(D @ D.T - R @ R.T).max()
print(f"largest change in any of {len(D) * len(D)} scores: {change:.1e}")
EOF_FILE
put dot.py <<'EOF_FILE'
import numpy as np

a = np.array([2, 1, 2])
b = np.array([1, 2, 2])
print(a * b)
print((a * b).sum())
print(a @ b)
print((2 * a) @ b)
EOF_FILE
put cosine.py <<'EOF_FILE'
import numpy as np

def cosine(x, y):
    return x @ y / (np.linalg.norm(x) * np.linalg.norm(y))

a = np.array([2, 1, 2])
b = np.array([1, 2, 2])
print(np.linalg.norm(a), np.linalg.norm(b))
print(round(cosine(a, b), 4))
print(round(np.degrees(np.arccos(cosine(a, b))), 1), "degrees")
print(round(cosine(2 * a, b), 4))
c = np.array([1, -2, 0])
print(cosine(a, c), cosine(a, -a))
D = np.array([a, 2 * a, b, c])
print((D @ b / (np.linalg.norm(D, axis=1) * np.linalg.norm(b))).round(4))
EOF_FILE
put euclid.py <<'EOF_FILE'
import json
import numpy as np
from minilm import embed

a = np.array([2, 1, 2])
b = np.array([1, 2, 2])
print(a - b, round(np.linalg.norm(a - b), 3))
help = [json.loads(line) for line in open("data/help.jsonl")]
D = embed([h["title"] + ". " + h["body"] for h in help])
queries = [json.loads(line) for line in open("data/queries.jsonl")]
Qv = embed([q["text"] for q in queries])
q = Qv[0]
cos = D @ q
dist = np.linalg.norm(D - q, axis=1)
print("      cos    dist   2-2cos  dist^2")
for i in np.argsort(-cos)[:4]:
    print(f"{help[i]['id']}  {cos[i]:.3f}  {dist[i]:.3f}  {2 - 2 * cos[i]:.3f}  {dist[i] ** 2:.3f}")
same_l2 = same_l1 = top_l1 = 0
for q in Qv:
    by_cos = np.argsort(-(D @ q))
    by_l2 = np.argsort(np.linalg.norm(D - q, axis=1))
    by_l1 = np.argsort(np.abs(D - q).sum(axis=1))
    same_l2 += (by_cos == by_l2).all()
    same_l1 += (by_cos == by_l1).all()
    top_l1 += by_cos[0] == by_l1[0]
print(f"same order as cosine, all 40 articles: L2 {same_l2}/24, L1 {same_l1}/24")
print(f"same first article as cosine:          L1 {top_l1}/24")
EOF_FILE
put lengths.py <<'EOF_FILE'
import json
import numpy as np
from wordllama import WordLlama

wl = WordLlama.load()
help = [json.loads(line) for line in open("data/help.jsonl")]
ids = [h["id"] for h in help]
W = wl.embed([h["title"] + ". " + h["body"] for h in help])
for text in ["refund", "When your refund arrives"]:
    print(f"{np.linalg.norm(wl.embed(text)[0]):.3f}  {text!r}")
n = np.linalg.norm(W, axis=1)
print(f"articles: shortest {n.min():.3f}, longest {n.max():.3f}")
q = wl.embed("discount for a classroom set")[0]
raw = W @ q
cos = raw / (n * np.linalg.norm(q))
for i in [ids.index("h37"), ids.index("h05")]:
    print(f"{ids[i]}  raw {raw[i]:.3f}  length {n[i]:.3f}  cosine {cos[i]:.3f}  {help[i]['title']}")
Wn = W / n[:, None]
queries = [json.loads(line) for line in open("data/queries.jsonl")]
for query in queries:
    q = wl.embed(query["text"])[0]
    by_raw, by_cos = ids[np.argmax(W @ q)], ids[np.argmax(Wn @ q)]
    if by_raw != by_cos:
        print(f"{query['id']}  raw {by_raw}  cosine {by_cos}  relevant {' '.join(query['relevant'])}")
EOF_FILE
put metrics.sql <<'EOF_FILE'
CREATE EXTENSION vector;
SELECT '[2,1,2]'::vector <-> '[1,2,2]' AS l2_distance,
       '[2,1,2]'::vector <=> '[1,2,2]' AS cosine_distance,
       '[2,1,2]'::vector <#> '[1,2,2]' AS negative_inner_product;
EOF_FILE
put crowded.py <<'EOF_FILE'
import json
import numpy as np
from minilm import embed
from wordllama import WordLlama

tickets = [json.loads(line) for line in open("data/tickets.jsonl")]
texts = [t["text"] for t in tickets]
labels = np.array([t["label"] for t in tickets])
upper = np.triu_indices(len(texts), 1)
same = (labels[:, None] == labels[None, :])[upper]
rng = np.random.default_rng(0)
noise = rng.standard_normal((len(texts), 384))
noise /= np.linalg.norm(noise, axis=1, keepdims=True)
models = {"minilm": embed(texts),
          "wordllama": WordLlama.load().embed(texts, norm=True),
          "random": noise}
print(f"{len(same)} pairs, {same.sum()} of them with the same label")
print("            5%  median    95%    max  same label  different  above 0.4")
for name, V in models.items():
    s = (V @ V.T)[upper]
    p5, p50, p95 = np.percentile(s, [5, 50, 95])
    print(f"{name:9} {p5:6.3f} {p50:6.3f} {p95:6.3f} {s.max():6.3f}"
          f"  {s[same].mean():10.3f} {s[~same].mean():10.3f} {(s > 0.4).mean():10.1%}")
bins = np.arange(-0.25, 1.0001, 0.05)
for name in ("minilm", "wordllama"):
    V = models[name]
    print(name, " ".join(map(str, np.histogram((V @ V.T)[upper], bins)[0])))
EOF_FILE

block rotate
on 'python rotate.py'

block dot
on 'python dot.py'

block cosine
on 'python cosine.py'

block euclid
on 'python euclid.py'

block lengths
on 'python lengths.py'

block metrics
on 'psql -f metrics.sql'

block crowded
on 'python crowded.py'
