#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of ai-models, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash ../../lab.sh up        # once: Ollama, the models, ~/desk
#   sudo bash captures.sh
#
# A line that starts with ana@desk:~/desk$ is what ana typed and what it
# printed. evalkit.py is the student's, shown whole in the harness section and
# taken from it here.
#
# THE CANDIDATES ARE REAL: llama3.2:3b, qwen2.5:3b and llama3.2:1b, through
# Ollama 0.40.0 and OpenAI's library, on 2026-10-07. qwen2.5:3b is pulled for
# this lesson alone, because an evaluation needs more than one candidate and a
# second family at the same size is the comparison worth making. Every score,
# interval and comparison below is computed from what the models wrote. At
# temperature 1 their answers vary from run to run, and so will a student's;
# at temperature 0 they come close to repeating, and the lesson shows how
# close. THE PROSE IS WRITTEN AGAINST ONE RUN OF THIS SCRIPT: a new run can
# move a score by a case or two, and the prose has to be read against it again.
#
# Recorded on Ubuntu 24.04 (4 processors, 16 GB, no GPU), TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture-lib.sh

lab reset >/dev/null
lab exec ana 'mkdir -p runs'
give evalkit.py harness.md example evalkit.py
M='llama3.2:3b qwen2.5:3b llama3.2:1b'

block building-the-set
on "python -c \"import json, collections; print(collections.Counter(json.loads(l)['label'] for l in open('cases/triage.jsonl')))\""
on 'grep -c "\"order\": null" cases/triage.jsonl'
on 'grep -E "\"c(24|26)\"" cases/triage.jsonl'

block scoring
on "python -c \"from evalkit import score_triage as s; c = {'label': 'refund'}; print(s('refund', c), s('Refund', c), s('refund.', c), s('order-status', c))\""
on "python -c \"from evalkit import score_extract as s; c = {'order': 'LB-20452'}; print(s('{\\\"order\\\": \\\"LB-20452\\\"}', c), s('Here is the JSON: {\\\"order\\\": \\\"LB-20452\\\"}', c))\""

block harness
on "time python evalkit.py run triage runs/triage.jsonl 0 $M"
on 'wc -l runs/triage.jsonl; head -2 runs/triage.jsonl'

block results
on 'python evalkit.py report runs/triage.jsonl'
on 'python evalkit.py compare runs/triage.jsonl qwen2.5:3b llama3.2:3b'
on 'python evalkit.py compare runs/triage.jsonl llama3.2:3b llama3.2:1b'

block errors
on 'python evalkit.py errors runs/triage.jsonl | grep -v "^llama3.2:1b"'
on 'python evalkit.py errors runs/triage.jsonl | grep "^llama3.2:1b" | head -6'

block repeatability
on 'python evalkit.py run triage runs/again.jsonl 0 qwen2.5:3b && diff <(cut -d, -f4,5 runs/again.jsonl) <(grep qwen2.5:3b runs/triage.jsonl | cut -d, -f4,5) && echo same answers'
on 'python evalkit.py run triage runs/hot-a.jsonl 1 qwen2.5:3b; python evalkit.py run triage runs/hot-b.jsonl 1 qwen2.5:3b'
on 'python evalkit.py report runs/hot-a.jsonl; python evalkit.py report runs/hot-b.jsonl | tail -1'
on 'diff <(cut -d, -f3,4 runs/hot-a.jsonl) <(cut -d, -f3,4 runs/hot-b.jsonl)'

block extraction
on "python evalkit.py run extract runs/extract.jsonl 0 $M"
on 'python evalkit.py report runs/extract.jsonl'
on 'python evalkit.py errors runs/extract.jsonl | grep -v "^llama3.2:1b"'
on 'python evalkit.py errors runs/extract.jsonl | grep "^llama3.2:1b" | head -6'

block decision
on 'cp runs/triage.jsonl runs/baseline.jsonl'
on 'python evalkit.py gate runs/baseline.jsonl runs/hot-a.jsonl qwen2.5:3b; echo "exit $?"'
on 'python evalkit.py gate runs/baseline.jsonl runs/hot-b.jsonl qwen2.5:3b; echo "exit $?"'
on 'python evalkit.py gate runs/baseline.jsonl runs/hot-a.jsonl qwen2.5:3b 0; echo "exit $?"'
