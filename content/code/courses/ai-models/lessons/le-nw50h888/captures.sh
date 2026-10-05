#!/usr/bin/env bash
# The terminal sessions quoted in lesson 14 of ai-models, as a script that
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
# NEITHER OLLAMA NOR LM STUDIO RUNS ON THIS MACHINE. Both fetch their models
# from hosts it cannot reach (ollama.com and huggingface.co), and LM Studio is
# a desktop application. What answers on their ports, 11434 and 1234, is
# standin (lab/standin.py), speaking their APIs; its model, standin-local,
# answers from the table in lab/answers.json, and its durations are the
# speeds lab/standin.py gives it. What is real: the `ollama` and `openai`
# libraries and what they send, and the two projects' own documentation, read
# at the commits lab/sources.py pins.
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

block two-tools
on 'sources quote ollama-api "Model names follow"'
on 'sources quote ollama-readme "Supported backends|llama.cpp\\]"'
on 'sources quote lmstudio-tools "llmster is LM Studio|listens on"'

block privacy
on 'sources quote ollama-faq "Ollama runs locally"'
on 'sources quote ollama-openai "No Ollama installation required|base_url=\"https://ollama.com"'

put lab/local_chat.py <<'PY'
import json

import ollama

prompt = open("prompts/triage.txt").read()
case = [json.loads(line) for line in open("cases/triage.jsonl")][4]

r = ollama.chat(model="standin-local", options={"temperature": 0},
                messages=[{"role": "system", "content": prompt}, {"role": "user", "content": case["text"]}])
print(f"{case['id']}: {r.message.content}   (a person said {case['label']})")
print(f"read {r.prompt_eval_count} tokens, wrote {r.eval_count}")
print(f"{r.eval_count / r.eval_duration * 1e9:.1f} tokens/s while writing, {r.total_duration / 1e9:.2f} s in all")
PY

block native
on 'python lab/local_chat.py'
on 'wire --headers user-agent'
on 'python -c "import ollama; [print(m.model, m.expires_at) for m in ollama.ps().models]"'

block keep-alive
on 'sources quote ollama-faq "By default models are kept in memory"'
on 'python -c "import ollama; print(ollama.generate(model=\"standin-local\", keep_alive=0).done_reason); print(len(ollama.ps().models), \"models loaded\")"'

put lab/context.py <<'PY'
import json

import ollama

prompt = open("prompts/triage.txt").read()
cases = [json.loads(line) for line in open("cases/triage.jsonl")]

# every other case as a worked example, then the last one as the question
messages = [{"role": "system", "content": prompt}]
for c in cases[:39]:
    messages += [{"role": "user", "content": c["text"]}, {"role": "assistant", "content": c["label"]}]
messages.append({"role": "user", "content": cases[39]["text"]})

for num_ctx in (None, 1024, 512):
    options = {"temperature": 0} | ({"num_ctx": num_ctx} if num_ctx else {})
    r = ollama.chat(model="standin-local", messages=messages, options=options)
    print(f"num_ctx {num_ctx or 'unset':>5}: sent {len(messages)} messages, "
          f"the model read {r.prompt_eval_count:>4} tokens -> {r.message.content}")
PY

block context
on 'sources quote ollama-faq "By default, Ollama uses a context window"'
on 'python lab/context.py'

put lab/two_servers.py <<'PY'
import json

from openai import OpenAI

prompt = open("prompts/triage.txt").read()
case = [json.loads(line) for line in open("cases/triage.jsonl")][4]

SERVERS = {"Ollama": ("http://127.0.0.1:11434/v1", "ollama"),
           "LM Studio": ("http://127.0.0.1:1234/v1", "lm-studio")}
for name, (url, key) in SERVERS.items():
    client = OpenAI(base_url=url, api_key=key)   # the library needs a key; neither server reads it here
    model = client.models.list().data[0].id
    r = client.chat.completions.create(model=model, temperature=0, messages=[
        {"role": "system", "content": prompt}, {"role": "user", "content": case["text"]}])
    print(f"{name:9} {model:22} {r.choices[0].message.content}")
PY

block openai
on 'python lab/two_servers.py'
on 'wire --count 4'
on 'sources quote ollama-openai "does not have a way of setting the context size"'
