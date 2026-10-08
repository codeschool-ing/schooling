#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of ai-dev, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo bash captures.sh            # builds the lab from nothing, then records
#
# It starts by removing Ollama, its models and ana, and builds them again with
# the steps lesson 1 shows, so that the setup sections record a real first
# install, and the failures a student meets on the way: the installer without
# zstd, Ollama installed and not running, pip outside the environment, the
# environment not active, a download the network refused, and the server
# stopped under a program.
#
# THE MODEL'S REPLIES ARE NOT REPEATABLE. Everything sent to llama3.2:3b
# through `ollama run` or an SDK is drawn at random with Ollama's defaults, so a
# rerun words them differently; the lesson says so where it quotes one. What IS
# repeatable on this machine: the probabilities next.py prints (no draw is
# made), generate.py at a fixed seed, tiktoken, and WordLlama.
#
#   model    llama3.2:3b (a80c4f17acd5) and llama3.2:1b (baf6a787fdff),
#            pulled from registry.ollama.ai by Ollama 0.40.0
#   taken    2026-10-07, on 4 cores and 15 GB with no GPU
#
# A line that starts with ana@dev:~$ or ana@dev:~/shop$ is what ana typed and
# what it printed. What is STAGED rather than typed, and not shown: the lab's
# own steps (lab.sh), and the files ana wrote (put below), each of which a
# lesson shows whole; put refuses one that no lesson shows byte for byte.
#
# pytest ends with how long its run took, "8 passed in 0.72s". That figure is
# measured, not written, and a rerun moves it by a few hundredths of a second.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh

quiet lab purge
quiet apt-get remove -y zstd
quiet lab user

block fails-zstd
home 'curl -fsSL https://ollama.com/install.sh -o install-ollama.sh'
home 'sh install-ollama.sh'

quiet lab install_ollama
block fails-not-running
home 'ollama --version'
home 'ollama list'

quiet lab serve
block fails-serve-twice
home 'ollama serve'

quiet lab install_models
block installing-ollama
home 'ollama --version'
home 'ollama list'
homeq 'ollama run llama3.2:3b "Say hello to a developer in one short sentence."'
home 'ollama ps'

quiet lab pull_small
block your-machine-small
homeq 'ollama run llama3.2:1b "Say hello to a developer in one short sentence."'
home 'ollama ps'
home 'ollama list'
block your-machine-speed
for m in llama3.2:3b llama3.2:1b; do
  home "curl -s http://127.0.0.1:11434/api/generate -d '{\"model\": \"$m\", \"prompt\": \"Explain in two sentences what a unit test is.\", \"stream\": false}' | python3 -c 'import json, sys; r = json.load(sys.stdin); print(r[\"eval_count\"], \"tokens in\", round(r[\"eval_duration\"] / 1e9, 1), \"seconds\")'"
done

block fails-pip-outside
bare 'python3 -m pip install anthropic==1.11.0'

quiet lab install_python
block fails-not-active
bare 'python3 -c "import anthropic"'

block fails-network
home "python -c 'import tiktoken; tiktoken.get_encoding(\"o200k_base\")' 2>&1 | tail -n 1"
home "python -c 'from wordllama import WordLlama; WordLlama.load()' 2>&1 | tail -n 1"

quiet lab build_tokenizer
quiet lab build_embeddings
block installing-sdk
home 'python --version'
home 'env | grep -E "_(BASE_URL|API_KEY)=" | sort'
home "python -c 'import anthropic; r = anthropic.Anthropic().messages.create(model=\"llama3.2:3b\", max_tokens=40, messages=[{\"role\": \"user\", \"content\": \"Reply with the word ready.\"}]); print(r.stop_reason, r.usage.output_tokens, repr(r.content[0].text))'"

python3 "$COURSE/lab/fences.py" block the-project.md '# make-shop.sh DIR: the shop project as the course starts it' |
  IN_HOME=1 lab exec ana 'cat > make-shop.sh'
block the-project
home 'bash make-shop.sh ~/shop'
on 'git log --oneline'
on 'python -m pytest -q'

block fails-stopped
quiet pkill -x ollama
sleep 1
on "python -c 'import anthropic; anthropic.Anthropic().messages.create(model=\"llama3.2:3b\", max_tokens=40, messages=[{\"role\": \"user\", \"content\": \"Hello\"}])' 2>&1 | tail -n 1"
quiet lab serve

put scratch/next.py <<'PY'
import json
import math
import sys
import urllib.request

# Ollama's own API rather than an SDK: it can return the probabilities the model
# gave each candidate for the next token, which no provider's API shows.
body = {"model": "llama3.2:3b", "prompt": sys.argv[1], "raw": True, "stream": False,
        "logprobs": True, "top_logprobs": 5, "options": {"num_predict": 1}}
request = urllib.request.Request("http://127.0.0.1:11434/api/generate", json.dumps(body).encode())
step = json.load(urllib.request.urlopen(request))["logprobs"][0]
for candidate in step["top_logprobs"]:
    print(f"{math.exp(candidate['logprob']):6.1%}  {candidate['token']!r}")
PY
put scratch/generate.py <<'PY'
import argparse
import json
import urllib.request

ap = argparse.ArgumentParser()
ap.add_argument("prompt")
ap.add_argument("--tokens", type=int, default=20)
ap.add_argument("--temperature", type=float, default=0.8)
ap.add_argument("--top-p", type=float, default=1.0)
ap.add_argument("--seed", type=int, default=1)
a = ap.parse_args()

# "raw" sends the text as it is, so the model continues it rather than replying to it.
body = {"model": "llama3.2:3b", "prompt": a.prompt, "raw": True, "stream": False,
        "options": {"num_predict": a.tokens, "temperature": a.temperature,
                    "top_p": a.top_p, "top_k": 0, "seed": a.seed}}
request = urllib.request.Request("http://127.0.0.1:11434/api/generate", json.dumps(body).encode())
print(a.prompt + json.load(urllib.request.urlopen(request))["response"])
PY
put scratch/tokens.py <<'PY'
import sys

import tiktoken

enc = tiktoken.get_encoding(sys.argv[1])
for line in sys.stdin:
    text = line.rstrip("\n")
    ids = enc.encode(text)
    print(f"{len(ids):3} tokens  {len(text):3} chars  " + "|".join(enc.decode([i]) for i in ids))
PY
put scratch/similar.py <<'PY'
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
on 'python scratch/next.py "Return the"'
on 'python scratch/next.py "Return the number of"'
on 'python scratch/next.py "If the file does not"'
block next-token-loop
on 'python scratch/generate.py "Return the" --tokens 40 --temperature 0'

block tokens
on 'printf "%s\n" "Tokenisation is not splitting on spaces." "Tokenization is not splitting on spaces." "A tokenização não divide o texto nos espaços." "def total(self) -> int:" "        return self.subtotal()" "1290 12900 129000 1290000" | python scratch/tokens.py o200k_base'
block tokens-encodings
on "python -c 'import tiktoken; [print(m, tiktoken.encoding_name_for_model(m)) for m in (\"gpt-4\", \"gpt-4o\", \"gpt-5\")]'"
on 'printf "%s\n" "A tokenização não divide o texto nos espaços." "        return self.subtotal()" | python scratch/tokens.py cl100k_base'
block tokens-files
on "python -c 'import tiktoken, pathlib; e = tiktoken.get_encoding(\"o200k_base\"); [print(f\"{len(e.encode(p.read_text())):5} tokens {len(p.read_text().split()):5} words  {p}\") for p in sorted(pathlib.Path(\"shop\").glob(\"*.py\"))]'"
on "python -c 'import tiktoken, pathlib; t = pathlib.Path(\"CONVENTIONS.md\").read_text(); print(len(t.split()), \"words,\", len(tiktoken.get_encoding(\"o200k_base\").encode(t)), \"tokens\")'"

block sampling
for t in 0 0.7 1.5; do
  on "python scratch/generate.py \"The default value is\" --tokens 16 --temperature $t --seed 8"
done
block sampling-seeds
for s in 1 2 3; do
  on "python scratch/generate.py \"The default value is\" --tokens 16 --temperature 0.7 --seed $s"
done
block sampling-top-p
on 'python scratch/generate.py "The default value is" --tokens 16 --temperature 1.5 --top-p 0.5 --seed 8'
block sampling-apis
put scratch/knobs.py <<'PY'
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
on 'python scratch/knobs.py'

block embeddings-vector
on "python -c 'from wordllama import WordLlama; v = WordLlama.load().embed([\"the cart total is wrong\"]); print(v.shape, v.dtype); print(v[0][:6].round(3))'"
block embeddings-similar
on 'printf "%s\n" "the cart total is wrong" "checkout adds up the order incorrectly" "the sum shown at checkout is too high" "the cart page loads slowly" "our office opens at nine" | python scratch/similar.py'
block embeddings-limits
on 'printf "%s\n" "the coupon was accepted" "the coupon was not accepted" "the coupon was refused" "the voucher was accepted" | python scratch/similar.py'

block context-turns
put scratch/turns.py <<'PY'
import anthropic

client = anthropic.Anthropic()
history = []
for question in ["My cart has three mugs.", "Add a lamp to it.", "How many items are in it now?"]:
    history.append({"role": "user", "content": question})
    r = client.messages.create(model="llama3.2:3b", max_tokens=60, system="Answer in one short sentence.",
                               messages=history)
    reply = r.content[0].text
    sent = r.usage.input_tokens + (r.usage.cache_read_input_tokens or 0)
    print(f"turn {len(history) // 2 + 1}: {len(history)} messages, {sent} input tokens")
    print(f"  {reply}")
    history.append({"role": "assistant", "content": reply})

print("what the third request carried:")
for message in history[:-1]:
    print(f"  {message['role']:9} | {message['content']}")
PY
on 'python scratch/turns.py'
onq 'ollama run llama3.2:3b "How many items are in it now?"'

block knowledge
on 'python scratch/next.py "The capital of France is"'
on 'python scratch/next.py "The capital of the Republic of Veldoria is"'
on 'python scratch/generate.py "The capital of the Republic of Veldoria is" --tokens 30 --temperature 0'
onq 'ollama run llama3.2:3b "What is the capital of the Republic of Veldoria?"'
onq "ollama run llama3.2:3b \"In Python's standard library, which function in the statistics module computes the harmonic median? Answer with one line of code.\""
