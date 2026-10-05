#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of ai-models, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash ../../lab.sh up        # once: the machine, the SDKs, the documents
#   bash captures.sh
#
# A line that starts with ana@desk:~/desk$ is what ana typed and what it
# printed. STAGED rather than typed: the lab itself (lab.sh reset) and the
# programs put below, which the lesson shows in full.
#
# WHAT IS MEASURED AND WHAT IS ASSUMED. The architecture numbers are Meta's,
# from models/sku_list.py at the commit sources.py pins, and the parameter
# counts are computed from them. Token counts come from standin's counter
# (o200k_base plus 3 a message). Prices are LiteLLM's sheet at its pinned
# commit. Three numbers are the COURSE'S ASSUMPTIONS and the lesson says so
# where it uses them: 1,000 GB/s of memory bandwidth, 400 e-mails a day, and
# $1,500 a month for a machine with a GPU.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@desk:~/desk$ %s\n' "$*"; lab exec ana "$*" 2>&1 || true; }
put() { lab exec ana "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"; }
block() { printf '##### %s\n' "$1"; }

lab reset >/dev/null

put lab/size.py <<'PY'
import re
import subprocess
import sys

src = subprocess.run(["sources", "lines", "llama-skus", "1", "330"], capture_output=True, text=True).stdout
VOCAB = 128256  # LLAMA3_VOCAB_SIZE, line 19 of sku_list.py


def arch(name):
    block = src[src.index(f'"meta-llama/{name}"'):]
    num = lambda k: float(re.search(rf'"{k}": ([0-9.]+)', block).group(1))  # noqa: E731
    return {k: num(k) for k in ("dim", "n_layers", "n_heads", "n_kv_heads", "ffn_dim_multiplier", "multiple_of")}


def parameters(a):
    dim, layers, kv = int(a["dim"]), int(a["n_layers"]), int(a["n_kv_heads"])
    head = dim // int(a["n_heads"])
    hidden = int(a["ffn_dim_multiplier"] * int(2 * 4 * dim / 3))
    hidden = int(a["multiple_of"]) * ((hidden + int(a["multiple_of"]) - 1) // int(a["multiple_of"]))
    attention = 2 * dim * dim + 2 * dim * kv * head
    feed_forward = 3 * dim * hidden
    return 2 * VOCAB * dim + layers * (attention + feed_forward + 2 * dim) + dim


def kv_bytes_per_token(a, bytes_per_value=2):
    head = int(a["dim"]) // int(a["n_heads"])
    return 2 * int(a["n_layers"]) * int(a["n_kv_heads"]) * head * bytes_per_value


GB = 1e9
bandwidth = float(sys.argv[1]) if len(sys.argv) > 1 else 1000  # GB/s, an assumption
print(f"{'model':16} {'parameters':>15} {'16-bit':>8} {'8-bit':>7} {'4-bit':>7} {'KV/token':>9} {'tok/s at 4-bit':>15}")
for name in ("Llama-3.1-8B", "Llama-3.1-70B", "Llama-3.1-405B"):
    a = arch(name)
    p = parameters(a)
    sizes = [p * bits / 8 / GB for bits in (16, 8, 4)]
    print(f"{name:16} {p:>15,} {sizes[0]:>6.0f}GB {sizes[1]:>5.0f}GB {sizes[2]:>5.0f}GB "
          f"{kv_bytes_per_token(a) // 1024:>6}KiB {bandwidth / sizes[2]:>15.0f}")
PY

block memory
on 'sources lines llama-skus 235 246'
on 'python lab/size.py'

block throughput
on 'python lab/size.py 1000 | cut -c1-17,76-'
on 'python lab/size.py 3000 | cut -c1-17,76-'

put lab/volume.py <<'PY'
import json

import anthropic

client = anthropic.Anthropic()
system = open("prompts/triage.txt").read()
ins, outs = [], []
for line in open("cases/triage.jsonl"):
    r = client.messages.create(model="standin-large", max_tokens=10, system=system,
                               messages=[{"role": "user", "content": json.loads(line)["text"]}])
    ins.append(r.usage.input_tokens)
    outs.append(r.usage.output_tokens)
print(f"{len(ins)} e-mails: {sum(ins) / len(ins):.1f} tokens in, {sum(outs) / len(outs):.1f} out, on average")
PY

put lab/breakeven.py <<'PY'
import json
import sys

sheet = json.load(open("/opt/aimodels/share/litellm-21881c57.json"))
model, machine = sys.argv[1], float(sys.argv[2])  # the machine's monthly cost is an assumption
tokens_in, tokens_out, per_day = 59, 2, 400  # volume.py, rounded up
price = sheet[model]
per_request = tokens_in * price["input_cost_per_token"] + tokens_out * price["output_cost_per_token"]
print(f"{model}: ${per_request * 1e6:.0f} per million requests")
print(f"  ana's {per_day} a day: ${per_request * per_day * 30:.2f} a month")
print(f"  a ${machine:,.0f} machine pays for itself at {machine / per_request / 30:,.0f} requests a day")
PY

block break-even
on 'python lab/volume.py'
on 'python lab/breakeven.py claude-haiku-4-5 1500'
on 'python lab/breakeven.py claude-opus-5-5 1500'
