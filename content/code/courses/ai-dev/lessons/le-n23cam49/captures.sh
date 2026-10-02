#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of ai-dev, as a script that produces
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
# THE REVIEW AND THE GENERATED TESTS WERE WRITTEN BY THE COURSE. assist is the
# lab's (lab/assist.py) and asks labllm's scripted-1, whose replies are in
# lab/scripted.json. They carry the mistakes the lesson is about on purpose;
# every test run against them, and hypothesis, are real.
#
# pytest ends with how long its run took, "8 passed in 0.57s". That figure is
# measured, not written, and a rerun moves it by a few hundredths of a second.
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
on 'assist ask "Review this diff. List real problems only, most serious first." --open review.diff'

block checking-findings
put tests/test_review.py <<'PY'
from datetime import date

from shop.cart import Cart
from shop.coupons import apply_coupon


def test_finding_1_friends15_is_valid_on_its_last_day():
    cart = Cart()
    apply_coupon(cart, "FRIENDS15", today=date(2026, 10, 31))
    assert cart.discount_percent == 15


def test_finding_3_a_lower_case_code_is_accepted():
    cart = Cart()
    apply_coupon(cart, "welcome10", today=date(2026, 10, 2))
    assert cart.discount_percent == 10
PY
on 'python -m pytest -q tests/test_review.py'

block pinned-bugs
on 'assist ask "Write pytest tests for apply_coupon." --open shop/coupons.py > tests/test_generated.py'
on 'python -m pytest -q tests/test_generated.py'
on 'grep -n -A2 "def test_friends15" tests/test_generated.py'

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
on 'python -m pytest -q tests/test_generated.py'
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
on 'git diff shop/money.py'
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
put lab/mutate.py <<'PY'
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
on 'python lab/mutate.py shop/cart.py'
on 'python lab/mutate.py shop/coupons.py'
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
on 'python -m pytest -q tests/test_cart_rules.py && python lab/mutate.py shop/cart.py'
