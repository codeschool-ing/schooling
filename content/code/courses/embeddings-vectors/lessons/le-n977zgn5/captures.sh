#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of embeddings-vectors, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# The programs are the ones the sections show, written into ~/emb by `put`.
# One is STAGED and not shown: plot.py, which prints every unread book's
# similarity to each of Lia's two finished books, the coordinates the figure in
# "a-reader-as-a-vector" is drawn from. The first program to run, like.py,
# embeds the sixty books through books.py and leaves books.npy behind.
#
# Every vector comes from all-MiniLM-L6-v2, run on this machine; lab.sh says
# where it was fetched from. The books are in the public domain; their blurbs,
# the readers and what they finished in data/ were written for the course, and
# so was the blurb of The Lost World in coldstart.py.
#
# Recorded on Ubuntu 24.04, Python 3.11, TZ=America/Sao_Paulo, on 2026-10-05.
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
lab reset >/dev/null 9>&-   # the daemons it starts must not inherit the lock

put books.py <<'EOF_FILE'
import json
import os
import numpy as np
from minilm import embed

books = [json.loads(line) for line in open("data/books.jsonl")]
readers = {r["reader"]: r for r in map(json.loads, open("data/readers.jsonl"))}
row = {b["id"]: i for i, b in enumerate(books)}
if not os.path.exists("books.npy"):
    np.save("books.npy", embed([b["title"] + ". " + b["blurb"] for b in books]))
B = np.load("books.npy")
def show(scores, skip=(), n=5):
    for i in np.argsort(-scores):
        b = books[i]
        if b["id"] in skip:
            continue
        print(f"  {scores[i]:.3f}  {b['id']}  {b['genre']:15} {b['title']}  ({b['author']})")
        n -= 1
        if n == 0:
            break
EOF_FILE
put like.py <<'EOF_FILE'
import sys
from books import B, books, row, show

b = books[row[sys.argv[1]]]
print(b["id"], b["title"], "-", b["genre"])
show(B @ B[row[b["id"]]], skip={b["id"]})
EOF_FILE
put genres.py <<'EOF_FILE'
import numpy as np
from minilm import embed
from books import B, books

genre = np.array([b["genre"] for b in books])
def agreement(V):
    S = V @ V.T
    np.fill_diagonal(S, -np.inf)
    top = np.argsort(-S, axis=1)[:, :5]
    return int((genre[top] == genre[:, None]).sum())
same = [(genre == g).sum() - 1 for g in genre]
chance = sum(5 * s / (len(books) - 1) for s in same)
print(f"chance:              {chance:.1f} of 300")
print(f"title. blurb:        {agreement(B)} of 300")
G = embed([b["genre"] + ". " + b["title"] + ". " + b["blurb"] for b in books])
print(f"genre. title. blurb: {agreement(G)} of 300")
EOF_FILE
put reader.py <<'EOF_FILE'
import sys
import numpy as np
from books import B, books, readers, row, show

r = readers[sys.argv[1]]
mine = [row[i] for i in r["finished"]]
print(r["name"], "finished:", ", ".join(books[i]["title"] for i in mine))
v = B[mine].mean(axis=0)
print(f"length of the average: {np.linalg.norm(v):.3f}")
v /= np.linalg.norm(v)
show(B @ v, skip=set(r["finished"]))
EOF_FILE
put between.py <<'EOF_FILE'
import numpy as np
from books import B, books, readers, row

mine = [row[i] for i in readers["r10"]["finished"]]
v = B[mine].mean(axis=0)
v /= np.linalg.norm(v)
print("        lia   " + "  ".join(books[i]["id"] for i in mine))
for i in [i for i in np.argsort(-(B @ v)) if i not in mine][:5]:
    cols = "  ".join(f"{B[i] @ B[j]:.3f}" for j in mine)
    print(f"{books[i]['id']}  {B[i] @ v:.3f}  {cols}  {books[i]['title']}")
EOF_FILE
put filters.py <<'EOF_FILE'
import numpy as np
from books import B, books, readers, row

r = readers["r02"]
v = B[[row[i] for i in r["finished"]]].mean(axis=0)
v /= np.linalg.norm(v)
scores = B @ v
out_of_stock = {"b28"}
finished = set(r["finished"])
authors = set()
picked, looked = [], 0
for i in np.argsort(-scores):
    b = books[i]
    looked += 1
    if b["id"] in finished:
        print(f"  skip {b['id']}  finished       {b['title']}")
    elif b["id"] in out_of_stock:
        print(f"  skip {b['id']}  out of stock   {b['title']}")
    elif b["author"] in authors:
        print(f"  skip {b['id']}  same author    {b['title']}  ({b['author']})")
    else:
        authors.add(b["author"])
        picked.append(i)
        if len(picked) == 5:
            break
print(f"looked at {looked} of {len(books)} to find 5")
for i in picked:
    print(f"  {scores[i]:.3f}  {books[i]['id']}  {books[i]['genre']:15} {books[i]['title']}  ({books[i]['author']})")
EOF_FILE
put mmr.py <<'EOF_FILE'
import numpy as np
from books import B, books, readers, row

r = readers["r02"]
v = B[[row[i] for i in r["finished"]]].mean(axis=0)
v /= np.linalg.norm(v)
pool = [i for i in range(len(books)) if books[i]["id"] not in r["finished"]]
def mmr(v, pool, k, lam):
    chosen, pool = [], list(pool)
    while pool and len(chosen) < k:
        def value(i):
            like = max((B[i] @ B[j] for j in chosen), default=0.0)
            return lam * (B[i] @ v) - (1 - lam) * like
        best = max(pool, key=value)
        chosen.append(best)
        pool.remove(best)
    return chosen
for lam in (1.0, 0.7, 0.6, 0.5):
    print(f"lambda {lam}")
    for i in mmr(v, pool, 5, lam):
        print(f"  {B[i] @ v:.3f}  {books[i]['id']}  {books[i]['genre']:15} {books[i]['title']}  ({books[i]['author']})")
EOF_FILE
put coldstart.py <<'EOF_FILE'
from collections import Counter
import numpy as np
from minilm import embed
from books import B, books, readers, row, show

new = embed("The Lost World. A professor leads an expedition to a remote plateau "
            "in South America where dinosaurs still roam.")[0]
print("The Lost World, nearest in the catalogue:")
show(B @ new)
print("readers who would see it in their top 5:")
for r in readers.values():
    if not r["finished"]:
        continue
    v = B[[row[i] for i in r["finished"]]].mean(axis=0)
    v /= np.linalg.norm(v)
    unread = [B[i] @ v for i in range(len(books)) if books[i]["id"] not in r["finished"]]
    rank = 1 + sum(s > new @ v for s in unread)
    if rank <= 5:
        print(f"  {r['name']:6} rank {rank}  ({new @ v:.3f})")
print("Marcos has finished:", readers["r11"]["finished"])
counts = Counter(i for r in readers.values() for i in r["finished"])
for book_id, n in counts.most_common(3):
    print(f"  {n} readers  {books[row[book_id]]['title']}")
q = embed("ghost stories and haunted houses")[0]
print("Marcos asked for ghost stories:")
show(B @ q, n=3)
EOF_FILE
put plot.py <<'EOF_FILE'
import numpy as np
from books import B, books, readers, row

mine = [row[i] for i in readers["r10"]["finished"]]
v = B[mine].mean(axis=0)
v /= np.linalg.norm(v)
top = set([i for i in np.argsort(-(B @ v)) if i not in mine][:5])
for i, b in enumerate(books):
    if i in mine:
        continue
    print(f"{b['id']} {B[i] @ B[mine[0]]:.3f} {B[i] @ B[mine[1]]:.3f} {'top' if i in top else '-'} {b['title']}")
EOF_FILE

block wc
on 'wc -l data/books.jsonl data/readers.jsonl'

block like
on 'python like.py b07'
on 'python like.py b13'

block blurbs
on 'grep -E "\"(b04|b07)\"" data/books.jsonl'

block genres
on 'python genres.py'

block reader
on 'python reader.py r02'
on 'python reader.py r10'

block between
on 'python between.py'

block plot
on 'python plot.py'

block filters
on 'python filters.py'

block mmr
on 'python mmr.py'

block coldstart
on 'python coldstart.py'

block nina
on 'python reader.py r12'
on 'python like.py b28'
