#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of ai-models, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash ../../lab.sh up        # once: the machine, the SDKs, the documents
#   bash captures.sh
#
# A line that starts with ana@desk:~/desk$ is what ana typed and what it
# printed. STAGED rather than typed: the lab itself (lab.sh reset) and
# lab/moe.py, which the lesson shows in full.
#
# Nothing here talks to a model. The model cards, the licence and the list of
# releases are Meta's own files at the commit sources.py pins; host prices are
# LiteLLM's sheet at its pinned commit. The 1,000 GB/s in moe.py is the same
# assumption about hardware lesson 3 made, and the lesson says so.
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

block generations
on "sources quote llama-skus 'description=\"Llama' | grep -o 'Llama [0-9.]* [^\"]*' | sort -u"

block moe
on 'sources lines llama4-card 23 42 | grep -E "Llama 4|Activated|Total|>[0-9]+M<"'

put lab/moe.py <<'PY'
# Llama 4's two models, from the card: billions of parameters in all, and the
# billions each token is actually computed with.
MODELS = {"Llama 4 Scout": (109, 17), "Llama 4 Maverick": (400, 17)}
BANDWIDTH = 1000  # GB/s, the same assumption as lesson 3

for name, (total, active) in MODELS.items():
    held, read = total / 2, active / 2  # gigabytes at 4 bits: half a byte per parameter
    print(f"{name:17} holds {held:5.1f} GB, reads {read:4.1f} GB a token, "
          f"ceiling about {BANDWIDTH / read:3.0f} tokens a second")
PY
on 'python lab/moe.py'

block card
on 'sources quote llama4-card "^\*\*Overview|Data Freshness|^\*\*Supported languages"'

block hosts
on 'sheet where llama-4-maverick'
