---
title: One step at a time
version: 2
---

"Add comma support to the price parser" is a task with three parts: decide what it must do, write
the tests that say so, change the code. Asking for all of it in one request gets all three at once,
mixed, and the tests that arrive with the change have the problem of lesson 4 section 04: they were
written from the change. **Asking for one step at a time lets you check each step before the next
one is built on it.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"The order of lesson 5. Ask for a plan; write the tests from it by hand; run them and see them fail; ask for the change; run the tests. When one fails, send the failure back and ask again; when all pass, stop.\"><defs><marker id=\"st-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"14\" y=\"50\" width=\"124\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"76.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">ask for a plan</text><text x=\"76.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">model</text><path d=\"M140 76 L152 76\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah)\"></path><rect x=\"154\" y=\"50\" width=\"124\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"216.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">write the tests</text><text x=\"216.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">you</text><path d=\"M280 76 L292 76\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah)\"></path><rect x=\"294\" y=\"50\" width=\"124\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"356.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">see them fail</text><text x=\"356.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pytest</text><path d=\"M420 76 L432 76\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah)\"></path><rect x=\"434\" y=\"50\" width=\"124\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"496.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">ask for the change</text><text x=\"496.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">model</text><path d=\"M560 76 L572 76\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah)\"></path><rect x=\"574\" y=\"50\" width=\"124\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"636.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">run the tests</text><text x=\"636.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pytest</text><path d=\"M636 104 L636 160 L496 160 L496 106\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah)\"></path><text x=\"566\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a test fails: send the failure back</text><path d=\"M698 76 L698 30 L640 30\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"560\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">all pass: stop</text></svg>", "caption": "Each step is checked before the next one is built on it, and the tests exist before the code they judge."}
```

## A plan, and no code

ana puts `parse_price` back as it was and asks for the steps only:

```
ana@dev:~/shop$ git checkout -q shop/money.py && git status --short
?? comma.diff
?? error.txt
?? prompts/
?? scratch/
ana@dev:~/shop$ python scratch/assist.py ask "We need parse_price to accept a decimal comma. Do not write code yet: list the steps, with the tests first." --open shop/money.py CONVENTIONS.md > /dev/null
context sent (511 of 3000 tokens):
    137  shop/money.py
    374  CONVENTIONS.md
---
ana@dev:~/shop$ cat -n scratch/reply.txt
     1	Here are the steps to update the `parse_price` function to accept a decimal comma:
     2	
     3	### Step 1: Write a test that fails without the change
     4	
     5	* Name: `test_parse_price_with_comma`
     6	* Description: A price with a decimal comma should still be parsed correctly.
     7	* Expected outcome: The test should fail because the `parse_price` function doesn't currently accept a decimal comma.
     8	
     9	### Step 2: Update the test to verify the correct behavior
    10	
    11	* Name: `test_parse_price_with_comma`
    12	* Description: A price with a decimal comma should be parsed correctly.
    13	* Expected outcome: The test should pass, verifying that the updated `parse_price` function correctly handles decimal commas.
    14	
    15	### Step 3: Update the `parse_price` function to accept a decimal comma
    16	
    17	* The updated function should check if the input string contains a comma, and if so, replace it with a dot before parsing the price.
    18	* The updated function should also handle the case where the input string has a comma but no decimal part.
    19	
    20	### Step 4: Review the updated code and ensure it follows the convention rules
    21	
    22	* Verify that the updated `parse_price` function meets the rule that errors are exceptions with a name, and that no function is longer than about 40 lines.
    23	* Verify that the updated code still follows the rule about text being produced by `shop.money.format_price` and parsed by `shop.money.parse_price`.
```

**A plan is cheap to read and cheap to correct**, and this one needs correcting. It does put a test
first, and its step 3 is the right idea: replace the comma with a dot before parsing. But steps 1
and 2 are the same test written twice, the test has a name and no cases, and step 4 is
`CONVENTIONS.md` read back. Nothing in it says which inputs decide whether the change worked. That
took ten seconds to read and costs one sentence to fix; the same gap found in a diff would have been
a diff to unpick.

## The tests, by hand

The cases are the part of the plan that matters, so ana writes them herself and decides the expected
values. She adds one the plan never mentioned, because she knows how Brazilians write a thousand:
`1.234,56` has a dot and a comma, and no rule can tell which of the two is the decimal separator, so
it must be refused rather than guessed:

```python
import pytest

from shop.money import parse_price


@pytest.mark.parametrize("text", ["12,90", "12.90", "12,9", " 12,90 "])
def test_a_comma_or_a_dot_is_the_decimal_separator(text):
    assert parse_price(text) == 1290


def test_a_price_with_both_a_dot_and_a_comma_is_refused():
    with pytest.raises(ValueError):
        parse_price("1.234,56")
```

Run before the change, they should fail, and they do (lesson 5 section 05's last rule). The one that
passes is `12.90`, which the old function already read:

```
ana@dev:~/shop$ python -m pytest -q tests/test_comma.py | tail -n 3
FAILED tests/test_comma.py::test_a_comma_or_a_dot_is_the_decimal_separator[ 12,90 ]
FAILED tests/test_comma.py::test_a_price_with_both_a_dot_and_a_comma_is_refused
4 failed, 1 passed in 0.73s
```

## The change

The function from lesson 5 section 05 is still in `scratch/parse_price.py`. Swapped in, against the
new tests:

```
ana@dev:~/shop$ python scratch/swap.py shop/money.py scratch/parse_price.py && python -m pytest -q tests/test_comma.py | tail -n 3
swap: parse_price replaced in shop/money.py
=========================== short test summary info ============================
FAILED tests/test_comma.py::test_a_comma_or_a_dot_is_the_decimal_separator[12.90]
1 failed, 4 passed in 0.71s
```

Four of five, and the one that fails is the dot, as the project's own test already said. **One of
the four passes for the wrong reason.** `1.234,56` is refused, as the test requires, but only because
the function splits it at the comma and `int("1.234")` happens to fail; nothing in it decided that a
price with both separators is ambiguous. A test checks what happens, not why, which is one more
reason to read a change that passes.

The tests now exist before the code that has to meet them, and they say exactly what is wrong.
Lesson 5 section 06 sends that back.
