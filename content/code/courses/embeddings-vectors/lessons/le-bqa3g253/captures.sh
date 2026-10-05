#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of embeddings-vectors, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# The programs are the ones the sections show, written into ~/emb by `put`.
# Nothing is staged.
#
# NOT RUN: st.py, the sentence-transformers version, is shown in the lesson
# and never written or executed here. huggingface.co, where the library
# downloads the model, refused this machine (the `hf` block records the
# answer), and PyTorch's package index was out of reach too. The same weights
# run instead through ONNX: Chroma's export of all-MiniLM-L6-v2, which lab.sh
# fetched and checked against its SHA-256. Chroma's DefaultEmbeddingFunction
# finds the same files in ~/.cache/chroma, put there when the lab was set up.
#
# Timings were taken while other work ran on the same four processors; they
# are what this run printed, and another run prints other numbers.
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

put local.py <<'EOF_FILE'
from minilm import embed

vectors = embed(["When your refund arrives", "Tracking a parcel"])
print(vectors.shape)
print(round(float(vectors[0] @ vectors[1]), 4))
EOF_FILE
put inside.py <<'EOF_FILE'
import os
import numpy as np
import onnxruntime
from tokenizers import Tokenizer
from chromadb.utils.embedding_functions import DefaultEmbeddingFunction
import minilm

DIR = os.environ["MINILM_DIR"]
texts = ["When your refund arrives", "A parcel marked as delivered that never arrived"]
tok = Tokenizer.from_file(os.path.join(DIR, "tokenizer.json"))
tok.enable_truncation(256)
tok.enable_padding(pad_id=0, pad_token="[PAD]")
enc = tok.encode_batch(texts)
print(enc[0].tokens)
print(enc[0].attention_mask)
ids = np.array([e.ids for e in enc], dtype=np.int64)
mask = np.array([e.attention_mask for e in enc], dtype=np.int64)
model = onnxruntime.InferenceSession(os.path.join(DIR, "model.onnx"))
hidden = model.run(None, {"input_ids": ids, "attention_mask": mask,
                          "token_type_ids": np.zeros_like(ids)})[0]
print("one vector per piece:", hidden.shape)
m = mask[:, :, None].astype(np.float32)
pooled = (hidden * m).sum(axis=1) / m.sum(axis=1)
naive = hidden.mean(axis=1)
print("pooled:", pooled.shape)
v = pooled / np.linalg.norm(pooled, axis=1, keepdims=True)
n = naive / np.linalg.norm(naive, axis=1, keepdims=True)
print("padding averaged in, first text:", round(float(v[0] @ n[0]), 4))
chroma = np.array(DefaultEmbeddingFunction()(texts))
print("largest difference from minilm.py:", np.abs(v - minilm.embed(texts)).max())
print("largest difference from Chroma:   ", np.abs(v - chroma).max())
EOF_FILE
put length.py <<'EOF_FILE'
import json
import os
import numpy as np
from tokenizers import Tokenizer
from chromadb.utils.embedding_functions import DefaultEmbeddingFunction
from minilm import embed, pieces

help = [json.loads(line) for line in open("data/help.jsonl")]
def count(h):
    text = h["title"] + ". " + h["body"]
    return len(text.split()), len(pieces(text))
for h in sorted(help, key=lambda h: -count(h)[1])[:4]:
    print(h["id"], h["lang"], "%d words, %d pieces" % count(h))
long = " ".join(h["body"] for h in help if h["category"] == "shipping")
print("shipping bodies joined:", len(pieces(long)), "pieces")
tok = Tokenizer.from_file(os.path.join(os.environ["MINILM_DIR"], "tokenizer.json"))
tok.no_truncation()
start, end = tok.encode(long).offsets[254]
print("the last piece read:", repr(long[start:end]), "in", repr(long[end - 40:end + 30]))
a = embed(long)
b = embed(long + " Every word after the limit is ignored, however important.")
c = embed("Refunds go back to the card you paid with. " + long)
print("a sentence added at the end:  ", np.abs(a - b).max())
print("a sentence added at the start:", np.abs(a - c).max())
chroma = np.array(DefaultEmbeddingFunction()([long]))
print("Chroma, same long text:", chroma.shape, np.abs(chroma - a).max())
EOF_FILE
put bench.py <<'EOF_FILE'
import json
import numpy as np
from minilm import embed
from wordllama import WordLlama

help = [json.loads(line) for line in open("data/help.jsonl")]
queries = [json.loads(line) for line in open("data/queries.jsonl")]
ids = [h["id"] for h in help]
docs = [h["title"] + ". " + h["body"] for h in help]
wl = WordLlama.load()
models = {
    "all-MiniLM-L6-v2": embed,
    "WordLlama": lambda texts: wl.embed(texts, norm=True),
}
for name, f in models.items():
    D, Q = f(docs), f([q["text"] for q in queries])
    top = np.argsort(-(Q @ D.T), axis=1)[:, :3]
    first = [ids[t[0]] in q["relevant"] for t, q in zip(top, queries)]
    three = [any(ids[j] in q["relevant"] for j in t) for t, q in zip(top, queries)]
    wrong = [q["id"] for q, ok in zip(queries, first) if not ok]
    print(f"{name:17} top 1: {sum(first)}/24  top 3: {sum(three)}/24  wrong at 1: {' '.join(wrong)}")
EOF_FILE
put speed.py <<'EOF_FILE'
import json
import time
from minilm import embed
from wordllama import WordLlama

texts = [json.loads(line)["text"] for line in open("data/tickets.jsonl")]
wl = WordLlama.load()
def rate(f, items, runs=3):
    best = float("inf")
    for _ in range(runs):
        t = time.perf_counter()
        f(items)
        best = min(best, time.perf_counter() - t)
    return len(items) / best
for b in (1, 8, 32, 150):
    r = rate(lambda t: embed(t, batch=b), texts)
    print(f"all-MiniLM-L6-v2  batch {b:3}           {r:7.0f} texts/s")
r = rate(lambda t: embed(t, batch=32), sorted(texts, key=len))
print(f"all-MiniLM-L6-v2  batch  32, sorted   {r:7.0f} texts/s")
r = rate(lambda t: wl.embed(t, norm=True), texts)
print(f"WordLlama         batch  64           {r:7.0f} texts/s")
EOF_FILE

block hf
on 'curl -sS -D - -o /dev/null https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2 | head -n 2'

block files
on 'ls -l $MINILM_DIR'

block local
on 'python local.py'

block inside
on 'python inside.py'

block length
on 'python length.py'

block card
on 'jq "{vocab_size, hidden_size, num_hidden_layers, max_position_embeddings}" $MINILM_DIR/config.json'
on 'jq .model_max_length $MINILM_DIR/tokenizer_config.json'
on 'jq -c "{truncation: .truncation.max_length, padding: .padding.strategy}" $MINILM_DIR/tokenizer.json'

block bench
on 'python bench.py'

block machine
on 'nproc'
on 'grep -m1 "model name" /proc/cpuinfo'
on 'grep -n "num_threads" /opt/emb/lib/python3.11/site-packages/minilm.py'

block speed
on 'python speed.py'
