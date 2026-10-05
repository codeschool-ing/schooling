#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of embeddings-vectors, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# The programs are the ones the sections show, written into ~/emb by `put`.
# Nothing is staged: the chart in "hybrid-search" is drawn from what
# hybrid.py prints.
#
# Every vector comes from all-MiniLM-L6-v2, run on this machine; lab.sh says
# where it was fetched from. The relevance judgements are the course's own:
# the 24 questions in data/queries.jsonl, and the eight exact strings listed
# in evaluate.py. The timing in index.py is whatever this machine took on
# the day, with other work running beside it.
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
lab reset >/dev/null

put bm25.py <<'EOF_FILE'
import collections
import json
import math
import re
import sys

help = [json.loads(line) for line in open("data/help.jsonl")]
def words(text):
    return re.findall(r"[a-z0-9]+(?:[-.@][a-z0-9]+)*", text.lower())

docs = [words(h["title"] + ". " + h["body"]) for h in help]
average = sum(map(len, docs)) / len(docs)
df = collections.Counter(w for d in docs for w in set(d))
def bm25(query, k1=1.5, b=0.75):
    scores = [0.0] * len(docs)
    for w in words(query):
        if w not in df:
            continue
        idf = math.log(1 + (len(docs) - df[w] + 0.5) / (df[w] + 0.5))
        for i, d in enumerate(docs):
            tf = d.count(w)
            scores[i] += idf * tf * (k1 + 1) / (tf + k1 * (1 - b + b * len(d) / average))
    return scores
def keyword_search(query):
    scores = bm25(query)
    found = [i for i in range(len(docs)) if scores[i] > 0]
    return sorted(found, key=lambda i: -scores[i])
if __name__ == "__main__":
    query = sys.argv[1]
    scores = bm25(query)
    for i in keyword_search(query)[:3]:
        print(f"{scores[i]:6.2f}  {help[i]['id']}  {help[i]['title']}")
EOF_FILE
put index.py <<'EOF_FILE'
import json
import time
import numpy as np
from minilm import embed

help = [json.loads(line) for line in open("data/help.jsonl")]
texts = [h["title"] + ". " + h["body"] for h in help]
start = time.perf_counter()
D = embed(texts)
print(f"embedded {len(texts)} articles in {time.perf_counter() - start:.2f} s")
np.save("index.npy", D)
json.dump([h["id"] for h in help], open("ids.json", "w"))
print(D.shape, D.dtype)
EOF_FILE
put search.py <<'EOF_FILE'
import json
import sys
import numpy as np
from minilm import embed

D = np.load("index.npy")
ids = json.load(open("ids.json"))
help = {h["id"]: h for h in map(json.loads, open("data/help.jsonl"))}
def search(query, k=3):
    q = embed(query)[0]
    scores = D @ q
    best = np.argsort(-scores)[:k]
    return [(ids[i], float(scores[i])) for i in best]
if __name__ == "__main__":
    for doc, score in search(sys.argv[1]):
        print(f"{score:6.3f}  {doc}  {help[doc]['title']}")
EOF_FILE
put evaluate.py <<'EOF_FILE'
import json
import numpy as np
from bm25 import keyword_search
from search import D, ids, embed

queries = [json.loads(line) for line in open("data/queries.jsonl")]
exact = [("MG-20481937", ["h06"]), ("Pix", ["h20"]), ("EPUB", ["h32"]), ("4.90", ["h07"]),
         ("Visa", ["h20"]), ("prepaid label", ["h14"]), ("photo ID", ["h11"]),
         ("cash on delivery", ["h20"])]
natural = [(q["text"], q["relevant"]) for q in queries]
def embedding_search(text):
    return list(np.argsort(-(D @ embed(text)[0])))

def recall(rank, questions, k):
    found = 0
    for text, relevant in questions:
        found += any(ids[i] in relevant for i in rank(text)[:k])
    return found
if __name__ == "__main__":
    for name, questions in (("24 questions", natural), ("8 exact strings", exact)):
        print(name)
        for method, rank in (("keyword", keyword_search), ("embedding", embedding_search)):
            print(f"  {method:10} recall@1 {recall(rank, questions, 1):2}  recall@3 {recall(rank, questions, 3):2}")
    for text, relevant in exact:
        k, e = keyword_search(text), embedding_search(text)
        where = lambda r: r.index(ids.index(relevant[0])) + 1 if ids.index(relevant[0]) in r else "-"
        print(f"  {text:18} keyword rank {where(k)}  embedding rank {where(e)}")
EOF_FILE
put chunking.py <<'EOF_FILE'
import json
import numpy as np
from minilm import embed, pieces

help = [h for h in map(json.loads, open("data/help.jsonl")) if h["lang"] == "en"]
queries = [json.loads(line) for line in open("data/queries.jsonl")]
pages = []
for category in ("orders", "shipping", "returns", "payments", "account", "ebooks"):
    articles = [h for h in help if h["category"] == category]
    for i in range(0, len(articles), 3):
        group = articles[i:i + 3]
        pages.append(([h["id"] for h in group],
                      " ".join(h["title"] + ". " + h["body"] for h in group)))
print(f"{len(pages)} pages, the longest {max(len(pieces(t)) for _, t in pages)} word pieces")
def windows(text, size=40, overlap=10):
    w = text.split()
    return [" ".join(w[i:i + size]) for i in range(0, max(len(w) - overlap, 1), size - overlap)]

chunkings = {
    "whole page": [(p, text) for p, (_, text) in enumerate(pages)],
    "one article": [(p, h["title"] + ". " + h["body"])
                    for p, (members, _) in enumerate(pages) for h in help if h["id"] in members],
    "40-word window": [(p, w) for p, (_, text) in enumerate(pages) for w in windows(text)],
}
Q = embed([q["text"] for q in queries])
for name, chunks in chunkings.items():
    V = embed([text for _, text in chunks])
    owner = np.array([p for p, _ in chunks])
    right, best = 0, []
    for q, v in zip(queries, Q):
        scores = V @ v
        right += bool(set(pages[owner[scores.argmax()]][0]) & set(q["relevant"]))
        best.append(scores.max())
        if q["id"] == "q15":
            example = f"{' '.join(pages[owner[scores.argmax()]][0])} at {scores.max():.3f}"
    print(f"{name:15} {len(chunks):3} vectors  right page first {right:2}/24"
          f"  mean best {np.mean(best):.3f}  q15: {example}")
EOF_FILE
put hybrid.py <<'EOF_FILE'
import collections
from bm25 import keyword_search, help
from evaluate import embedding_search, recall, natural, exact
from search import ids
def rrf(rankings, weights=None, k=60):
    weights = weights or [1] * len(rankings)
    scores = collections.defaultdict(float)
    for ranking, weight in zip(rankings, weights):
        for rank, doc in enumerate(ranking, start=1):
            scores[doc] += weight / (k + rank)
    return sorted(scores, key=lambda d: -scores[d]), scores
query = "how fast is shipping"
kw, em = keyword_search(query), embedding_search(query)
fused, scores = rrf([kw, em])
for doc in fused[:3]:
    k_rank = kw.index(doc) + 1 if doc in kw else "-"
    print(f"{ids[doc]}  keyword {k_rank}  embedding {em.index(doc) + 1}"
          f"  rrf {scores[doc]:.5f}  {help[doc]['title']}")
methods = {
    "keyword": keyword_search,
    "embedding": embedding_search,
    "hybrid": lambda t: rrf([keyword_search(t), embedding_search(t)])[0],
    "hybrid, keyword x0.5": lambda t: rrf([keyword_search(t), embedding_search(t)], [0.5, 1])[0],
}
print("                       24 questions    8 exact strings")
for name, rank in methods.items():
    print(f"{name:22} @1 {recall(rank, natural, 1):2}  @3 {recall(rank, natural, 3):2}"
          f"    @1 {recall(rank, exact, 1)}  @3 {recall(rank, exact, 3)}")
EOF_FILE

block keyword
on 'python bm25.py "MG-20481937"'
on 'python bm25.py "get rid of my profile for good"'

block index
on 'python index.py'
on 'ls -l index.npy ids.json'

block search
on 'python search.py "how do I get my money back"'
on 'python search.py "the box never showed up"'

block evaluate
on 'python evaluate.py'

block chunking
on 'python chunking.py'

block hybrid
on 'python hybrid.py'
on 'python search.py "4.90"'
