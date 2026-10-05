#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of embeddings-vectors, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# The programs are the ones the sections show, written into ~/emb by `put`.
# Nothing is staged: every program that prints a number quoted in the lesson
# is shown in it. The first one to run, knn.py, embeds the 150 tickets and
# leaves train.npy and test.npy behind for the others.
#
# Every vector comes from all-MiniLM-L6-v2 or WordLlama, run on this machine;
# lab.sh says where each was fetched from. The tickets and their labels in
# data/tickets.jsonl were written for the course.
#
# Recorded on Ubuntu 24.04, Python 3.11, scikit-learn 1.9.1,
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
lab reset >/dev/null 9>&-   # the daemons it starts must not inherit the lock

put tickets.py <<'EOF_FILE'
import json
import os
import numpy as np
from minilm import embed

def load(split):
    rows = [t for t in map(json.loads, open("data/tickets.jsonl"))
            if t["split"] == split]
    path = f"{split}.npy"
    if not os.path.exists(path):
        np.save(path, embed([t["text"] for t in rows]))
    labels = np.array([t["label"] for t in rows])
    return np.load(path), labels, rows
EOF_FILE
put knn.py <<'EOF_FILE'
from collections import Counter
import numpy as np
from tickets import load

Xtr, ytr, train = load("train")
Xte, yte, test = load("test")
print(Xtr.shape, Xte.shape)
S = Xte @ Xtr.T
order = np.argsort(-S, axis=1)
def vote(row, k):
    return Counter(ytr[row[:k]]).most_common(1)[0][0]

for k in (1, 3, 5, 10):
    pred = np.array([vote(row, k) for row in order])
    print(f"k={k:<3} {(pred == yte).sum()} of {len(yte)} right")
EOF_FILE
put neighbours.py <<'EOF_FILE'
import sys
import numpy as np
from tickets import load

Xtr, ytr, train = load("train")
Xte, yte, test = load("test")
i = [t["id"] for t in test].index(sys.argv[1])
print(test[i]["id"], yte[i], test[i]["text"])
s = Xtr @ Xte[i]
for j in np.argsort(-s)[:5]:
    print(f"  {s[j]:.3f}  {train[j]['id']}  {ytr[j]:9} {train[j]['text']}")
EOF_FILE
put centroids.py <<'EOF_FILE'
import numpy as np
from tickets import load

Xtr, ytr, train = load("train")
Xte, yte, test = load("test")
labels = sorted(set(ytr))
C = np.array([Xtr[ytr == label].mean(axis=0) for label in labels])
print("length before:", np.linalg.norm(C, axis=1).round(3))
C /= np.linalg.norm(C, axis=1, keepdims=True)
pred = np.array(labels)[(Xte @ C.T).argmax(axis=1)]
print((pred == yte).sum(), "of", len(yte), "right")
for label, c in zip(labels, C):
    s = Xtr @ c
    s[ytr != label] = np.nan
    near, far = np.nanargmax(s), np.nanargmin(s)
    print(f"{label:9} {s[near]:.3f} {train[near]['text']}")
    print(f"{'':9} {s[far]:.3f} {train[far]['text']}")
EOF_FILE
put trained.py <<'EOF_FILE'
import time
import numpy as np
from sklearn.linear_model import LogisticRegression
from tickets import load

Xtr, ytr, train = load("train")
Xte, yte, test = load("test")
t0 = time.perf_counter()
model = LogisticRegression(max_iter=1000).fit(Xtr, ytr)
print(f"trained in {(time.perf_counter() - t0) * 1000:.0f} ms")
print("weights:", model.coef_.shape, "+", model.intercept_.shape)
pred = model.predict(Xte)
print((pred == yte).sum(), "of", len(yte), "right")
i = [t["id"] for t in test].index("t027")
print(test[i]["text"])
for label, p in zip(model.classes_, model.predict_proba(Xte[i:i + 1])[0]):
    print(f"  {label:9} {p:.3f}")
EOF_FILE
put fewer.py <<'EOF_FILE'
import numpy as np
from sklearn.linear_model import LogisticRegression
from wordllama import WordLlama
from tickets import load

Xtr, ytr, train = load("train")
Xte, yte, test = load("test")
labels = sorted(set(ytr))
wl = WordLlama.load()
texts = lambda rows: [t["text"] for t in rows]
models = {"minilm": (Xtr, Xte),
          "wordllama": (wl.embed(texts(train), norm=True), wl.embed(texts(test), norm=True))}

def scores(A, y, B):
    C = np.array([A[y == label].mean(axis=0) for label in labels])
    C /= np.linalg.norm(C, axis=1, keepdims=True)
    knn = y[(B @ A.T).argmax(axis=1)]
    cen = np.array(labels)[(B @ C.T).argmax(axis=1)]
    lr = LogisticRegression(max_iter=1000).fit(A, y).predict(B)
    return [(p == yte).sum() for p in (knn, cen, lr)]

print("model      per label   1-nn  centroid  logistic")
for name, (A, B) in models.items():
    for n in (1, 2, 3, 5, 10, 20):
        keep = np.concatenate([np.flatnonzero(ytr == label)[:n] for label in labels])
        k1, cen, lr = scores(A[keep], ytr[keep], B)
        print(f"{name:10} {n:>9} {k1:>6} {cen:>9} {lr:>9}")
EOF_FILE
put zeroshot.py <<'EOF_FILE'
import numpy as np
from minilm import embed
from tickets import load

Xte, yte, test = load("test")
labels = ["account", "ebooks", "payments", "returns", "shipping"]
wordings = {
    "names": ["account", "ebooks", "payments", "returns", "shipping"],
    "descriptions": [
        "a question about signing in, passwords and personal data",
        "a question about e-books, audiobooks and the reading app",
        "a question about paying, cards, charges and invoices",
        "a question about sending a book back for a refund or exchange",
        "a question about delivery and parcels",
    ],
    "examples": [
        "I can't log in to my account.",
        "My e-book won't open in the app.",
        "My card was charged twice at checkout.",
        "I want to return this book and get a refund.",
        "Where is my parcel? It has not been delivered yet.",
    ],
}
for name, texts in wordings.items():
    D = embed(texts)
    pred = np.array(labels)[(Xte @ D.T).argmax(axis=1)]
    print(f"{name:13} {(pred == yte).sum()} of {len(yte)} right")
EOF_FILE
put measure.py <<'EOF_FILE'
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import classification_report, confusion_matrix
from tickets import load

Xtr, ytr, train = load("train")
Xte, yte, test = load("test")
model = LogisticRegression(max_iter=1000).fit(Xtr, ytr)
pred = model.predict(Xte)
labels = list(model.classes_)
print("          " + " ".join(f"{l[:8]:>8}" for l in labels))
for label, row in zip(labels, confusion_matrix(yte, pred, labels=labels)):
    print(f"{label:9} " + " ".join(f"{n:>8}" for n in row))
print(classification_report(yte, pred, digits=3))
for t, p in zip(test, pred):
    if p != t["label"]:
        print(f"{t['id']}  {t['label']} -> {p}: {t['text']}")
EOF_FILE

block head
on 'head -n 3 data/tickets.jsonl'
on "jq -r '.split + \" \" + .label' data/tickets.jsonl | sort | uniq -c"

block knn
on 'python knn.py'

block neighbours
on 'python neighbours.py t021'
on 'python neighbours.py t054'

block centroids
on 'python centroids.py'

block trained
on 'python trained.py'

block fewer
on 'python fewer.py'

block zeroshot
on 'python zeroshot.py'

block measure
on 'python measure.py'
