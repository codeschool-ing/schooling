#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of ai-dev, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo bash ../../lab.sh up        # once: the machine, the SDKs, labllm
#   sudo bash captures.sh
#
# A line that starts with ana@dev:~/shop$ is what ana typed, in her project,
# and what it printed. What is STAGED rather than typed, and not shown in the
# lesson: the lab itself (lab.sh reset), and the files ana wrote (put below),
# whose contents the lesson shows in full.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@dev:~/shop$ %s\n' "$*"; lab exec ana "$*" 2>&1 || true; }
put() { lab exec ana "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"; }
block() { printf '##### %s\n' "$1"; }

lab reset >/dev/null

put lab/next.py <<'PY'
import sys

from tinylm import TinyLM

lm = TinyLM.load("/opt/aidev/share/tiny.json")
top, used = lm.top(sys.argv[1], k=5)
print(f"context used: {used} tokens")
for text, p in top:
    print(f"{p:6.1%}  {text!r}")
PY
put lab/generate.py <<'PY'
import argparse

from tinylm import TinyLM

ap = argparse.ArgumentParser()
ap.add_argument("prompt")
ap.add_argument("--tokens", type=int, default=20)
ap.add_argument("--temperature", type=float, default=1.0)
ap.add_argument("--top-p", type=float, default=1.0)
ap.add_argument("--seed", type=int, default=1)
a = ap.parse_args()

lm = TinyLM.load("/opt/aidev/share/tiny.json")
pieces = lm.generate(a.prompt, a.tokens, a.temperature, a.top_p, a.seed)
print(a.prompt + "".join(pieces))
PY
put lab/tokens.py <<'PY'
import sys

import tiktoken

enc = tiktoken.get_encoding(sys.argv[1])
for line in sys.stdin:
    text = line.rstrip("\n")
    ids = enc.encode(text)
    print(f"{len(ids):3} tokens  {len(text):3} chars  " + "|".join(enc.decode([i]) for i in ids))
PY
put lab/similar.py <<'PY'
import sys

import numpy as np
from wordllama import WordLlama

wl = WordLlama.load()
query, *texts = [line.strip() for line in sys.stdin if line.strip()]
vectors = wl.embed([query] + texts, norm=True)
scores = vectors[1:] @ vectors[0]
print(f"query: {query}")
for i in np.argsort(-scores):
    print(f"  {scores[i]:+.3f}  {texts[i]}")
PY

block next-token
on 'python lab/next.py "Return the"'
on 'python lab/next.py "Return the number of"'
on 'python lab/next.py "If the file does not"'
block next-token-loop
on 'python lab/generate.py "Return the" --tokens 40 --temperature 0'

block tokens
on 'printf "%s\n" "Tokenisation is not splitting on spaces." "Tokenization is not splitting on spaces." "A tokenização não divide o texto nos espaços." "def total(self) -> int:" "        return self.subtotal()" "1290 12900 129000 1290000" | python lab/tokens.py o200k_base'
block tokens-encodings
on "python -c 'import tiktoken; [print(m, tiktoken.encoding_name_for_model(m)) for m in (\"gpt-4\", \"gpt-4o\", \"gpt-5\")]'"
on 'printf "%s\n" "A tokenização não divide o texto nos espaços." "        return self.subtotal()" | python lab/tokens.py cl100k_base'
block tokens-files
on "python -c 'import tiktoken, pathlib; e = tiktoken.get_encoding(\"o200k_base\"); [print(f\"{len(e.encode(p.read_text())):5} tokens {len(p.read_text().split()):5} words  {p}\") for p in sorted(pathlib.Path(\"shop\").glob(\"*.py\"))]'"

block sampling
for t in 0 0.7 1.5; do
  on "python lab/generate.py \"The default value is\" --tokens 16 --temperature $t --seed 7"
done
block sampling-seeds
for s in 1 2 3; do
  on "python lab/generate.py \"The default value is\" --tokens 16 --temperature 0.7 --seed $s"
done
block sampling-apis
put lab/knobs.py <<'PY'
import inspect

import anthropic
import openai
from google.genai import types

calls = {
    "anthropic messages.create": inspect.signature(anthropic.Anthropic().messages.create).parameters,
    "openai chat.completions.create": inspect.signature(openai.OpenAI().chat.completions.create).parameters,
    "google GenerateContentConfig": types.GenerateContentConfig.model_fields,
}
for name, params in calls.items():
    have = [k for k in ("temperature", "top_p", "top_k", "seed") if k in params]
    print(f"{name:32} {' '.join(have) or '(none of them)'}")
PY
on 'python lab/knobs.py'
block sampling-top-p
on 'python lab/generate.py "The default value is" --tokens 16 --temperature 1.5 --top-p 0.5 --seed 7'

block embeddings-vector
on "python -c 'from wordllama import WordLlama; v = WordLlama.load().embed([\"the cart total is wrong\"]); print(v.shape, v.dtype); print(v[0][:6].round(3))'"
block embeddings-similar
on 'printf "%s\n" "the cart total is wrong" "checkout adds up the order incorrectly" "the sum shown at checkout is too high" "the cart page loads slowly" "our office opens at nine" | python lab/similar.py'
block embeddings-limits
on 'printf "%s\n" "the coupon was accepted" "the coupon was not accepted" "the coupon was refused" "the voucher was accepted" | python lab/similar.py'

block context-turns
put lab/turns.py <<'PY'
import anthropic

client = anthropic.Anthropic()
history = []
for question in ["My cart has three mugs.", "Add a lamp to it.", "How many items are in it now?"]:
    history.append({"role": "user", "content": question})
    n = client.messages.count_tokens(model="tiny-1", messages=history).input_tokens
    print(f"turn {len(history) // 2 + 1}: {len(history)} messages, {n} input tokens")
    history.append({"role": "assistant", "content": "(the reply would go here)"})
PY
on 'python lab/turns.py'
on "tail -n 1 /var/log/labllm/requests.jsonl | python -c 'import json, sys; [print(m[\"role\"], \"|\", m[\"content\"]) for m in json.load(sys.stdin)[\"request\"][\"messages\"]]'"

block knowledge
on 'python lab/next.py "The capital of France is"'
on 'python lab/generate.py "The capital of France is" --tokens 14 --temperature 0'
on 'python lab/next.py "colourless green ideas"'

block the-lab
on 'python --version'
on "python -c 'import tiktoken; t = open(\"/opt/aidev/share/corpus.txt\").read(); print(len(t.split()), \"words,\", len(tiktoken.get_encoding(\"o200k_base\").encode(t)), \"tokens\")'"
on "python -c 'import tiktoken; print(tiktoken.get_encoding(\"o200k_base\").n_vocab, \"tokens in o200k_base\")'"
on 'pip list 2>/dev/null | grep -iE "^(anthropic|openai|google-genai|mcp|tiktoken|wordllama|numpy|pytest|hypothesis) "'
on 'git log --oneline'
on 'python -m pytest -q'
on 'env | grep -E "_(BASE_URL|API_KEY)=" | sort'
on 'curl -s http://127.0.0.1:8400/v1/messages -H "x-api-key: $ANTHROPIC_API_KEY" -H "anthropic-version: 2023-06-01" -H "content-type: application/json" -d "{\"model\": \"tiny-1\", \"max_tokens\": 12, \"messages\": [{\"role\": \"user\", \"content\": \"Return the\"}]}" | python -m json.tool'
