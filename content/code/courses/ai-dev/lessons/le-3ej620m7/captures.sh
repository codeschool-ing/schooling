#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of ai-dev, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo bash ../../lab.sh up        # once: Ollama, the models, ~/shop
#   sudo bash captures.sh
#
# THE MODEL'S REPLIES ARE NOT REPEATABLE, and neither are the timings in
# cache.py. Every request goes to llama3.2:3b through the anthropic SDK, which
# cannot set a temperature, so each reply is drawn at Ollama's default and a
# rerun words it differently. The token counts are repeatable: they are counts
# of what was sent, not of what came back, apart from output_tokens.
#
#   model    llama3.2:3b (a80c4f17acd5), Ollama 0.40.0
#   taken    2026-10-07, on 4 cores and 15 GB with no GPU
#
# The price sheet in price-list.md is not a capture of this script: it was
# printed by ../../prices.py on 2026-10-02, from Anthropic's pricing page and
# LiteLLM's list at a pinned commit, and the lesson quotes it as dated data.
#
# A line that starts with ana@dev:~/shop$ is what ana typed, in her project,
# and what it printed. What is STAGED rather than typed, and not shown: the
# lab's own reset, and the files ana wrote (put below), each of which a lesson
# shows whole; put refuses one that no lesson shows byte for byte.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh

quiet lab reset

put scratch/window.py <<'PY'
import sys

import anthropic
import tiktoken

client = anthropic.Anthropic()
enc = tiktoken.get_encoding("o200k_base")
copies = int(sys.argv[1])
text = ("The password for this exercise is PINEAPPLE.\n\n" + open("CONVENTIONS.md").read() * copies
        + "\n\nWhat is the password for this exercise? Answer with the word only.")
r = client.messages.create(model="llama3.2:3b", max_tokens=20,
                           messages=[{"role": "user", "content": text}])
read = r.usage.input_tokens + (r.usage.cache_read_input_tokens or 0)
print(f"sent about {len(enc.encode(text))}, read {read}: {r.stop_reason}, {r.content[0].text!r}")
PY
block the-window
on 'python scratch/window.py 2'
on 'python scratch/window.py 10'
on 'python scratch/window.py 12'

put scratch/count.py <<'PY'
import anthropic
import tiktoken

client = anthropic.Anthropic()
enc = tiktoken.get_encoding("o200k_base")
question = "Why does a 210.00 cart with WELCOME10 pay shipping?"
system = open("CONVENTIONS.md").read()
tool = {"name": "get_cart", "description": "Read a customer's cart by its id.",
        "input_schema": {"type": "object", "properties": {"cart_id": {"type": "string"}},
                         "required": ["cart_id"]}}
cases = [("question only", {}),
         ("with the conventions as system prompt", {"system": system}),
         ("with one tool definition", {"tools": [tool]})]
print(f"tiktoken on the question alone: {len(enc.encode(question))}")
for label, extra in cases:
    r = client.messages.create(model="llama3.2:3b", max_tokens=1,
                               messages=[{"role": "user", "content": question}], **extra)
    print(f"{r.usage.input_tokens + (r.usage.cache_read_input_tokens or 0):5}  {label}")
PY
block counting
on 'python scratch/count.py'
on 'ollama show llama3.2:3b --template | head -n 12'

put scratch/cost.py <<'PY'
from decimal import Decimal

import anthropic

# Dollars per million tokens, read from Anthropic's pricing page on 2026-10-02.
PRICES = {
    "claude-opus-5-5": (Decimal("4"), Decimal("20")),
    "claude-sonnet-5-5": (Decimal("2"), Decimal("10")),
    "claude-haiku-4-5": (Decimal("1"), Decimal("5")),
}
MILLION = Decimal(1_000_000)


def cost(model: str, input_tokens: int, output_tokens: int) -> Decimal:
    price_in, price_out = PRICES[model]
    return (input_tokens * price_in + output_tokens * price_out) / MILLION


client = anthropic.Anthropic()
r = client.messages.create(model="llama3.2:3b", max_tokens=300,
                           system=open("shop/cart.py").read(),
                           messages=[{"role": "user", "content": "Explain the shop's shipping rule."}])
u = r.usage
print(f"usage: {u.input_tokens} in, {u.output_tokens} out")
for model in PRICES:
    print(f"  at {model} prices: ${cost(model, u.input_tokens, u.output_tokens):.6f}")

print("a month of 3,000 requests a day, 1,800 tokens in and 250 out each:")
for model in PRICES:
    print(f"  {model}: ${cost(model, 1_800, 250) * 3_000 * 30:,.2f}")
PY
block a-bill
on 'python scratch/cost.py'

put scratch/conversation.py <<'PY'
import anthropic

client = anthropic.Anthropic()
REPLY = "Here is a reply of about a hundred tokens. " * 10
history, sent = [], 0
for turn in range(1, 21):
    history.append({"role": "user", "content": f"Question number {turn} about the cart, in about thirty tokens of text."})
    r = client.messages.create(model="llama3.2:3b", max_tokens=1, messages=history)
    n = r.usage.input_tokens + (r.usage.cache_read_input_tokens or 0)
    sent += n
    if turn in (1, 2, 5, 10, 15, 20):
        print(f"turn {turn:2}: this request {n:5} tokens, all requests so far {sent:6}")
    history.append({"role": "assistant", "content": REPLY})
PY
block conversation-cost
on 'python scratch/conversation.py'

put scratch/cache.py <<'PY'
import subprocess
import time
from decimal import Decimal

import anthropic

# Claude Sonnet 5.5, dollars per million tokens, read on 2026-10-02.
BASE, READ = Decimal("2"), Decimal("0.20")
client = anthropic.Anthropic()
project = subprocess.run("git ls-files | xargs tail -n +1", shell=True,
                         capture_output=True, text=True).stdout
system = [{"type": "text", "text": "You review changes to this project.\n\n" + project,
           "cache_control": {"type": "ephemeral"}}]
for question in ["Explain the shop's shipping rule.", "Explain the shipping rule again, shorter."]:
    start = time.monotonic()
    r = client.messages.create(model="llama3.2:3b", max_tokens=300, system=system,
                               messages=[{"role": "user", "content": question}])
    u = r.usage
    read = u.cache_read_input_tokens or 0
    print(f"input {u.input_tokens:4}  cache read {read:4}  output {u.output_tokens:3}  "
          f"{time.monotonic() - start:4.1f} s")
    paid = (u.input_tokens * BASE + read * READ) / 1_000_000
    plain = (u.input_tokens + read) * BASE / 1_000_000
    print(f"    at Sonnet's prices: input ${paid:.6f}, against ${plain:.6f} with no cache")
PY
block caching
onq 'ollama stop llama3.2:3b'
on 'python scratch/cache.py'

put scratch/cutoff.py <<'PY'
import sys

import anthropic

client = anthropic.Anthropic()
r = client.messages.create(model="llama3.2:3b", max_tokens=int(sys.argv[1]),
                           system=open("shop/cart.py").read(),
                           messages=[{"role": "user", "content": "Explain the shop's shipping rule."}])
print(f"stop_reason={r.stop_reason} output_tokens={r.usage.output_tokens}")
print(r.content[0].text)
if r.stop_reason == "max_tokens":
    print("!! the reply was cut off; do not use it as if it were complete")
PY
block cut-off
on 'python scratch/cutoff.py 40'
on 'python scratch/cutoff.py 400'
block cut-off-stop
on "python -c 'import anthropic; r = anthropic.Anthropic().messages.create(model=\"llama3.2:3b\", max_tokens=80, stop_sequences=[\"3.\"], messages=[{\"role\": \"user\", \"content\": \"Write a numbered list of five fruits.\"}]); print(r.stop_reason, repr(r.stop_sequence)); print(repr(r.content[0].text))'"

put scratch/budget.py <<'PY'
import anthropic
import tiktoken

DAILY_LIMIT = 20_000  # input tokens per user per day
PER_REQUEST = 3_000
MARGIN = 1.2  # tiktoken is not this model's tokenizer, so the estimate gets room
client = anthropic.Anthropic()
enc = tiktoken.get_encoding("o200k_base")
spent: dict[str, int] = {}


class OverBudget(Exception):
    pass


def ask(user: str, messages: list, max_tokens: int = 300):
    n = int(sum(len(enc.encode(m["content"])) for m in messages) * MARGIN)
    if n + max_tokens > PER_REQUEST:
        raise OverBudget(f"about {n} input tokens + {max_tokens} out is over {PER_REQUEST} per request")
    if spent.get(user, 0) + n > DAILY_LIMIT:
        raise OverBudget(f"{user} has used {spent.get(user, 0)} of {DAILY_LIMIT} today")
    r = client.messages.create(model="llama3.2:3b", max_tokens=max_tokens, messages=messages)
    used = r.usage.input_tokens + (r.usage.cache_read_input_tokens or 0)
    spent[user] = spent.get(user, 0) + used
    return r, used


code = open("shop/cart.py").read()
question = [{"role": "user", "content": code + "\nExplain the shipping rule above."}]
huge = [{"role": "user", "content": open("CONVENTIONS.md").read() * 8}]
for user, msgs in [("ana", question), ("ana", huge), ("bea", question)]:
    try:
        r, used = ask(user, msgs)
        print(f"{user}: ok, {used} in, {r.usage.output_tokens} out; spent today {spent[user]}")
    except OverBudget as e:
        print(f"{user}: refused before sending: {e}")
PY
block budgets
on 'python scratch/budget.py'
