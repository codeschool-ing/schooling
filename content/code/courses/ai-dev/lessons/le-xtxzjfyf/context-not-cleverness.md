---
title: The evidence beats the description
version: 1
---

People describe a bug in their own words: "parse_price breaks with commas". The model then has to
guess which line, which input, which error. **Paste the evidence instead**: the exact command, the
exact input and the exact traceback. It is shorter to copy than to describe, and it contains
details you would not have thought to mention.

## The traceback, as the program wrote it

```
ana@dev:~/shop$ python -c 'from shop.money import parse_price; print(parse_price("12,90"))'
Traceback (most recent call last):
  File "<string>", line 1, in <module>
  File "/home/ana/shop/shop/money.py", line 8, in parse_price
    return int(units) * 100 + int(cents)
           ^^^^^^^^^^
ValueError: invalid literal for int() with base 10: '12,90'
```

Four lines of useful facts: the file, the line, the expression `int(units) * 100`, and the value
that failed, `'12,90'`. That last part says the whole string reached `int()` as the units, so the
function never split it, because it splits on a dot. A description would have said "it crashes"; the
traceback says why.

ana saves it to a file, so it can go into the request byte for byte:

```
ana@dev:~/shop$ python -c 'from shop.money import parse_price; print(parse_price("12,90"))' 2> error.txt; cat error.txt
Traceback (most recent call last):
  File "<string>", line 1, in <module>
  File "/home/ana/shop/shop/money.py", line 8, in parse_price
    return int(units) * 100 + int(cents)
           ^^^^^^^^^^
ValueError: invalid literal for int() with base 10: '12,90'
```

## The request with the evidence

The structured prompt of lesson 5 section 02, the traceback, and three files of context: the
function, its tests and the conventions:

```
ana@dev:~/shop$ assist ask "$(cat prompts/comma.md) Traceback from running it: $(cat error.txt)" --open shop/money.py tests/test_money.py CONVENTIONS.md > comma.diff
context sent (596 of 3000 tokens):
    137  shop/money.py
     85  tests/test_money.py
    374  CONVENTIONS.md
---
ana@dev:~/shop$ cat comma.diff
diff --git a/shop/money.py b/shop/money.py
index 9af0e26..3eb6322 100644
--- a/shop/money.py
+++ b/shop/money.py
@@ -3,7 +3,7 @@
 
 def parse_price(text: str) -> int:
     """Turn a price as people write it into cents: '12.90' -> 1290."""
-    units, _, cents = text.strip().partition(".")
+    units, _, cents = text.strip().replace(",", ".").partition(".")
     cents = (cents + "00")[:2]
     return int(units) * 100 + int(cents)
 
```

**A diff of one line**, in integers, touching only `parse_price`. The reply was written by the course,
but the shape of the improvement is the general one. With the error and the rules in the context
there is much less left to guess, and the guesses that remain are about the code in front of the
model rather than about code it imagines.

## What counts as evidence

- **The error message and the traceback, unedited.** Including the parts that look irrelevant: the
  file path says which copy of the code ran.
- **The command that produced it**, so the input is exact.
- **Versions**, when the problem might be one: the library version from `pip list`, the Python
  version. Lesson 1 section 11's "API that used to exist" is answered by this line.
- **What you already tried**, so the reply does not suggest it.

And one thing to take out first: **secrets**. A traceback can carry a connection string, a log line
can carry a token. Lesson 3 section 03 applies to what you paste as much as to what an editor sends.
