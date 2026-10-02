---
title: Feeding back the evidence
version: 1
---

The first answer is rarely the last one, and the useful question is what to send back. "That's
wrong, try again" gives the model nothing new; it will produce a variation on the same guess. **Send
the evidence that it was wrong**: the failing test, the error, the output, exactly as the tools
printed them. It is the same rule as lesson 5 section 03, applied to the second round.

## The failure, verbatim

```
ana@dev:~/shop$ python -m pytest -q tests/test_comma.py 2>&1 | grep -A3 "def test_a_price_with_both" | head -4; python -m pytest -q tests/test_comma.py 2>&1 | tail -2 > failure.txt
    def test_a_price_with_both_a_dot_and_a_comma_is_refused():
>       with pytest.raises(ValueError):
E       Failed: DID NOT RAISE ValueError

```

ana sends the failure back with the requirement it breaks, stated once, and asks for a diff against
the file as it is now, since the first diff has been applied:

```
ana@dev:~/shop$ assist ask "Your change to parse_price fails this test, which must pass: parse_price(\"1.234,56\") must raise ValueError. pytest says: $(cat failure.txt). Reply with a unified diff against the current shop/money.py." --open shop/money.py tests/test_comma.py > second.diff
context sent (238 of 3000 tokens):
    141  shop/money.py
     97  tests/test_comma.py
---
ana@dev:~/shop$ cat second.diff
diff --git a/shop/money.py b/shop/money.py
index 3eb6322..b9a7ed0 100644
--- a/shop/money.py
+++ b/shop/money.py
@@ -2,8 +2,11 @@
 
 
 def parse_price(text: str) -> int:
-    """Turn a price as people write it into cents: '12.90' -> 1290."""
-    units, _, cents = text.strip().replace(",", ".").partition(".")
+    """Turn a price as people write it into cents: '12.90' or '12,90' -> 1290."""
+    text = text.strip().replace(",", ".")
+    units, _, cents = text.partition(".")
+    if not units.lstrip("-").isdigit() or not (cents == "" or cents.isdigit()) or len(cents) > 2:
+        raise ValueError(f"not a price: {text!r}")
     cents = (cents + "00")[:2]
     return int(units) * 100 + int(cents)
 

```

The second diff, written by the course, keeps the comma handling and adds the check the plan
asked for: units of digits only, cents of at most two digits, otherwise `ValueError`. Applied, with
the whole suite run, not just the new file:

```
ana@dev:~/shop$ git apply second.diff && python -m pytest -q
.............                                                            [100%]
13 passed in 0.55s
```

Thirteen tests: the eight the project had and the five new ones.

## When to stop iterating

- **When the tests pass**, which is why they were written first. Without them, "done" is a feeling.
- **When the same failure comes back twice.** A model that cannot fix something on the second try,
  given the evidence, rarely fixes it on the fifth. The problem is usually missing context (a file it
  has not seen) or a requirement that contradicts another. Read the code yourself, or change what
  you send.
- **When the diffs grow.** A fix that touches more on each round is drifting away from the problem.
  Revert to the last good state and ask a narrower question.

Each round is a request, and lesson 2 section 06 applies: a conversation that carries every
previous attempt gets more expensive each turn. Starting a fresh request with the current code and
the current failure is often both cheaper and better.
