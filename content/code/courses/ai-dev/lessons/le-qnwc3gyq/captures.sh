#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of ai-dev, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo bash ../../lab.sh up        # once: the machine, the SDKs, labllm
#   sudo bash captures.sh
#
# A line that starts with ana@dev:~/shop$ is what ana typed, in her project,
# and what it printed. What is STAGED rather than typed, and not shown in the
# lesson: the lab itself (lab.sh reset), and the files ana wrote (put below),
# whose contents the lesson shows in full, and a commit of llm.py and ask.py
# before ana's fix to llm.py, so that git diff can show the fix.
#
# TIMES ARE MEASURED: once.py's seconds include the SDK's own backoff, which
# has a random part, so a rerun moves them by a few tenths.
#
# ALL THREE PROVIDERS ARE labllm. The three SDKs are the real ones (anthropic,
# openai, google-genai, at the versions lesson 1 lists) and they speak their
# real wire formats, but every request in this lesson went to 127.0.0.1:8400,
# whose replies were written by the course (lab/scripted.json). The rate limit,
# the 529s and the 401 are labllm's, switched on with /lab/config, which the
# lesson shows. labllm counts tokens the same way for all three; real
# providers each count with their own tokenizer.
#
# The prices in cost.py were read with prices.py on 2026-10-02: Anthropic's
# from its pricing page, OpenAI's and Google's from LiteLLM at the pinned
# commit, as lesson 2 explains.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@dev:~/shop$ %s\n' "$*"; lab exec ana "$*" 2>&1 || true; }
put() { lab exec ana "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"; }
block() { printf '##### %s\n' "$1"; }
lab reset >/dev/null

put three.py <<'PY'
"""One question, three providers, each through its own SDK."""
import os

import anthropic
import openai
from google import genai
from google.genai import types

SYSTEM = "Answer in one paragraph."
QUESTION = "Explain in a paragraph why the cart stores prices in cents."


def ask_anthropic():
    r = anthropic.Anthropic().messages.create(
        model="scripted-1", max_tokens=300, system=SYSTEM,
        messages=[{"role": "user", "content": QUESTION}])
    return r.content[0].text, r.usage.input_tokens, r.usage.output_tokens, r.stop_reason


def ask_openai():
    r = openai.OpenAI().chat.completions.create(
        model="scripted-1", max_completion_tokens=300,
        messages=[{"role": "system", "content": SYSTEM}, {"role": "user", "content": QUESTION}])
    return r.choices[0].message.content, r.usage.prompt_tokens, r.usage.completion_tokens, r.choices[0].finish_reason


def ask_google():
    client = genai.Client(http_options=types.HttpOptions(base_url=os.environ["GEMINI_BASE_URL"]))
    r = client.models.generate_content(
        model="scripted-1", contents=QUESTION,
        config=types.GenerateContentConfig(
            system_instruction=SYSTEM, max_output_tokens=300,
            automatic_function_calling=types.AutomaticFunctionCallingConfig(disable=True)))
    u = r.usage_metadata
    return r.text, u.prompt_token_count, u.candidates_token_count, r.candidates[0].finish_reason


for name, ask in [("anthropic", ask_anthropic), ("openai", ask_openai), ("google", ask_google)]:
    text, n_in, n_out, why = ask()
    print(f"{name:9} {n_in:3} in {n_out:3} out  {why!s:18} {text[:34]}…")
PY

block three-shapes
on 'python three.py'

block keys
on "env | grep _API_KEY | cut -d= -f1"
on "env -u ANTHROPIC_API_KEY python -c 'import anthropic; anthropic.Anthropic().messages.create(model=\"scripted-1\", max_tokens=10, messages=[{\"role\": \"user\", \"content\": \"hi\"}])' 2>&1 | tail -n 1"
on "ANTHROPIC_API_KEY=lab-anthropic-key-9999 python -c 'import anthropic; anthropic.Anthropic().messages.create(model=\"scripted-1\", max_tokens=10, messages=[{\"role\": \"user\", \"content\": \"hi\"}])' 2>&1 | tail -n 1"
on "printf '.env\n' > .gitignore; git check-ignore -v .env"

put burst.py <<'PY'
"""Five requests in a row, with the SDK's retries off, to see the limit as it is."""
import anthropic

model = anthropic.Anthropic(max_retries=0)
for n in range(1, 6):
    try:
        raw = model.messages.with_raw_response.create(
            model="scripted-1", max_tokens=20, messages=[{"role": "user", "content": "Say hello in five words."}])
        print(n, raw.http_response.status_code, "remaining:", raw.headers["anthropic-ratelimit-requests-remaining"])
    except anthropic.RateLimitError as e:
        print(n, e.status_code, "retry-after:", e.response.headers["retry-after"], "|", e.message)
PY

block rate-limits
on "curl -s localhost:8400/lab/config -d '{\"rpm\": 3, \"clear\": true}' >/dev/null; python burst.py"

block retries
on "curl -s localhost:8400/lab/config -d '{\"rpm\": 50, \"clear\": true}' >/dev/null"
on "python -c 'import anthropic, openai; a = anthropic.Anthropic(); o = openai.OpenAI(); print(\"anthropic:\", a.max_retries, a.timeout); print(\"openai:   \", o.max_retries, o.timeout)'"
put once.py <<'PY'
"""One request, with the SDK's default retries, and how long it took."""
import time

import anthropic

t0 = time.monotonic()
try:
    r = anthropic.Anthropic().messages.create(
        model="scripted-1", max_tokens=20, messages=[{"role": "user", "content": "Say hello in five words."}])
    print(f"{r.content[0].text!r} after {time.monotonic() - t0:.1f} s")
except anthropic.APIStatusError as e:
    print(f"{type(e).__name__} {e.status_code} after {time.monotonic() - t0:.1f} s")
PY
on "curl -s localhost:8400/lab/config -d '{\"fail_next\": 529, \"fail_count\": 2}' >/dev/null; python once.py"
on "tail -n 3 /var/log/labllm/requests.jsonl | python -c 'import json, sys; [print(r[\"status\"], r.get(\"error\", \"\")) for r in map(json.loads, sys.stdin)]'"
on "curl -s localhost:8400/lab/config -d '{\"fail_next\": 529, \"fail_count\": 3}' >/dev/null; python once.py"

put cost.py <<'PY'
"""What one workload costs a month at each model's list price."""
# Dollars per million tokens, input and output, read with prices.py on 2026-10-02.
PRICES = {
    "claude-opus-5-5": (4, 20), "claude-sonnet-5-5": (2, 10), "claude-haiku-4-5": (1, 5),
    "gpt-5.5": (5, 30), "gpt-5.4": (2.5, 15), "gpt-5.4-mini": (0.75, 4.5), "gpt-5.4-nano": (0.2, 1.25),
    "gemini-pro-latest": (2, 12), "gemini-3.5-flash": (1.5, 9), "gemini-3.5-flash-lite": (0.3, 2.5),
}
REQUESTS, TOKENS_IN, TOKENS_OUT = 2_000 * 30, 1_500, 300

print(f"{REQUESTS:,} requests a month, {TOKENS_IN:,} tokens in and {TOKENS_OUT} out each")
rows = []
for model, (p_in, p_out) in PRICES.items():
    month = REQUESTS * (TOKENS_IN * p_in + TOKENS_OUT * p_out) / 1_000_000
    rows.append((month, model))
for month, model in sorted(rows):
    print(f"  {model:22} ${month:>9,.2f}")
PY

block cost
on 'python cost.py'

put llm.py <<'PY'
"""One way for the shop to ask a model, whichever provider is behind it."""
import os
from dataclasses import dataclass

import anthropic
import openai
from google import genai
from google.genai import errors as genai_errors
from google.genai import types


@dataclass
class Reply:
    text: str
    tokens_in: int
    tokens_out: int
    provider: str


class Unavailable(Exception):
    """The provider could not answer after its SDK's own retries."""


def _anthropic(system, question, max_tokens):
    try:
        r = anthropic.Anthropic().messages.create(model=os.environ["LLM_MODEL_ANTHROPIC"], max_tokens=max_tokens,
                                                  system=system, messages=[{"role": "user", "content": question}])
    except (anthropic.APIConnectionError, anthropic.RateLimitError, anthropic.InternalServerError) as e:
        raise Unavailable(f"anthropic: {type(e).__name__}") from e
    return Reply(r.content[0].text, r.usage.input_tokens, r.usage.output_tokens, "anthropic")


def _openai(system, question, max_tokens):
    try:
        r = openai.OpenAI().chat.completions.create(
            model=os.environ["LLM_MODEL_OPENAI"], max_completion_tokens=max_tokens,
            messages=[{"role": "system", "content": system}, {"role": "user", "content": question}])
    except (openai.APIConnectionError, openai.RateLimitError, openai.InternalServerError) as e:
        raise Unavailable(f"openai: {type(e).__name__}") from e
    return Reply(r.choices[0].message.content, r.usage.prompt_tokens, r.usage.completion_tokens, "openai")


def _google(system, question, max_tokens):
    client = genai.Client(http_options=types.HttpOptions(base_url=os.environ["GEMINI_BASE_URL"]))
    try:
        r = client.models.generate_content(
            model=os.environ["LLM_MODEL_GOOGLE"], contents=question,
            config=types.GenerateContentConfig(system_instruction=system, max_output_tokens=max_tokens,
                                               automatic_function_calling=types.AutomaticFunctionCallingConfig(disable=True)))
    except genai_errors.ServerError as e:
        raise Unavailable(f"google: {type(e).__name__}") from e
    u = r.usage_metadata
    return Reply(r.text, u.prompt_token_count, u.candidates_token_count, "google")


PROVIDERS = {"anthropic": _anthropic, "openai": _openai, "google": _google}


def ask(system, question, max_tokens=300):
    """Ask the providers in LLM_PROVIDERS, in order, until one answers."""
    tried = []
    for name in os.environ["LLM_PROVIDERS"].split(","):
        try:
            return PROVIDERS[name](system, question, max_tokens)
        except Unavailable as e:
            tried.append(str(e))
    raise Unavailable("; ".join(tried))
PY
put ask.py <<'PY'
import sys

from llm import ask

r = ask("Answer in one paragraph.", sys.argv[1])
print(f"{r.provider}: {r.tokens_in} in, {r.tokens_out} out | {r.text[:48]}…")
PY

block adapter
lab exec ana "printf 'LLM_MODEL_ANTHROPIC=scripted-1\nLLM_MODEL_OPENAI=scripted-1\nLLM_MODEL_GOOGLE=scripted-1\n' > .env"
lab exec ana 'git add .gitignore llm.py ask.py && git commit -q -m "One way to ask a model"'
on 'cat .env'
on 'set -a; . ./.env; for p in anthropic openai google; do LLM_PROVIDERS=$p python ask.py "Explain in a paragraph why the cart stores prices in cents."; done'
on "curl -s localhost:8400/lab/config -d '{\"fail_next\": 529, \"fail_count\": 3}' >/dev/null; set -a; . ./.env; LLM_PROVIDERS=anthropic,openai python ask.py 'Explain in a paragraph why the cart stores prices in cents.' 2>&1 | tail -n 1"
on "tail -n 3 /var/log/labllm/requests.jsonl | python -c 'import json, sys; [print(r[\"path\"], r[\"status\"]) for r in map(json.loads, sys.stdin)]'"
# The fix ana makes to llm.py, applied by a script; git diff below shows all of it.
lab exec ana "python -" <<'PY'
from pathlib import Path
p = Path('llm.py')
s = p.read_text()
s = s.replace('''class Unavailable(Exception):
    """The provider could not answer after its SDK's own retries."""
''', '''class Unavailable(Exception):
    """The provider could not answer after its SDK's own retries."""


def transient(e):
    """Worth asking another provider: no connection, a rate limit, or the provider's own failure."""
    status = getattr(e, "status_code", None) or getattr(e, "code", None)
    return status is None or status == 429 or status >= 500
''')
for old, new in [
        ("(anthropic.APIConnectionError, anthropic.RateLimitError, anthropic.InternalServerError)",
         "(anthropic.APIConnectionError, anthropic.APIStatusError)"),
        ("(openai.APIConnectionError, openai.RateLimitError, openai.InternalServerError)",
         "(openai.APIConnectionError, openai.APIStatusError)"),
        ("genai_errors.ServerError", "genai_errors.APIError")]:
    line = f"    except {old} as e:\n"
    assert line in s, old
    s = s.replace(line, f"    except {new} as e:\n        if not transient(e):\n            raise\n")
p.write_text(s)
PY
on 'git diff llm.py'
on "curl -s localhost:8400/lab/config -d '{\"fail_next\": 529, \"fail_count\": 3}' >/dev/null; set -a; . ./.env; LLM_PROVIDERS=anthropic,openai python ask.py 'Explain in a paragraph why the cart stores prices in cents.'"
on "tail -n 4 /var/log/labllm/requests.jsonl | python -c 'import json, sys; [print(r[\"path\"], r[\"status\"]) for r in map(json.loads, sys.stdin)]'"
