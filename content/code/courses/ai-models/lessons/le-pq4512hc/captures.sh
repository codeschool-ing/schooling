#!/usr/bin/env bash
# The terminal sessions quoted in lesson 7 of ai-models, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash ../../lab.sh up        # once: the machine, the SDKs, the documents
#   bash captures.sh
#
# A line that starts with ana@desk:~/desk$ is what ana typed and what it
# printed. STAGED rather than typed: the lab itself (lab.sh reset) and
# lab/tiered.py, which the lesson shows in full.
#
# Nothing here talks to a model. Google's own pages could not be reached from
# the machine the course was recorded on; every number is LiteLLM's sheet at
# its pinned commit, whose entries for Gemini name Google's pricing page as
# their source.
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

block lineup
on 'sheet compare gemini/gemini-3.5-flash-lite gemini/gemini-3.5-flash gemini/gemini-3.1-pro-preview gemini/gemini-flash-latest gemini/gemini-pro-latest'
on 'sheet show gemini/gemini-3.5-flash | grep -E "^(source|rpm|tpm)"'

put lab/tiered.py <<'PY'
import json
import sys

sheet = json.load(open("/opt/aimodels/share/litellm-21881c57.json"))
model, tokens_in, tokens_out = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
e = sheet[model]
rate_in, rate_out = e["input_cost_per_token"], e["output_cost_per_token"]
if tokens_in > 200_000 and "input_cost_per_token_above_200k_tokens" in e:
    # the whole request moves to the higher rate, in and out
    rate_in = e["input_cost_per_token_above_200k_tokens"]
    rate_out = e["output_cost_per_token_above_200k_tokens"]
print(f"{tokens_in:,} in at ${rate_in * 1e6:g}/M, {tokens_out:,} out at ${rate_out * 1e6:g}/M: "
      f"${tokens_in * rate_in + tokens_out * rate_out:.4f}")
PY

block price-tiers
on 'sheet show gemini/gemini-pro-latest | grep -E "^(input|output)_cost_per_token"'
on 'sheet cost gemini/gemini-pro-latest 300000 1000'
on 'sources quote litellm-cost "If input_tokens > threshold|for all token types"'
on 'python lab/tiered.py gemini/gemini-pro-latest 190000 1000; python lab/tiered.py gemini/gemini-pro-latest 210000 1000'

block modalities
on 'sheet show gemini/gemini-3.5-flash | grep -E "^(supported_|input_cost_per_audio|search_context|google_maps)"'

block access
on 'sheet where gemini-3.5-flash'
