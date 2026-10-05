#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of ai-models, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   bash ../../lab.sh up        # once: the machine, the SDKs, the documents
#   bash captures.sh
#
# A line that starts with ana@desk:~/desk$ is what ana typed and what it
# printed. STAGED rather than typed, and not shown in the lesson: the lab
# itself (lab.sh reset) and lab/template.py, which the lesson shows in full.
#
# Nothing in this lesson talks to a model. What it quotes are Meta's own
# documents for Llama 3.1, read by sources.py at the commit it pins.
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

block pretraining
on 'sources quote llama3.1-card "collection of pretrained|~15 trillion"'

block base-and-tuned
on "sources quote llama3.1-prompt-format '^<.begin_of_text.>Color|^ red, orange'"
on "sources quote llama3.1-prompt-format 'end_of_text...: Model|End of turn'"

put lab/template.py <<'PY'
import json


def render(messages):
    """A conversation as Llama 3.1 reads it, from Meta's prompt_format.md."""
    out = "<|begin_of_text|>"
    for m in messages:
        out += f"<|start_header_id|>{m['role']}<|end_header_id|>\n\n{m['content']}<|eot_id|>"
    return out + "<|start_header_id|>assistant<|end_header_id|>\n\n"


case = json.loads(open("cases/triage.jsonl").readline())
print(render([{"role": "system", "content": open("prompts/triage.txt").read().strip()},
              {"role": "user", "content": case["text"]}]))
PY
block chat-template
on 'python lab/template.py'

block model-card
on 'sources quote llama3.1-card "^\*\*supported languages|^\*\*Intended Use Cases"'

block cutoff
on 'sources quote llama3.1-card "data freshness"'
