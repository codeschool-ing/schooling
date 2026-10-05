#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of ai-models, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash ../../lab.sh up        # once: the machine, the SDKs, the documents
#   bash captures.sh
#
# A line that starts with ana@desk:~/desk$ is what ana typed and what it
# printed. STAGED rather than typed: the lab itself (lab.sh reset) and
# lab/card.py, which the lesson shows in full.
#
# Nothing here talks to a model. The comparison table is Anthropic's own models
# page, read by `sources fetch` on the date it prints; the prices and cache
# fields are LiteLLM's sheet at its pinned commit.
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

put lab/card.py <<'PY'
import subprocess
import sys

page = subprocess.run(["sources", "lines", "claude-models", "1", "300"], capture_output=True, text=True).stdout
print(page.splitlines()[0])
lines = [line.split("| ", 1)[1] if "| " in line else "" for line in page.splitlines()[1:]]
table = lines.index("Feature")  # the comparison table starts here
names = [lines[table + 1 + 2 * k] for k in range(4)]


def row(label):
    """The cells that follow a row's label in the table: one per model, two for prices."""
    i = lines.index(label, table)
    cells = lines[i + 1:i + 1 + (8 if label == "Pricing" else 4)]
    return [" ".join(cells[k:k + 2]) for k in range(0, 8, 2)] if label == "Pricing" else cells


wanted = sys.argv[2:] if len(sys.argv) > 2 else ["Claude API ID", "Context window", "Max output"]
for k, name in enumerate(names):
    if sys.argv[1] in ("all", name):
        print(name)
        for label in wanted:
            print(f"  {label:27} {row(label)[k]}")
PY

block lineup
on 'python lab/card.py all "Claude API ID" "Comparative latency" Pricing'
on 'sheet provider anthropic | grep -v -- "-20[0-9]*  "'

block dates
on 'python lab/card.py all "Reliable knowledge cutoff" Retirement'
on 'sheet retiring --provider anthropic'

block platforms
on 'python lab/card.py "Claude Haiku 4.5" "Claude API ID" "Claude API alias" "Amazon Bedrock ID" "Google Cloud ID" "Microsoft Foundry ID"'

block features
on 'python lab/card.py all Thinking "Default effort" "Context window" "Max output"'
on 'sheet show claude-haiku-4-5 | grep -E "^(input_cost_per_token|cache|prompt_cache|output_cost_per_token)"'
on 'sheet show claude-sonnet-5-5 | grep -E "^prompt_cache_min"'
