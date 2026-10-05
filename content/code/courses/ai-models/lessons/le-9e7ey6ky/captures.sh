#!/usr/bin/env bash
# The terminal sessions quoted in lesson 17 of ai-models, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash ../../lab.sh up        # once: the machine, the SDKs, the documents
#   bash captures.sh
#
# A line that starts with ana@desk:~/desk$ is what ana typed and what it
# printed. STAGED rather than typed: the lab itself (lab.sh reset), the
# programs put below, which the lesson shows in full, and the overload:
# `overload N` tells standin, through its /lab/config, to answer the next N
# requests with a 529, where in the world the API would simply be busy.
#
# api.anthropic.com is reachable from the machine this was recorded on, but a
# key is a bill a course cannot hand out, so what answers at
# ANTHROPIC_BASE_URL is standin (lab/standin.py). Its replies come from
# lab/answers.json; its prompt cache follows the rules Anthropic documents,
# with minimums of its own (1,024 tokens for standin-large). What is real:
# the anthropic library at the version lab.sh pins and what it sends and
# retries, the model sheet, and Anthropic's documentation, read on the date
# lab/sources.py prints.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@desk:~/desk$ %s\n' "$*"; lab exec ana "$*" 2>&1 || true; }
put() { lab exec ana "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"; }
block() { printf '##### %s\n' "$1"; }
overload() { curl -s -o /dev/null -d "{\"fail_next\": 529, \"fail_count\": $1}" http://127.0.0.1:8500/lab/config; }

lab reset >/dev/null

put lab/claude_sort.py <<'PY'
import json
import sys

import anthropic

client = anthropic.Anthropic()
cases = {c["id"]: c for c in map(json.loads, open("cases/triage.jsonl"))}
prompt_file, case_id, max_tokens = sys.argv[1], sys.argv[2], int(sys.argv[3])

r = client.messages.create(model="standin-large", max_tokens=max_tokens,
                           system=open(prompt_file).read(),
                           messages=[{"role": "user", "content": cases[case_id]["text"]}])
print(repr(r.content[0].text), r.stop_reason, f"{r.usage.input_tokens} in, {r.usage.output_tokens} out")
PY

block shape
on 'python lab/claude_sort.py prompts/triage.txt c05 16'
on 'wire --headers anthropic-version,x-api-key,user-agent'
on 'sources quote claude-versioning "anthropic-version: 2023"'
on 'python lab/claude_sort.py prompts/extract.txt c01 64'
on 'python lab/claude_sort.py prompts/extract.txt c01 8'

put lab/retries.py <<'PY'
import json
import sys
import time

import anthropic

client = anthropic.Anthropic(max_retries=int(sys.argv[1]))
prompt = open("prompts/triage.txt").read()
case = [json.loads(line) for line in open("cases/triage.jsonl")][4]

start = time.monotonic()
try:
    r = client.messages.create(model="standin-large", max_tokens=16, system=prompt,
                               messages=[{"role": "user", "content": case["text"]}])
    print(f"{r.content[0].text} after {time.monotonic() - start:.1f} s")
except anthropic.APIStatusError as e:
    print(f"{type(e).__name__} {e.status_code} after {time.monotonic() - start:.1f} s")
PY

block errors
on 'sources quote claude-errors "overloaded_error|529 errors can occur|automatically retries"'
overload 2
on 'python lab/retries.py 2'
on 'wire --count 3'
overload 1
on 'python lab/retries.py 0'

put lab/cache.py <<'PY'
import json

import anthropic

client = anthropic.Anthropic()
prompt = open("prompts/triage.txt").read()
cases = [json.loads(line) for line in open("cases/triage.jsonl")]
examples = "".join(f"E-mail: {c['text']}\nLabel: {c['label']}\n\n" for c in cases[:39])


def sort(system, label):
    r = client.messages.create(
        model="standin-large", max_tokens=16,
        system=[{"type": "text", "text": system, "cache_control": {"type": "ephemeral"}}],
        messages=[{"role": "user", "content": cases[39]["text"]}])
    u = r.usage
    print(f"{label:22} written {u.cache_creation_input_tokens:4}  read {u.cache_read_input_tokens:4}  "
          f"uncached {u.input_tokens:3}  -> {r.content[0].text}")


sort(prompt, "prompt alone")
sort(prompt + "\nExamples:\n\n" + examples, "with 39 examples")
sort(prompt + "\nExamples:\n\n" + examples, "the same, again")
PY

block caching
on 'sources quote claude-caching "Shorter prompts cannot be cached|processed without caching|To verify whether"'
on 'python lab/cache.py'
on 'sheet show claude-sonnet-4-5 | grep -E "^(input_cost_per_token|cache_creation_input_token_cost|cache_read_input_token_cost|prompt_cache_min_tokens) "'
on 'python -c "print(f\"uncached {1128 * 3e-6 * 1000:.2f}  cached {(1104 * 3e-7 + 24 * 3e-6) * 1000:.2f}  dollars per 1,000 e-mails, input only\")"'
