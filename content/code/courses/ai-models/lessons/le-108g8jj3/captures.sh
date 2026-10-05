#!/usr/bin/env bash
# The terminal sessions quoted in lesson 12 of ai-models, as a script that
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
# huggingface.co could not be reached from the machine this was recorded on.
# What is read instead is Hugging Face's own source, at the commits sources.py
# pins: the list of tasks in huggingface.js and the Hub's documentation. The
# card in cards.py is ana's, written for the course, and huggingface_hub (the
# real library, at the version lab.sh pins) turns it into the metadata a Hub
# repository carries.
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

put lab/tasks.py <<'PY'
import re
import subprocess
import sys
from collections import Counter

src = subprocess.run(["sources", "lines", "hf-tasks", "1", "664"], capture_output=True, text=True).stdout
text = "\n".join(line.split("| ", 1)[1] if "| " in line else "" for line in src.splitlines()[1:])
# one entry per task: its key, its display name, and the modality it belongs to
tasks = re.findall(r'\n\t"([a-z0-9-]+)": \{\n\t\tname: "([^"]+)",.*?\n\t\tmodality: "(\w+)"', text, re.S)
print(len(tasks), "tasks:", dict(Counter(m for _, _, m in tasks).most_common()))
for key, name, modality in tasks:
    if modality == (sys.argv[1] if len(sys.argv) > 1 else "nlp"):
        print(f"  {key:32} {name}")
PY

block tasks
on 'sources quote hf-tasks "To determine which|filters at the left"'
on 'python lab/tasks.py nlp'

block the-hub
on 'python -c "import inspect, huggingface_hub as h; print(h.__version__); print(*list(inspect.signature(h.hf_hub_download).parameters)[:6], sep=chr(10))"'

put lab/cards.py <<'PY'
from huggingface_hub import ModelCard, ModelCardData

# The metadata a fine-tune of ana's would carry, if she ever published one.
data = ModelCardData(language=["en", "pt"], license="apache-2.0", base_model="Qwen/Qwen3-8B",
                     pipeline_tag="text-classification", tags=["customer-support"])
content = f"---\n{data.to_yaml()}\n---\n\n# lantern-books/email-sorter\n\nSorts a bookshop's e-mail.\n"
print(content)
card = ModelCard(content)
print("read back:", card.data.license, card.data.base_model, card.data.language)
PY

block cards
on 'sources quote hub-model-cards "simple Markdown files with additional metadata|YAML.*section at the top"'
on 'python lab/cards.py'

block community
on 'sources quote hub-model-cards "is a fine-tune, an adapter, or a quantized|infer the type of relationship"'
