#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of embeddings-vectors, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# The programs are the ones the sections show, written into ~/emb by `put`.
# One is STAGED and not shown: pca.py, which projects the titles of the
# shipping, payments and e-books articles from 384 dimensions down to two,
# and prints the coordinates the figure in "close-means-similar" is drawn
# from.
#
# Every vector comes from all-MiniLM-L6-v2 or WordLlama, run on this machine;
# lab.sh says where each was fetched from.
#
# THE SETUP SECTIONS. `setup` deletes what setup.sh made (the environment,
# the model, WordLlama's cache, pip's cache and the lines in ~/.bashrc) and
# runs setup.sh again, as lesson 1 shows it: lab.sh writes it into ~/emb with
# lab/fence.py, so the file run here is the file the student reads. `fails`
# breaks the machine on purpose, one way at a time, and mends it: it removes
# python3.12-venv, stops PostgreSQL and removes pgvector, then puts each back.
# `fresh` runs a command the way a terminal opened before setup.sh would:
# without the lines setup.sh adds to ~/.bashrc.
#
# Recorded on Ubuntu 24.04, Python 3.12, TZ=America/Sao_Paulo.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
# on 'command': what ana typed in ~/emb, and what it printed.
on() { printf 'ana@lab:~/emb$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
# put PATH: a file ana wrote in ~/emb, from stdin. Its content is shown in the lesson.
put() { lab exec "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"; }
block() { printf '##### %s\n' "$1"; }
# fresh 'command': in a terminal that has not read setup.sh's lines in ~/.bashrc.
fresh() {
  printf 'ana@lab:~/emb$ %s\n' "$*"
  runuser -u ana -- env -i HOME=/home/ana USER=ana PATH=/opt/emb-py/bin:/usr/bin:/bin \
    LC_ALL=C.UTF-8 TZ=America/Sao_Paulo bash -c "cd ~/emb; $*" 2>&1 || true
}
# at DIR 'command': typed somewhere other than ~/emb.
at() { printf 'ana@lab:%s$ %s\n' "$1" "$2"; lab exec "cd $1; $2" 2>&1 || true; }
# One capture at a time: every run rebuilds ~/emb from nothing.
exec 9>/var/tmp/emb-capture.lock; flock 9
lab reset >/dev/null

put first.py <<'EOF_FILE'
from minilm import embed

v = embed("When your refund arrives")[0]
print(v.shape, v.dtype)
print(v[:8].round(4))
print("length:", round(float((v * v).sum()) ** 0.5, 6))
print("bytes: ", v.nbytes)
EOF_FILE
put near.py <<'EOF_FILE'
import json
from minilm import embed

help = {h["id"]: h for h in map(json.loads, open("data/help.jsonl"))}
question = "how do I get my money back"
ids = ["h15", "h14", "h18", "h33", "h07", "h29"]
docs = [help[i]["title"] + ". " + help[i]["body"] for i in ids]
q = embed(question)[0]
D = embed(docs)
scores = D @ q
for i, s in sorted(zip(ids, scores), key=lambda p: -p[1]):
    print(f"{s:6.3f}  {i}  {help[i]['title']}")
EOF_FILE
put order.py <<'EOF_FILE'
from minilm import embed
from wordllama import WordLlama

a, b = "the dog bit the man", "the man bit the dog"
wl = WordLlama.load()
m = embed([a, b])
print("minilm    ", round(float(m[0] @ m[1]), 4))
w = wl.embed([a, b], norm=True)
print("wordllama ", round(float(w[0] @ w[1]), 4))
print(wl.tokenizer.encode(a, add_special_tokens=False).tokens)
EOF_FILE
put limits.py <<'EOF_FILE'
from minilm import embed

pairs = [
    ("I want a refund", "I do not want a refund"),
    ("I want a refund", "Please give me my money back"),
    ("How to return a book", "Como devolver um livro"),
    ("How to return a book", "How to return a lamp"),
]
for a, b in pairs:
    v = embed([a, b])
    print(f"{float(v[0] @ v[1]):6.3f}  {a!r} / {b!r}")
EOF_FILE
put pca.py <<'EOF_FILE'
import json
import numpy as np
from minilm import embed

help = [h for h in map(json.loads, open("data/help.jsonl"))
        if h["lang"] == "en" and h["category"] in ("shipping", "payments", "ebooks")]
V = embed([h["title"] for h in help])
X = V - V.mean(axis=0)
U, S, Wt = np.linalg.svd(X, full_matrices=False)
P = X @ Wt[:2].T
print(f"kept {(S[:2]**2).sum() / (S**2).sum():.3f} of the variance")
for h, (x, y) in zip(help, P):
    print(f"{h['id']} {h['category']:9} {x:7.3f} {y:7.3f}  {h['title']}")
EOF_FILE

block setup
lab exec 'rm -rf ~/.venvs/emb ~/models ~/.cache/wordllama ~/.cache/pip; sed -i "/^# embeddings course$/,+3d" ~/.bashrc'
on 'bash setup.sh'
on 'du -sh ~/.venvs/emb ~/models ~/.cache/pip'

block check
on 'python --version'
on 'python -c "from minilm import embed; print(embed(\"hello\").shape)"'
on 'psql -Atc "SELECT current_user, current_database()"'

block wc
on 'wc -l data/help.jsonl data/queries.jsonl data/tickets.jsonl'

block fail-pip
fresh 'pip install numpy'

block fail-venv
DEBIAN_FRONTEND=noninteractive apt-get remove -y -q python3.12-venv >/dev/null 2>&1
fresh 'python3 -m venv ~/.venvs/try'
DEBIAN_FRONTEND=noninteractive apt-get install -y -q python3-venv >/dev/null 2>&1
lab exec 'rm -rf ~/.venvs/try'

block fail-pg
pg_ctlcluster 16 main stop
on 'psql -c "SELECT 1"'
pg_ctlcluster 16 main start 9>&-   # the server must not inherit the lock

block fail-vector
DEBIAN_FRONTEND=noninteractive apt-get remove -y -q postgresql-16-pgvector >/dev/null 2>&1
on 'psql -c "CREATE EXTENSION vector"'
DEBIAN_FRONTEND=noninteractive apt-get install -y -q postgresql-16-pgvector >/dev/null 2>&1
on 'psql -c "CREATE EXTENSION vector"'

block fail-module
at '~' 'python -c "from minilm import embed"'

block grep
on 'grep -i "money back" data/help.jsonl'
on 'grep -ci "refund" data/help.jsonl'

block first
on 'python first.py'

block near
on 'python near.py'

block pca
on 'python pca.py'

block order
on 'python order.py'

block limits
on 'python limits.py'
