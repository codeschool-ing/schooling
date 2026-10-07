#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of ai-dev, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo bash ../../lab.sh up        # once: Ollama, the models, ~/shop
#   sudo bash captures.sh
#
# THE ASSISTANT'S SUGGESTIONS ARE NOT REPEATABLE, and the lesson is built on
# that. assist (shown whole in what-it-sees.md) completes with
# qwen2.5-coder:1.5b through Ollama's fill-in-the-middle and answers questions
# with llama3.2:3b; neither is given a temperature, so every request is a new
# draw. Where the lesson depends on what came back, this script does what the
# lesson tells the student to do rather than assume an answer:
#
#   completion   ask, accept, run the four tests, and undo with git checkout
#                while they fail, at most three times; if none passes, ana
#                writes the body herself, and the lesson shows hers.
#   refactor     the whole-file request is asked again while the reply has
#                no block of code to write, at most three times.
#   documenting  asked again while the reply has no block of code, as the
#                refactoring is; ana pastes the examples the model wrote, out
#                of scratch/examples.txt, into the docstring of format_price.
#
#   models   llama3.2:3b (a80c4f17acd5), qwen2.5-coder:1.5b (d7372fd82851),
#            Ollama 0.40.0
#   taken    2026-10-07, on 4 cores and 15 GB with no GPU
#
# A line that starts with ana@dev:~/shop$ is what ana typed, in her project,
# and what it printed. What is STAGED rather than typed, and not shown: the
# lab's own reset, the files ana wrote (put below, each of which a lesson shows
# whole), the start of remove() that ana typed in her editor, and the paste of
# the docstring.
#
# pytest ends with how long its run took, "8 passed in 0.72s". That figure is
# measured, not written, and a rerun moves it by a few hundredths of a second.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh
tools() {
put scratch/assist.py <<'PY'
"""assist: an editor assistant small enough to read, written for this course.

The assistants built into editors do three things before a model sees anything:
they decide which text to send (the file around the cursor, other files that look
related, the project's instruction file), they leave out what they were told to
leave out, and they fit the rest into a token budget. This does the same three
things against your local models, prints what it sent, and keeps the whole
request in scratch/sent.json and the reply in scratch/reply.txt, which the real
ones do not show you. It is not a
copy of any of them: their exact rules are their own and mostly unpublished.

    python scratch/assist.py complete FILE:LINE [--open FILE ...] [--accept]
    python scratch/assist.py ask "QUESTION" [--open FILE ...] [--write FILE]

Completion uses a small code model trained to fill a gap between the text before
the cursor and the text after it; questions go to the chat model. Rules:
AGENTS.md, if present, goes first. Paths matching a line of .assistignore are
never read. A file holding something shaped like a secret is refused rather than
sent. The budget is 3,000 tokens of context. --accept puts the suggestion into
the file at the cursor, as pressing Tab would; --write puts the first block of
code in the reply into FILE, as a chat panel's Apply button would.
"""
import argparse
import fnmatch
import json
import os
import re
import sys
import urllib.request

import anthropic
import tiktoken

ENC = tiktoken.get_encoding("o200k_base")
BUDGET = 3000
SECRET = re.compile(r"(?i)(token|secret|password|api_key)\s*[=:]\s*\S{8,}")
CHAT, CODE = "llama3.2:3b", "qwen2.5-coder:1.5b"


def ignored(path):
    try:
        patterns = [p.strip() for p in open(".assistignore") if p.strip() and not p.startswith("#")]
    except FileNotFoundError:
        return False
    return any(fnmatch.fnmatch(path, p) or fnmatch.fnmatch(os.path.basename(path), p) for p in patterns)


def gather(paths, used):
    """The other files, in order, each whole or not at all, within what is left of the budget."""
    parts, notes = [], []
    for p in paths:
        if ignored(p):
            notes.append(f"skipped {p}: listed in .assistignore")
            continue
        text = open(p).read()
        if SECRET.search(text):
            notes.append(f"refused {p}: it holds something shaped like a secret")
            continue
        n = len(ENC.encode(text))
        if used + n > BUDGET:
            notes.append(f"dropped {p}: {n} tokens would pass the budget")
            continue
        parts.append((p, text, n))
        used += n
    return parts, used, notes


def as_comment(name, text):
    """Another file, for a code model: commented out, so it reads as context and not as code."""
    return "".join(f"# {line}\n".replace("# \n", "#\n") for line in [f"Path: {name}"] + text.split("\n"))


def report(sections, used, notes):
    print(f"context sent ({used} of {BUDGET} tokens):", file=sys.stderr)
    for name, _, n in sections:
        print(f"  {n:5}  {name}", file=sys.stderr)
    for note in notes:
        print(f"  {note}", file=sys.stderr)
    print("---", file=sys.stderr)


def complete(target, opened, accept):
    path, line = target.rsplit(":", 1)
    lines = open(path).read().split("\n")
    k = int(line)
    before, after = "\n".join(lines[:k - 1]) + "\n", "\n" + "\n".join(lines[k:])
    sections, used = [], 0
    if os.path.exists("AGENTS.md"):
        text = open("AGENTS.md").read()
        sections.append(("AGENTS.md", text, len(ENC.encode(text))))
        used += sections[-1][2]
    n = len(ENC.encode(before + after))
    sections.append((f"{path} (cursor at line {line})", None, n))
    used += n
    others, used, notes = gather(opened, used)
    sections += others
    report(sections, used, notes)
    context = "".join(as_comment(name, text) for name, text, _ in sections if text is not None)
    # Stop at the first blank line, so that one suggestion is one block.
    request = {"model": CODE, "prompt": context + before, "suffix": after, "stream": False,
               "options": {"num_predict": 300, "stop": ["\n\n"]}}
    json.dump(request, open("scratch/sent.json", "w"), indent=1)
    req = urllib.request.Request("http://127.0.0.1:11434/api/generate", json.dumps(request).encode())
    suggestion = json.load(urllib.request.urlopen(req))["response"].rstrip("\n")
    open("scratch/reply.txt", "w").write(suggestion + "\n")
    print(suggestion)
    if accept:
        lines[k - 1:k] = suggestion.split("\n")
        open(path, "w").write("\n".join(lines))


def ask(question, opened, write):
    sections, used = [], 0
    if os.path.exists("AGENTS.md"):
        text = open("AGENTS.md").read()
        sections.append(("AGENTS.md", text, len(ENC.encode(text))))
        used += sections[-1][2]
    others, used, notes = gather(opened, used)
    sections += others
    report(sections, used, notes)
    prompt = "".join(f"### {name}\n{text}\n" for name, text, _ in sections) + "\n" + question
    request = {"model": CHAT, "max_tokens": 1500,
               "system": "You answer questions about the files shown, briefly, as a senior colleague would.",
               "messages": [{"role": "user", "content": prompt}]}
    json.dump(request, open("scratch/sent.json", "w"), indent=1)
    reply = anthropic.Anthropic().messages.create(**request).content[0].text
    open("scratch/reply.txt", "w").write(reply + "\n")
    print(reply)
    if write:
        block = re.search(r"```\w*\n(.*?)\n```", reply, re.S)
        if not block:
            sys.exit("assist: the reply has no block of code to write")
        open(write, "w").write(block.group(1) + "\n")


def main():
    ap = argparse.ArgumentParser(prog="assist")
    ap.add_argument("mode", choices=["complete", "ask"])
    ap.add_argument("target")
    ap.add_argument("--open", nargs="*", default=[], help="other files open in the editor")
    ap.add_argument("--accept", action="store_true", help="insert the completion at the cursor")
    ap.add_argument("--write", metavar="FILE", help="write the reply's first block of code to FILE")
    a = ap.parse_args()
    if a.mode == "complete":
        complete(a.target, a.open, a.accept)
    else:
        ask(a.target, a.open, a.write)


if __name__ == "__main__":
    main()
PY
put scratch/sent.py <<'PY'
import json

r = json.load(open("scratch/sent.json"))
before, after = r["prompt"].split("\n"), r["suffix"].split("\n")
print("model:", r["model"], " stop:", r["options"]["stop"])
print("\n".join(before[:2] + ["(...)"] + before[-7:]))
print("<the gap the model fills>")
print("\n".join(after[:3] + ["(...)"]))
PY
}

quiet lab reset
tools

# ana starts a method: its signature and what it is for, and stops at the cursor.
lab exec ana "python - <<'PY'
p = 'shop/cart.py'
s = open(p).read()
s = s.replace('    def subtotal(self)', '''    def remove(self, sku: str, quantity: int = 1) -> None:
        \"\"\"Take \`quantity\` units of \`sku\` out of the cart.

        A line that reaches zero is removed. Removing more than the cart
        holds, or a sku it does not hold, raises ValueError.
        \"\"\"

    def subtotal(self)''')
open(p, 'w').write(s)
PY"

block what-it-sees-insert
on 'curl -s http://127.0.0.1:11434/api/generate -d '"'"'{"model": "llama3.2:3b", "prompt": "def add(a, b):\n", "suffix": "\n\nprint(add(1, 2))\n", "stream": false}'"'"'; echo'
block what-it-sees
on 'sed -n 28,34p shop/cart.py'
on 'python scratch/assist.py complete shop/cart.py:34 --open shop/coupons.py tests/test_cart.py'
on 'python scratch/sent.py'

block what-leaves
put .gitignore <<'TXT'
.env
__pycache__/
scratch/
TXT
put .env <<'TXT'
SHOP_PAYMENTS_TOKEN=not-a-real-token-7d41
TXT
put settings.py <<'PY'
PAYMENTS_URL = "https://payments.example.com/v1"
PAYMENTS_KEY = "pk_test_4f9a8c7e1d2b3a6f"  # made up for the course; a real key never belongs in code
PY
on 'git status --short --ignored'
on 'python scratch/assist.py ask "Why might a payment fail?" --open shop/cart.py .env settings.py'
on 'grep -c pk_test_4f9a8c7e1d2b3a6f scratch/sent.json'
on 'printf "settings.py\n*.pem\nsecrets/\n" > .assistignore'
on 'python scratch/assist.py ask "Why might a payment fail?" --open shop/cart.py .env settings.py 2>&1 >/dev/null'

block completion
put tests/test_remove.py <<'PY'
import pytest

from shop.cart import Cart


def test_removing_some_units_keeps_the_line():
    cart = Cart()
    cart.add("MUG-01", 3990, 3)
    cart.remove("MUG-01", 2)
    assert cart.lines[0].quantity == 1


def test_removing_the_last_unit_removes_the_line():
    cart = Cart()
    cart.add("MUG-01", 3990)
    cart.remove("MUG-01")
    assert cart.lines == []


def test_removing_more_than_the_cart_holds_is_refused():
    cart = Cart()
    cart.add("MUG-01", 3990, 2)
    with pytest.raises(ValueError):
        cart.remove("MUG-01", 3)


def test_removing_a_sku_not_in_the_cart_is_refused():
    with pytest.raises(ValueError):
        Cart().remove("LAMP-02")
PY
on 'git add shop/cart.py tests/test_remove.py && git commit -q -m "Cart.remove: what it must do"'
on 'python -m pytest -q tests/test_remove.py | tail -n 1'
for try in 1 2 3; do
  block completion-try-$try
  on 'python scratch/assist.py complete shop/cart.py:34 --open shop/coupons.py tests/test_cart.py --accept 2>/dev/null'
  on 'python -m pytest -q tests/test_remove.py | tail -n 1'
  if lab exec ana 'python -m pytest -q tests/test_remove.py' >/dev/null 2>&1; then
    break
  fi
  on 'git checkout shop/cart.py'
done
if ! lab exec ana 'python -m pytest -q tests/test_remove.py' >/dev/null 2>&1; then
  block completion-by-hand
  lab exec ana "python - <<'PY'
p = 'shop/cart.py'
s = open(p).read()
s = s.replace('''        \"\"\"

    def subtotal''', '''        \"\"\"
        for line in self.lines:
            if line.sku == sku:
                if quantity > line.quantity:
                    raise ValueError(f\"the cart holds {line.quantity} of {sku}\")
                line.quantity -= quantity
                if line.quantity == 0:
                    self.lines.remove(line)
                return
        raise ValueError(f\"{sku} is not in the cart\")

    def subtotal''')
open(p, 'w').write(s)
PY"
  on 'sed -n 34,42p shop/cart.py'
fi
block completion-kept
on 'git diff'
on 'python -m pytest -q'

block instructions-file
put AGENTS.md <<'MD'
# Notes for coding assistants

Read CONVENTIONS.md before changing anything. The rules that matter most:

- Money is integer cents. Never introduce a float, not even in a test.
- Run `python -m pytest` after every change, and say if it fails.
- Never edit a test to make it pass. If a test looks wrong, say so instead.
- Standard library only. Ask before adding a dependency.
MD
on 'python scratch/assist.py complete shop/cart.py:34 --open shop/coupons.py tests/test_cart.py 2>&1 >/dev/null'

block refactor
quiet lab reset
tools
on 'python -m pytest -q'
on 'python scratch/assist.py ask "Refactor Cart so total() computes the subtotal once. Reply with a unified diff." --open shop/cart.py > refactor.diff'
on 'cat -n refactor.diff'
on 'git apply --check refactor.diff'
# A reply with no block of code writes nothing, and ana asks again, at most
# three times.
for try in 1 2 3; do
  on 'python scratch/assist.py ask "Refactor Cart so total() computes the subtotal once. Reply with the complete new shop/cart.py in one block of code." --open shop/cart.py --write shop/cart.py > /dev/null'
  lab exec ana 'git diff --quiet shop/cart.py' || break
done
on 'git diff'
on 'python -m pytest -q'
put tests/test_threshold.py <<'PY'
from shop.cart import Cart
from shop.coupons import apply_coupon


def test_free_shipping_threshold_is_checked_after_the_discount():
    cart = Cart()
    cart.add("LAMP-02", 21000)
    apply_coupon(cart, "WELCOME10")
    assert cart.discount() == 2100
    assert cart.total() == 21000 - 2100 + 1500
PY
on 'python -m pytest -q tests/test_threshold.py | tail -n 1'
on 'git checkout shop/cart.py && python -m pytest -q'

block documenting
# A reply with no block of code writes nothing, and ana asks again, at most
# three times.
for try in 1 2 3; do
  on 'python scratch/assist.py ask "Write three doctest examples for format_price, one of them with a negative amount. Reply with only the >>> lines and the results, in one block of code." --open shop/money.py --write scratch/examples.txt > /dev/null'
  lab exec ana 'test -s scratch/examples.txt' && break
done
on 'cat scratch/examples.txt'
# ana pastes the examples into the docstring of format_price, under its first
# line, indented as the docstring is.
lab exec ana "python - <<'PY'
examples = [line.rstrip() for line in open('scratch/examples.txt').read().strip().split('\n')]
p = 'shop/money.py'
s = open(p).read()
q = chr(39)
old = '    \"\"\"Turn cents into a price as people read it: 1290 -> ' + q + '12.90' + q + '.\"\"\"'
new = ('    \"\"\"Turn cents into a price as people read it: 1290 -> ' + q + '12.90' + q + '.\n\n'
       + '\n'.join('    ' + line if line else '' for line in examples) + '\n    \"\"\"')
assert old in s
open(p, 'w').write(s.replace(old, new))
PY"
on 'sed -n 11,22p shop/money.py'
on 'python -m pytest -q --doctest-modules shop/money.py'
