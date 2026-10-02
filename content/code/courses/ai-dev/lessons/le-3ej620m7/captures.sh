#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of ai-dev, as a script that produces
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
# whose contents the lesson shows in full.
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

put lab/window.py <<'PY'
import sys

import anthropic

client = anthropic.Anthropic()
words = open("/opt/aidev/share/corpus.txt").read().split()
n, out = int(sys.argv[1]), int(sys.argv[2])
try:
    r = client.messages.create(model="tiny-1", max_tokens=out,
                               messages=[{"role": "user", "content": " ".join(words[:n])}])
    print(f"{r.stop_reason}: {r.usage.input_tokens} in, {r.usage.output_tokens} out")
except anthropic.BadRequestError as e:
    print(e.status_code, e.body["error"]["message"])
PY
block the-window
on 'python lab/window.py 900 200'
on 'python lab/window.py 900 400'
on 'python lab/window.py 1300 200'
on 'python lab/window.py 900 600'

put lab/count.py <<'PY'
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
    n = client.messages.count_tokens(model="scripted-1", messages=[{"role": "user", "content": question}],
                                     **extra).input_tokens
    print(f"{n:5}  {label}")
PY
block counting
on 'python lab/count.py'

block price-list
printf '%s\n' "##### (run on the recording machine, outside the lab: prices.py reads the network)"
printf '$ python3 prices.py\n'; (cd ../.. && python3 prices.py)

put lab/cost.py <<'PY'
from decimal import Decimal

import anthropic

# Dollars per million tokens, read from Anthropic's pricing page on 2026-10-02 (prices.py).
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
r = client.messages.create(model="scripted-1", max_tokens=300,
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
on 'python lab/cost.py'

put lab/conversation.py <<'PY'
import anthropic

client = anthropic.Anthropic()
REPLY = "Here is a reply of about a hundred and fifty tokens. " * 15
history, sent = [], 0
for turn in range(1, 21):
    history.append({"role": "user", "content": f"Question number {turn} about the cart, in about thirty tokens of text."})
    n = client.messages.count_tokens(model="scripted-1", messages=history).input_tokens
    sent += n
    if turn in (1, 2, 5, 10, 15, 20):
        print(f"turn {turn:2}: this request {n:5} tokens, all requests so far {sent:6}")
    history.append({"role": "assistant", "content": REPLY})
PY
block conversation-cost
on 'python lab/conversation.py'

put lab/cache.py <<'PY'
import subprocess
from decimal import Decimal

import anthropic

# Claude Sonnet 5.5, dollars per million tokens, read on 2026-10-02 (prices.py).
BASE, WRITE, READ = Decimal("2"), Decimal("2.50"), Decimal("0.20")
client = anthropic.Anthropic()
project = subprocess.run("git ls-files | xargs tail -n +1", shell=True,
                         capture_output=True, text=True).stdout
system = [{"type": "text", "text": "You review changes to this project.\n\n" + project,
           "cache_control": {"type": "ephemeral"}}]
for question in ["Explain the shop's shipping rule.", "Explain the shipping rule again, shorter."]:
    r = client.messages.create(model="scripted-1", max_tokens=300, system=system,
                               messages=[{"role": "user", "content": question}])
    u = r.usage
    print(f"input {u.input_tokens:4}  cache write {u.cache_creation_input_tokens:4}  "
          f"cache read {u.cache_read_input_tokens:4}  output {u.output_tokens}")
    paid = (u.input_tokens * BASE + u.cache_creation_input_tokens * WRITE
            + u.cache_read_input_tokens * READ) / 1_000_000
    plain = (u.input_tokens + u.cache_creation_input_tokens + u.cache_read_input_tokens) * BASE / 1_000_000
    print(f"    input cost ${paid:.6f}, against ${plain:.6f} with no cache")
PY
block caching
on 'python lab/cache.py'

put lab/cutoff.py <<'PY'
import sys

import anthropic

client = anthropic.Anthropic()
r = client.messages.create(model="scripted-1", max_tokens=int(sys.argv[1]),
                           messages=[{"role": "user", "content": "Explain the shop's shipping rule."}])
print(f"stop_reason={r.stop_reason} output_tokens={r.usage.output_tokens}")
print(r.content[0].text)
if r.stop_reason == "max_tokens":
    print("!! the reply was cut off; do not use it as if it were complete")
PY
block cut-off
on 'python lab/cutoff.py 40'
on 'python lab/cutoff.py 300'
block cut-off-stop
on "python -c 'import anthropic; r = anthropic.Anthropic().messages.create(model=\"tiny-1\", max_tokens=60, stop_sequences=[\"\\n\\n\"], messages=[{\"role\": \"user\", \"content\": \"Return the\"}]); print(r.stop_reason, repr(r.stop_sequence)); print(repr(r.content[0].text))'"

put lab/budget.py <<'PY'
import anthropic

DAILY_LIMIT = 20_000  # input tokens per user per day
PER_REQUEST = 4_000
client = anthropic.Anthropic()
spent: dict[str, int] = {}


class OverBudget(Exception):
    pass


def ask(user: str, messages: list, max_tokens: int = 300):
    n = client.messages.count_tokens(model="scripted-1", messages=messages).input_tokens
    if n + max_tokens > PER_REQUEST:
        raise OverBudget(f"{n} input tokens + {max_tokens} out is over {PER_REQUEST} per request")
    if spent.get(user, 0) + n > DAILY_LIMIT:
        raise OverBudget(f"{user} has used {spent.get(user, 0)} of {DAILY_LIMIT} today")
    r = client.messages.create(model="scripted-1", max_tokens=max_tokens, messages=messages)
    spent[user] = spent.get(user, 0) + r.usage.input_tokens
    return r


question = [{"role": "user", "content": "Explain the shop's shipping rule."}]
huge = [{"role": "user", "content": open("/opt/aidev/share/corpus.txt").read()[:30_000]}]
for user, msgs in [("ana", question), ("ana", huge), ("bea", question)]:
    try:
        r = ask(user, msgs)
        print(f"{user}: ok, {r.usage.input_tokens} in, {r.usage.output_tokens} out; spent today {spent[user]}")
    except OverBudget as e:
        print(f"{user}: refused before sending: {e}")
PY
block budgets
on 'python lab/budget.py'
on 'tail -n 3 /var/log/labllm/requests.jsonl | python -c "import json, sys; [print(r[\"n\"], r[\"path\"], r[\"status\"]) for r in map(json.loads, sys.stdin)]"'
