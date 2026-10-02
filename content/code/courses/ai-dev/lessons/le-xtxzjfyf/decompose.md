---
title: One step at a time
version: 1
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

ana starts again from the original `parse_price` and asks for the steps only:

```
ana@dev:~/shop$ git checkout -q shop/money.py && git status --short
?? comma.diff
?? error.txt
?? lab/
?? prompts/
ana@dev:~/shop$ assist ask "We need parse_price to accept a decimal comma. Do not write code yet: list the steps, with the tests first." --open shop/money.py CONVENTIONS.md 2>/dev/null
1. Write the tests first, from what the change must do: '12,90' and '12,9' parse like '12.90' and '12.9', the existing dot keeps working, and '1.234,56' is refused, because a dot and a comma in one price leave no way to tell which is the decimal separator.
2. Change parse_price to read a comma as the decimal separator, keeping the arithmetic in integers as CONVENTIONS.md requires.
3. Run the whole suite, not only the new tests.

```

The plan, written by the course, puts the tests first and names the case nobody had mentioned:
`1.234,56`, where a dot and a comma in one price leave no way to tell which is the decimal separator.
**A plan is cheap to read and cheap to correct.** If it had said "convert to float", that would have
been one sentence to strike out rather than a diff to unpick.

## The tests, from the plan, by hand

ana writes the tests herself, from the plan's list of cases, deciding the expected values:

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

Run before the change, they should fail, and they do (lesson 5 section 05's last rule):

```
ana@dev:~/shop$ python -m pytest -q tests/test_comma.py 2>&1 | tail -3
FAILED tests/test_comma.py::test_a_comma_or_a_dot_is_the_decimal_separator[ 12,90 ]
FAILED tests/test_comma.py::test_a_price_with_both_a_dot_and_a_comma_is_refused
4 failed, 1 passed in 0.54s
```

## The change

The diff from lesson 5 section 03, applied:

```
ana@dev:~/shop$ git apply comma.diff && python -m pytest -q tests/test_comma.py
....F                                                                    [100%]
=================================== FAILURES ===================================
_____________ test_a_price_with_both_a_dot_and_a_comma_is_refused ______________

    def test_a_price_with_both_a_dot_and_a_comma_is_refused():
>       with pytest.raises(ValueError):
E       Failed: DID NOT RAISE ValueError

tests/test_comma.py:12: Failed
=========================== short test summary info ============================
FAILED tests/test_comma.py::test_a_price_with_both_a_dot_and_a_comma_is_refused
1 failed, 4 passed in 0.52s
```

Four of five. The comma works, the dot still works, and `1.234,56` is accepted when the plan said it
must be refused. The one-line diff turns the comma into a dot and splits on the first dot, so it
reads `1.234,56` as one unit and twenty-three cents, quietly. **The test written from the plan caught
what the diff written from the error did not consider.** That is the value of the order: the
requirement existed, as a test, before the code that had to meet it.
