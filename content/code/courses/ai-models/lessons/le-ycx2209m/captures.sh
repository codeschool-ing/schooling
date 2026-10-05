#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of ai-models, as a script that
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
# None of the seven providers below could be called from the machine this
# was recorded on with a key of the course's. Every one of them is standin
# (lab/standin.py), at the address and with the key lab.sh gives that
# provider; its answers come from lab/answers.json, and its rate-limit
# headers follow two naming schemes, OpenAI's for most and Anthropic's for
# Anthropic, with the lab's own numbers in them. What is real: the openai library, the one client all seven
# requests went through, and Anthropic's compatibility documentation, read
# on the date lab/sources.py prints.
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

put lab/compat.py <<'PY'
import json
import os

from openai import OpenAI

env = os.environ
# name: (base URL, key, model) -- the only three things that change
PROVIDERS = {
    "OpenAI":       (env["OPENAI_BASE_URL"], env["OPENAI_API_KEY"], "standin-small"),
    "Anthropic":    (env["ANTHROPIC_BASE_URL"] + "/v1/", env["ANTHROPIC_API_KEY"], "standin-large"),
    "Mistral":      (env["MISTRAL_SERVER_URL"] + "/v1", env["MISTRAL_API_KEY"], "standin-small"),
    "OpenRouter":   (env["OPENROUTER_BASE_URL"], env["OPENROUTER_API_KEY"], "standin/small"),
    "Hugging Face": (env["HF_BASE_URL"] + "/v1", env["HF_TOKEN"], "standin/small:cheapest"),
    "Ollama":       ("http://127.0.0.1:11434/v1", "ollama", "standin-local"),
    "LM Studio":    ("http://127.0.0.1:1234/v1", "lm-studio", "standin-local"),
}
prompt = open("prompts/triage.txt").read()
cases = [json.loads(line) for line in open("cases/triage.jsonl")][30:]

for name, (url, key, model) in PROVIDERS.items():
    client = OpenAI(base_url=url, api_key=key)
    right, limits = 0, set()
    for c in cases:
        raw = client.chat.completions.with_raw_response.create(
            model=model, temperature=0, max_tokens=16,
            messages=[{"role": "system", "content": prompt}, {"role": "user", "content": c["text"]}])
        right += raw.parse().choices[0].message.content.strip() == c["label"]
        limits |= {h for h in raw.headers if "ratelimit" in h and "requests" in h and "remaining" in h}
    print(f"{name:12} {model:22} {right}/{len(cases)}  {', '.join(sorted(limits)) or '(no rate-limit header)'}")
PY

block one-client
on 'python lab/compat.py'
on 'wire --count 70 | cut -d" " -f1,2,5 | sort | uniq -c'

block ignored
on 'sources quote claude-openai-compat "silently ignored|not considered a long-term"'
on 'sources lines claude-openai-compat 283 284'
on 'sources lines claude-openai-compat 293 294'
on 'sources quote claude-openai-compat "Values greater than 1|Prompt caching is not supported"'
on 'sources quote ollama-openai "does not have a way of setting the context size"'
