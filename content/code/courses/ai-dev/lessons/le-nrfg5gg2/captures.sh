#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of ai-dev, as a script that produces
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
# EVERY REPLY FROM THE ASSISTANT IN THIS LESSON WAS WRITTEN BY THE COURSE. assist
# is the lab's (lab/assist.py) and asks labllm's scripted-1, whose replies are in
# lab/scripted.json. The suggestions carry the mistakes the lesson is about on
# purpose; the tests, the diff and the doctest run against them are real.
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

# ana starts a method: its signature and what it is for, and stops at the cursor.
STUB='    def remove(self, sku: str, quantity: int = 1) -> None:
        """Take `quantity` units of `sku` out of the cart.

        A line that reaches zero is removed. Removing more than the cart
        holds, or a sku it does not hold, raises ValueError.
        """
'
lab exec ana "python - <<'PY'
p = 'shop/cart.py'
s = open(p).read()
s = s.replace('    def subtotal(self)', '''$STUB
    def subtotal(self)''')
open(p, 'w').write(s)
PY"

block what-it-sees
on 'sed -n 28,34p shop/cart.py'
on 'assist complete shop/cart.py:34 --open shop/coupons.py tests/test_cart.py'
put lab/sent.py <<'PY'
import json

r = json.loads(open("/var/log/labllm/requests.jsonl").read().splitlines()[-1])["request"]
lines = r["messages"][0]["content"].split("\n")
k = lines.index("<CURSOR>")
print("system:", r["system"])
print("\n".join(lines[:2] + ["(...)"] + lines[k - 3:k + 3] + ["(...)"]))
print("\n".join(line for line in lines if line.startswith("### ")))
PY
on 'python lab/sent.py'

block what-leaves
put .gitignore <<'TXT'
.env
__pycache__/
lab/
TXT
put .env <<'TXT'
SHOP_PAYMENTS_TOKEN=lab-not-a-real-token-7d41
TXT
put settings.py <<'PY'
PAYMENTS_URL = "https://payments.example.com/v1"
PAYMENTS_KEY = "pk_lab_4f9a8c7e1d2b3a6f"  # the lab's; a real key never belongs in code
PY
on 'git status --short --ignored'
on 'assist ask "Why might a payment fail?" --open shop/cart.py .env settings.py'
on 'grep -c pk_lab_4f9a8c7e1d2b3a6f /var/log/labllm/requests.jsonl'
on 'printf "settings.py\n*.pem\nsecrets/\n" > .assistignore'
on 'assist ask "Why might a payment fail?" --open shop/cart.py .env settings.py 2>&1 >/dev/null'

block completion
lab exec ana "python - <<'PY'
p = 'shop/cart.py'
s = open(p).read()
s = s.replace('''        \"\"\"

    def subtotal''', '''        \"\"\"
        for line in self.lines:
            if line.sku == sku:
                line.quantity -= quantity
                return
        raise ValueError(f\"{sku} is not in the cart\")

    def subtotal''')
open(p, 'w').write(s)
PY"
on 'sed -n 28,39p shop/cart.py'
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
on 'python -m pytest -q tests/test_remove.py'
lab exec ana "python - <<'PY'
p = 'shop/cart.py'
s = open(p).read()
s = s.replace('''            if line.sku == sku:
                line.quantity -= quantity
                return
        raise''', '''            if line.sku == sku:
                if quantity > line.quantity:
                    raise ValueError(f\"the cart holds {line.quantity} of {sku}\")
                line.quantity -= quantity
                if line.quantity == 0:
                    self.lines.remove(line)
                return
        raise''')
open(p, 'w').write(s)
PY"
on 'sed -n 34,42p shop/cart.py'
on 'git diff --stat'
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
on 'assist complete shop/cart.py:34 --open shop/coupons.py tests/test_cart.py 2>&1 >/dev/null'

block refactor
lab reset >/dev/null
on 'python -m pytest -q'
on 'assist ask "Refactor Cart so total() computes the subtotal once. Reply with a unified diff." --open shop/cart.py > refactor.diff'
on 'cat refactor.diff'
on 'git apply --stat refactor.diff'
on 'git apply refactor.diff && python -m pytest -q'
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
on 'python -m pytest -q tests/test_threshold.py'
on 'git checkout shop/cart.py && python -m pytest -q'

block documenting
on 'assist ask "Write a docstring with examples for format_price." --open shop/money.py'
lab exec ana "python - <<'PY'
p = 'shop/money.py'
s = open(p).read()
s = s.replace('''    \"\"\"Turn cents into a price as people read it: 1290 -> '12.90'.\"\"\"''', '''    \"\"\"Turn cents into a price as people read it.

    >>> format_price(1290)
    '12.90'
    >>> format_price(5)
    '0.05'
    >>> format_price(-5)
    '-0.05'
    \"\"\"''')
open(p, 'w').write(s)
PY"
on 'python -m pytest -q --doctest-modules shop/money.py'
