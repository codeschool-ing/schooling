#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of ai-dev, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo bash ../../lab.sh up        # once: Ollama, the models, ~/shop
#   sudo bash captures.sh
#
# THE REVIEW AND THE GENERATED TESTS ARE NOT REPEATABLE. They come from
# llama3.2:3b through assist (lesson 3 shows it whole), with no temperature, so
# every run is a new draw, and the lesson discusses the draw it shows. What is
# repeatable: every test ana wrote, hypothesis at --hypothesis-seed=0, and the
# mutation tester. The request for tests is asked again while the reply has no
# block of code to write, at most three times, as lesson 3 does.
#
#   model    llama3.2:3b (a80c4f17acd5), Ollama 0.40.0
#   taken    2026-10-07, on 4 cores and 15 GB with no GPU
#
# A line that starts with ana@dev:~/shop$ is what ana typed, in her project,
# and what it printed. What is STAGED rather than typed, and not shown: the
# lab's own reset, and the files ana wrote (put below), each of which a lesson
# shows whole; put refuses one that no lesson shows byte for byte.
#
# pytest ends with how long its run took, "8 passed in 0.72s". That figure is
# measured, not written, and a rerun moves it by a few hundredths of a second.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh

quiet lab reset
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

block review-a-diff
on 'git switch -c coupon-expiry'
put shop/coupons.py <<'PY'
from datetime import date

from shop.cart import Cart

# code: (percent off, last day it is valid, or None for no end)
COUPONS = {"WELCOME10": (10, None), "FRIENDS15": (15, date(2026, 10, 31))}


class UnknownCoupon(Exception):
    pass


class ExpiredCoupon(Exception):
    pass


def apply_coupon(cart: Cart, code: str, today: date | None = None) -> None:
    """Set the cart's discount from a coupon code, typed in any case."""
    today = today or date.today()
    code = code.strip().upper()
    if code not in COUPONS:
        raise UnknownCoupon(code)
    percent, until = COUPONS[code]
    if until is not None and today >= until:
        raise ExpiredCoupon(code)
    cart.discount_percent = percent
PY
on 'git commit -qam "Coupons in any case, with an end date" && python -m pytest -q'
on 'git diff main --stat'
on 'git diff main > review.diff'
on 'python scratch/assist.py ask "Review this diff. List the three most serious real problems, one short paragraph each." --open review.diff > review.txt'
on 'cat -n review.txt'

block checking-findings
put tests/test_review.py <<'PY'
from datetime import date

from shop.cart import Cart
from shop.coupons import apply_coupon


def test_friends15_is_valid_on_its_last_day():
    cart = Cart()
    apply_coupon(cart, "FRIENDS15", today=date(2026, 10, 31))
    assert cart.discount_percent == 15


def test_a_lower_case_code_is_accepted():
    cart = Cart()
    apply_coupon(cart, "welcome10", today=date(2026, 10, 2))
    assert cart.discount_percent == 10
PY
on 'python -m pytest -q tests/test_review.py'

block pinned-bugs
for try in 1 2 3; do
  on 'python scratch/assist.py ask "Write pytest tests for apply_coupon, including its end dates. Start the file with every import it needs." --open shop/coupons.py --write tests/test_generated.py > /dev/null'
  lab exec ana 'test -s tests/test_generated.py' && break
done
on 'grep -n "^def test_\|10, 31" tests/test_generated.py'
on 'python -m pytest -q tests/test_generated.py | tail -n 15'
on 'sed -i "1i from datetime import date" tests/test_generated.py && python -m pytest -q tests/test_generated.py | tail -n 15'

block from-the-spec
put tests/test_coupon_terms.py <<'PY'
"""The coupon terms, as the shop publishes them:

    FRIENDS15  15% off, valid until 31 October 2026, inclusive.
    WELCOME10  10% off, no end date.
    Codes may be typed in any case.
"""
from datetime import date

import pytest

from shop.cart import Cart
from shop.coupons import ExpiredCoupon, apply_coupon


def test_friends15_is_valid_on_31_october():
    cart = Cart()
    apply_coupon(cart, "FRIENDS15", today=date(2026, 10, 31))
    assert cart.discount_percent == 15


def test_friends15_is_refused_on_1_november():
    with pytest.raises(ExpiredCoupon):
        apply_coupon(Cart(), "FRIENDS15", today=date(2026, 11, 1))


def test_welcome10_never_expires():
    cart = Cart()
    apply_coupon(cart, "WELCOME10", today=date(2099, 1, 1))
    assert cart.discount_percent == 10


@pytest.mark.parametrize("typed", ["friends15", "Friends15", " FRIENDS15 "])
def test_codes_may_be_typed_in_any_case(typed):
    cart = Cart()
    apply_coupon(cart, typed, today=date(2026, 10, 2))
    assert cart.discount_percent == 15
PY
on 'python -m pytest -q tests/test_coupon_terms.py'
on 'sed -i "s/today >= until/today > until/" shop/coupons.py && git diff --stat'
on 'python -m pytest -q tests/test_coupon_terms.py tests/test_review.py'
on 'python -m pytest -q tests/test_generated.py | tail -n 15'
on 'rm tests/test_generated.py && python -m pytest -q'

block edge-cases
put tests/test_format_edges.py <<'PY'
import pytest

from shop.money import format_price


@pytest.mark.parametrize("cents, text", [
    (0, "0.00"),
    (5, "0.05"),
    (99, "0.99"),
    (100, "1.00"),
    (1290, "12.90"),
    (100000, "1000.00"),
    (-5, "-0.05"),
    (-1290, "-12.90"),
])
def test_format_price(cents, text):
    assert format_price(cents) == text
PY
on 'python -m pytest -q tests/test_format_edges.py'

block property-based
put tests/test_money_properties.py <<'PY'
from hypothesis import given
from hypothesis import strategies as st

from shop.money import format_price, parse_price

cents = st.integers(min_value=-10**9, max_value=10**9)


@given(cents)
def test_a_price_survives_a_round_trip_through_text(n):
    assert parse_price(format_price(n)) == n


@given(cents)
def test_a_negative_price_reads_as_minus_the_positive_one(n):
    if n < 0:
        assert format_price(n) == "-" + format_price(-n)
PY
on 'python -m pytest -q -p no:cacheprovider --hypothesis-seed=0 tests/test_money_properties.py'
put shop/money.py <<'PY'
"""Money is an integer number of cents. Never a float."""


def parse_price(text: str) -> int:
    """Turn a price as people write it into cents: '12.90' -> 1290."""
    units, _, cents = text.strip().partition(".")
    cents = (cents + "00")[:2]
    return int(units) * 100 + int(cents)


def format_price(cents: int) -> str:
    """Turn cents into a price as people read it: 1290 -> '12.90', -5 -> '-0.05'."""
    sign = "-" if cents < 0 else ""
    cents = abs(cents)
    return f"{sign}{cents // 100}.{cents % 100:02d}"
PY
on 'python -m pytest -q -p no:cacheprovider --hypothesis-seed=0 tests/test_money_properties.py'
put shop/money.py <<'PY'
"""Money is an integer number of cents. Never a float."""


def parse_price(text: str) -> int:
    """Turn a price as people write it into cents: '12.90' -> 1290, '-0.05' -> -5."""
    text = text.strip()
    sign = -1 if text.startswith("-") else 1
    units, _, cents = text.lstrip("-").partition(".")
    cents = (cents + "00")[:2]
    return sign * (int(units) * 100 + int(cents))


def format_price(cents: int) -> str:
    """Turn cents into a price as people read it: 1290 -> '12.90', -5 -> '-0.05'."""
    sign = "-" if cents < 0 else ""
    cents = abs(cents)
    return f"{sign}{cents // 100}.{cents % 100:02d}"
PY
on 'python -m pytest -q -p no:cacheprovider --hypothesis-seed=0'

block mutation
put scratch/mutate.py <<'PY'
"""Change one operator at a time, run the tests, and report the changes nobody noticed."""
import ast
import pathlib
import subprocess
import sys

SWAP = {ast.Gt: ast.GtE, ast.GtE: ast.Gt, ast.Lt: ast.LtE, ast.LtE: ast.Lt,
        ast.Add: ast.Sub, ast.Sub: ast.Add, ast.FloorDiv: ast.Div}
NAME = {ast.Gt: ">", ast.GtE: ">=", ast.Lt: "<", ast.LtE: "<=", ast.Add: "+", ast.Sub: "-",
        ast.FloorDiv: "//", ast.Div: "/"}

path = pathlib.Path(sys.argv[1])
original = path.read_text()


def operators(tree):
    for node in ast.walk(tree):
        ops = node.ops if isinstance(node, ast.Compare) else [node.op] if isinstance(node, ast.BinOp) else []
        for k, op in enumerate(ops):
            if type(op) in SWAP:
                yield node, k, op


survived = 0
for i in range(len(list(operators(ast.parse(original))))):
    tree = ast.parse(original)
    node, k, op = list(operators(tree))[i]
    new = SWAP[type(op)]()
    if isinstance(node, ast.Compare):
        node.ops[k] = new
    else:
        node.op = new
    path.write_text(ast.unparse(tree))
    run = subprocess.run([sys.executable, "-m", "pytest", "-q", "-x", "-p", "no:cacheprovider"],
                         capture_output=True)
    verdict = "killed" if run.returncode else "SURVIVED"
    survived += verdict == "SURVIVED"
    print(f"{path}:{node.lineno}  {NAME[type(op)]:>2} -> {NAME[type(new)]:<2}  {verdict}")
path.write_text(original)
print(f"{survived} survived")
PY
on 'python scratch/mutate.py shop/cart.py'
on 'python scratch/mutate.py shop/coupons.py'
put tests/test_cart_rules.py <<'PY'
from datetime import date

from shop.cart import Cart
from shop.coupons import apply_coupon


def test_a_discount_rounds_down_to_a_whole_cent():
    cart = Cart()
    cart.add("MUG-01", 3990)
    apply_coupon(cart, "FRIENDS15", today=date(2026, 10, 2))
    assert cart.discount() == 598  # 15% of 39.90 is 5.985


def test_free_shipping_threshold_is_checked_after_the_discount():
    cart = Cart()
    cart.add("LAMP-02", 21000)
    apply_coupon(cart, "WELCOME10", today=date(2026, 10, 2))
    assert cart.total() == 21000 - 2100 + 1500
PY
on 'python -m pytest -q tests/test_cart_rules.py && python scratch/mutate.py shop/cart.py'
