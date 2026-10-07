---
title: Feeding back the evidence
version: 2
---

The first answer is rarely the last one, and the useful question is what to send back. "That's
wrong, try again" gives the model nothing new; it will produce a variation on the same guess. **Send
the evidence that it was wrong**: the failing test, the error, the output, exactly as the tools
printed them. It is the same rule as lesson 5 section 03, applied to the second round.

## The failure, verbatim

`--tb=line` makes pytest print each failure as one line, which is short enough to send:

```
ana@dev:~/shop$ python -m pytest -q --tb=line tests/test_comma.py > failure.txt; cat failure.txt
.F...                                                                    [100%]
=================================== FAILURES ===================================
E   ValueError: invalid literal for int() with base 10: '12.90'
/home/ana/shop/shop/money.py:8: ValueError: invalid literal for int() with base 10: '12.90'
=========================== short test summary info ============================
FAILED tests/test_comma.py::test_a_comma_or_a_dot_is_the_decimal_separator[12.90]
1 failed, 4 passed in 0.72s
```

## Three rounds

Each round sends the prompt, the failure and the current code, swaps the reply in and runs the
whole suite, writing the new failures to `failure.txt` for the next round. ana gives it three
rounds and stops at the first that passes:

```
ana@dev:~/shop$ python scratch/assist.py ask "$(cat prompts/comma.md) The parse_price in shop/money.py below fails these tests, which must pass: $(cat failure.txt)" --open shop/money.py tests/test_comma.py CONVENTIONS.md --write scratch/parse_price.py > /dev/null
context sent (608 of 3000 tokens):
    137  shop/money.py
     97  tests/test_comma.py
    374  CONVENTIONS.md
---
ana@dev:~/shop$ cat scratch/parse_price.py
def parse_price(text: str) -> int:
    """Turn a price as people write it into cents: '12,90' -> 1290."""
    if ',' in text and '.' in text:
        raise ValueError("Invalid decimal separator")
    units, _, cents = text.strip().partition(",")
    cents = (cents + "00")[:2]
    return int(units) * 100 + int(cents)
ana@dev:~/shop$ python scratch/swap.py shop/money.py scratch/parse_price.py && python -m pytest -q --tb=line > failure.txt; tail -n 3 failure.txt
swap: parse_price replaced in shop/money.py
FAILED tests/test_comma.py::test_a_comma_or_a_dot_is_the_decimal_separator[12.90]
FAILED tests/test_money.py::test_parse_price - ValueError: invalid literal fo...
2 failed, 11 passed in 0.70s
```

The first round added something real: a price with both a comma and a dot now raises `ValueError`
on purpose, which is what the test of `1.234,56` meant. It still splits at the comma, so `12.90`
fails as before, in the new test and in the old one. Rounds two and three:

```
ana@dev:~/shop$ python scratch/assist.py ask "$(cat prompts/comma.md) The parse_price in shop/money.py below fails these tests, which must pass: $(cat failure.txt)" --open shop/money.py tests/test_comma.py CONVENTIONS.md --write scratch/parse_price.py > /dev/null
context sent (627 of 3000 tokens):
    156  shop/money.py
     97  tests/test_comma.py
    374  CONVENTIONS.md
---
ana@dev:~/shop$ cat scratch/parse_price.py
def parse_price(text: str) -> int:
    """Turn a price as people write it into cents: '12,90' -> 1290."""
    if ',' in text and '.' in text:
        raise ValueError("Invalid decimal separator")
    units, _, cents = text.strip().partition(",")
    cents = (cents + "00")[:2]
    return int(units) * 100 + int(cents)
ana@dev:~/shop$ python scratch/swap.py shop/money.py scratch/parse_price.py && python -m pytest -q --tb=line > failure.txt; tail -n 3 failure.txt
swap: parse_price replaced in shop/money.py
FAILED tests/test_comma.py::test_a_comma_or_a_dot_is_the_decimal_separator[12.90]
FAILED tests/test_money.py::test_parse_price - ValueError: invalid literal fo...
2 failed, 11 passed in 0.73s
ana@dev:~/shop$ python scratch/assist.py ask "$(cat prompts/comma.md) The parse_price in shop/money.py below fails these tests, which must pass: $(cat failure.txt)" --open shop/money.py tests/test_comma.py CONVENTIONS.md --write scratch/parse_price.py > /dev/null
context sent (627 of 3000 tokens):
    156  shop/money.py
     97  tests/test_comma.py
    374  CONVENTIONS.md
---
ana@dev:~/shop$ cat scratch/parse_price.py
def parse_price(text: str) -> int:
    """Turn a price as people write it into cents: '12,90' -> 1290."""
    if ',' in text and '.' in text:
        raise ValueError("Invalid decimal separator")
    units, _, cents = text.strip().partition(",")
    cents = (cents + "00")[:2]
    return int(units) * 100 + int(cents)
ana@dev:~/shop$ python scratch/swap.py shop/money.py scratch/parse_price.py && python -m pytest -q --tb=line > failure.txt; tail -n 3 failure.txt
swap: parse_price replaced in shop/money.py
FAILED tests/test_comma.py::test_a_comma_or_a_dot_is_the_decimal_separator[12.90]
FAILED tests/test_money.py::test_parse_price - ValueError: invalid literal fo...
2 failed, 11 passed in 0.71s
```

**The same function, character for character, three times.** Given the code it had written and the
two tests it broke, the model returned its own code unchanged. More rounds would not have helped.
The evidence was all in the request, and the model did not act on it. A model of three billion
parameters gives out at this kind of step sooner than a large one, and when it does, the next move
is yours rather than another round.

## By hand

ana stops, as the first rule below says, and writes the function herself. It is eight lines, and the
first round's idea of refusing a price with both separators is worth keeping:

```python
def parse_price(text: str) -> int:
    """Turn a price as people write it into cents: '12.90' or '12,90' -> 1290."""
    text = text.strip()
    if "." in text and "," in text:
        raise ValueError(f"a dot and a comma in one price: {text!r}")
    units, _, cents = text.replace(",", ".").partition(".")
    cents = (cents + "00")[:2]
    return int(units) * 100 + int(cents)
```

```
ana@dev:~/shop$ git checkout -q shop/money.py && python scratch/swap.py shop/money.py scratch/parse_price.py && python -m pytest -q
swap: parse_price replaced in shop/money.py
.............                                                            [100%]
13 passed in 0.69s
```

Thirteen tests: the eight the project had and the five new ones. The tests she wrote in lesson 5
section 06 judged her code the same way they judged the model's, which is what makes them worth
writing first: they do not care who wrote the change.

## When to stop iterating

- **When the tests pass**, which is why they were written first. Without them, "done" is a feeling.
- **When the same failure comes back twice.** A model that cannot fix something on the second try,
  given the evidence, rarely fixes it on the fifth; above, it did not even change its answer. The problem
  is usually missing context (a file it has not seen) or a requirement that contradicts another. Read the code yourself, or change what
  you send.
- **When the changes grow.** A fix that touches more on each round is drifting away from the problem.
  Revert to the last good state and ask a narrower question.

Each round is a request, and lesson 2 section 06 applies: a conversation that carries every
previous attempt gets more expensive each turn. Starting a fresh request with the current code and
the current failure is often both cheaper and better.
