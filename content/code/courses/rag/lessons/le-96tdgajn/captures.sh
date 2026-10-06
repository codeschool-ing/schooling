#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of rag, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# The programs are the ones the sections show, written into ~/rag by `put`.
# Nothing is staged. Every reply comes from extract-1, the lab's stand-in
# generator, which is not a language model (lab/labgen.py says what it does);
# every similarity was computed on this machine with all-MiniLM-L6-v2.
#
# Recorded on Ubuntu 24.04, Python 3.11, PostgreSQL 16 with pgvector 0.6.0,
# TZ=America/Sao_Paulo, on 2026-10-06.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@lab:~/rag$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
put() { lab exec "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"; }
block() { printf '##### %s\n' "$1"; }
exec 9>/var/tmp/rag-capture.lock; flock 9
put chunking.py <<'EOF_FILE'
import glob
import re

import numpy as np
from minilm import embed


def load():
    """{id: (metadata, body)} for every document, the front matter read into a dict."""
    docs = {}
    for path in sorted(glob.glob("data/docs/*.md")):
        head, body = open(path).read().split("\n---\n", 1)
        meta = dict(line.split(": ", 1) for line in head.splitlines()[1:])
        docs[meta["id"]] = (meta, body.strip())
    return docs


def fixed(text, size, overlap=0):
    """Every SIZE words, starting again OVERLAP words before the last cut."""
    words = text.split()
    step = size - overlap
    return [" ".join(words[i:i + size]) for i in range(0, max(len(words) - overlap, 1), step)]


def sections(text):
    """(heading path, body) for every '## ' section, the document's title first."""
    title = re.search(r"^# (.+)$", text, re.M).group(1)
    out = []
    for part in re.split(r"\n(?=## )", text)[1:]:
        heading, _, body = part.partition("\n")
        out.append((f"{title} > {heading[3:]}", body.strip()))
    return out


def structured(text, size):
    """Inside each section, whole paragraphs packed together up to SIZE words."""
    chunks = []
    for path, body in sections(text):
        pack = []
        for para in re.split(r"\n\s*\n", body):
            if pack and len(" ".join(pack + [para]).split()) > size:
                chunks.append((path, "\n\n".join(pack)))
                pack = []
            pack.append(para)
        if pack:
            chunks.append((path, "\n\n".join(pack)))
    return chunks


def sentences(text):
    flat = " ".join(line for line in text.splitlines() if not line.startswith("#"))
    return [s for s in re.split(r"(?<=[.!?])(?<!\b\d\.)\s+(?=[A-Z0-9])", " ".join(flat.split())) if s]


def semantic(text, quantile=0.25):
    """Cut between two sentences wherever their similarity is in the lowest QUANTILE."""
    sents = sentences(text)
    v = embed(sents)
    sim = (v[:-1] * v[1:]).sum(axis=1)
    cut = np.quantile(sim, quantile)
    chunks, start = [], 0
    for i, s in enumerate(sim):
        if s <= cut:
            chunks.append(" ".join(sents[start:i + 1]))
            start = i + 1
    chunks.append(" ".join(sents[start:]))
    return chunks
EOF_FILE
put truncation.py <<'EOF_FILE'
from chunking import load
from minilm import embed, pieces

meta, body = load()["returns-policy"]
print("pieces in the whole policy:", len(pieces(body)))
words = body.split()
keep = max(k for k in range(1, len(words) + 1) if len(pieces(" ".join(words[:k]))) <= 256)
print(f"words the model reads: {keep} of {len(words)}")
whole, prefix, extra = embed([body, " ".join(words[:keep]), body + " Returns are never accepted."])
print(f"similarity, whole policy and its first {keep} words: {whole @ prefix:.4f}")
print(f"similarity, whole policy and the policy plus a sentence at the end: {whole @ extra:.4f}")
EOF_FILE
put boundaries.py <<'EOF_FILE'
import sys

from chunking import fixed, load

size, overlap = int(sys.argv[1]), int(sys.argv[2])
meta, body = load()["returns-policy"]
chunks = fixed(body, size, overlap)
print(f"{len(chunks)} chunks of {size} words, {overlap} overlapping")
for i in (3, 4, 5):
    words = chunks[i].split()
    print(f"chunk {i} starts: {' '.join(words[:9])} ...")
    print(f"chunk {i} ends:   ... {' '.join(words[-9:])}")
EOF_FILE
put structure.py <<'EOF_FILE'
from chunking import load, structured

meta, body = load()["returns-policy"]
chunks = structured(body, 120)
print(len(chunks), "chunks")
for path, text in chunks[:6]:
    print(f"{len(text.split()):4} words  {path}")
print()
print(chunks[5][1])
EOF_FILE
put boundaries_semantic.py <<'EOF_FILE'
from chunking import load, semantic

meta, body = load()["returns-policy"]
for i, chunk in enumerate(semantic(body), 1):
    print(f"{i:2} {len(chunk.split()):4} words  {' '.join(chunk.split()[:9])} ...")
EOF_FILE
put compare.py <<'EOF_FILE'
import json

import tiktoken
from chunking import fixed, load, sections, semantic, structured
from minilm import embed

enc = tiktoken.get_encoding("cl100k_base")
docs = load()
questions = [q for q in map(json.loads, open("data/eval.jsonl")) if q["facts"]]
norm = lambda t: " ".join(t.split())
qv = embed([q["question"] for q in questions])

strategies = {
    "fixed, 30 words": lambda b: fixed(b, 30),
    "fixed, 60 words": lambda b: fixed(b, 60),
    "fixed, 60 + 15 overlap": lambda b: fixed(b, 60, 15),
    "fixed, 120 words": lambda b: fixed(b, 120),
    "fixed, 240 words": lambda b: fixed(b, 240),
    "sections": lambda b: [t for _, t in sections(b)],
    "structured, 60 words": lambda b: [t for _, t in structured(b, 60)],
    "structured, 120 words": lambda b: [t for _, t in structured(b, 120)],
    "semantic": semantic,
}
print(f"{'strategy':24} {'chunks':>6} {'words':>6} {'found':>6} {'tokens':>7}")
for name, cut in strategies.items():
    chunks = [c for _, body in docs.values() for c in cut(body)]
    v = embed(chunks)
    found, tokens = 0, 0
    for q, scores in zip(questions, qv @ v.T):
        top = [chunks[i] for i in scores.argsort()[::-1][:3]]
        found += any(f in norm(t) for t in top for f in q["facts"])
        tokens += len(enc.encode("\n".join(top)))
    mean = sum(len(c.split()) for c in chunks) / len(chunks)
    print(f"{name:24} {len(chunks):6} {mean:6.0f} {found:3}/{len(questions)} {tokens / len(questions):7.0f}")
EOF_FILE
put small_to_big.py <<'EOF_FILE'
import json

import tiktoken
from chunking import load, sections, sentences
from minilm import embed

enc = tiktoken.get_encoding("cl100k_base")
questions = [q for q in map(json.loads, open("data/eval.jsonl")) if q["facts"]]
norm = lambda t: " ".join(t.split())

# Index sentences, but remember which section each came from.
parents, small = [], []
for _, body in load().values():
    for path, text in sections(body):
        parents.append(text)
        small += [(s, len(parents) - 1) for s in sentences(text)]
v = embed([s for s, _ in small])

found, tokens = 0, 0
for q in questions:
    scores = v @ embed(q["question"])[0]
    keep = []
    for i in scores.argsort()[::-1]:
        if small[i][1] not in keep:
            keep.append(small[i][1])
        if len(keep) == 3:
            break
    context = [parents[p] for p in keep]
    found += any(f in norm(t) for t in context for f in q["facts"])
    tokens += len(enc.encode("\n".join(context)))
print(f"sentences indexed: {len(small)}, sections returned: 3 per question")
print(f"found: {found}/{len(questions)}  tokens: {tokens / len(questions):.0f}")
EOF_FILE

block truncation
on 'python truncation.py'
block fixed
on 'python boundaries.py 60 0'
block overlap
on 'python boundaries.py 60 15'
block structure
on 'python structure.py'
block semantic
on 'python boundaries_semantic.py'
block compare
on 'python compare.py'
block small
on 'python small_to_big.py'
