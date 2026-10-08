---
title: Ask for an answer a program can check
version: 2
---

A reply in prose is read by a person, and a person skims. **A reply in a format a tool understands
can be checked before anybody reads it**: a diff can be tried against the code, JSON can be parsed
and validated, a test file can be run. Asking for that format is the cheapest quality check there
is, because the check already exists.

## A diff, checked before it is applied

`comma.diff` from lesson 5 section 03 is meant to be a unified diff. `git apply --check` tries a
diff against the working tree without changing anything:

```
ana@dev:~/shop$ git apply --check comma.diff && echo "applies cleanly"
error: corrupt patch at line 11
```

**Refused, and nothing was changed.** A unified diff is a strict format: each hunk's header says how
many lines of the old file it covers and how many of the new, and the body has to match those
numbers and the file. The reply's header said six and seven, and its body was seven lines of
unchanged context with no line added at all. The lines never add up to what the header promised,
and git calls the patch corrupt at line 11, which is the end of the file.
Small models get these numbers wrong more often than not, because writing a diff means counting
lines that are not on the page. Every diff `llama3.2:3b` wrote while this lesson was being
prepared was refused the same way.

That is the format doing its job. A reply that had been the whole file in prose would have been
pasted over the real one, and the damage found later, if at all.

## A function, checked by swapping it in

A format the model writes reliably, and a program can still check, is the function on its own. ana
changes the last line of the prompt:

```
ana@dev:~/shop$ sed -i 's/^Answer with: .*/Answer with: only the new parse_price function, in one block of code, and nothing else./' prompts/comma.md && tail -n 1 prompts/comma.md
Answer with: only the new parse_price function, in one block of code, and nothing else.
```

and writes the check: a short program that puts one function in place of the function of the same
name, and refuses anything that is not exactly one function. It is what an editor's Apply button
should do, and `ast`, Python's own parser, does the hard part:

```python
"""Put a function from one file in place of the function of the same name in another.

    python scratch/swap.py TARGET NEW

NEW must hold exactly one function and nothing else, and TARGET must already
have a function of that name at the top level. Anything else is refused before
TARGET is touched, which is the check an Apply button should make.
"""
import ast
import sys

target, new = sys.argv[1], sys.argv[2]
code = open(new).read()
tree = ast.parse(code)
if len(tree.body) != 1 or not isinstance(tree.body[0], ast.FunctionDef):
    sys.exit(f"swap: {new} is not one function and nothing else")
name = tree.body[0].name
lines = open(target).read().split("\n")
old = [f for f in ast.parse("\n".join(lines)).body if isinstance(f, ast.FunctionDef) and f.name == name]
if not old:
    sys.exit(f"swap: {target} has no function called {name}")
lines[old[0].lineno - 1:old[0].end_lineno] = code.rstrip("\n").split("\n")
open(target, "w").write("\n".join(lines))
print(f"swap: {name} replaced in {target}")
```

The same request, with the new last line, and the reply's block written to
`scratch/parse_price.py`:

```
ana@dev:~/shop$ python scratch/assist.py ask "$(cat prompts/comma.md) Traceback from running it: $(cat error.txt)" --open shop/money.py tests/test_money.py CONVENTIONS.md --write scratch/parse_price.py > /dev/null
context sent (596 of 3000 tokens):
    137  shop/money.py
     85  tests/test_money.py
    374  CONVENTIONS.md
---
ana@dev:~/shop$ cat scratch/parse_price.py
def parse_price(text: str) -> int:
    """Turn a price as people write it into cents: '12,90' -> 1290."""
    units, _, cents = text.strip().partition(",")
    cents = (cents + "00")[:2]
    return int(units) * 100 + int(cents)
ana@dev:~/shop$ python scratch/swap.py shop/money.py scratch/parse_price.py && git diff
swap: parse_price replaced in shop/money.py
diff --git a/shop/money.py b/shop/money.py
index 9af0e26..d22f18f 100644
--- a/shop/money.py
+++ b/shop/money.py
@@ -2,8 +2,8 @@
 
 
 def parse_price(text: str) -> int:
-    """Turn a price as people write it into cents: '12.90' -> 1290."""
-    units, _, cents = text.strip().partition(".")
+    """Turn a price as people write it into cents: '12,90' -> 1290."""
+    units, _, cents = text.strip().partition(",")
     cents = (cents + "00")[:2]
     return int(units) * 100 + int(cents)
 
```

`swap` accepted it, and `git diff` shows exactly what changed: two lines, the docstring, which now
says `'12,90'`, and the split, now on a comma. The checks the prompt named in "Done when" settle the rest in a second:

```
ana@dev:~/shop$ python -c 'from shop.money import parse_price; print(parse_price("12,90"), parse_price("12,9"), parse_price("12.90"))'
Traceback (most recent call last):
  File "<string>", line 1, in <module>
  File "/home/ana/shop/shop/money.py", line 8, in parse_price
    return int(units) * 100 + int(cents)
           ^^^^^^^^^^
ValueError: invalid literal for int() with base 10: '12.90'
ana@dev:~/shop$ python -m pytest -q
......F.                                                                 [100%]
=================================== FAILURES ===================================
_______________________________ test_parse_price _______________________________

    def test_parse_price():
>       assert parse_price("12.90") == 1290
               ^^^^^^^^^^^^^^^^^^^^

tests/test_money.py:5: 
_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ 

text = '12.90'

    def parse_price(text: str) -> int:
        """Turn a price as people write it into cents: '12,90' -> 1290."""
        units, _, cents = text.strip().partition(",")
        cents = (cents + "00")[:2]
>       return int(units) * 100 + int(cents)
               ^^^^^^^^^^
E       ValueError: invalid literal for int() with base 10: '12.90'

shop/money.py:8: ValueError
=========================== short test summary info ============================
FAILED tests/test_money.py::test_parse_price - ValueError: invalid literal fo...
1 failed, 7 passed in 0.66s
```

**The function now splits on a comma instead of a dot**, so `12.90` breaks where `12,90` used to,
and the project's own test of `parse_price` fails. The format did what it was asked for. The reply
could be read by a program, put in place by a program and judged by the tests within a second of
arriving, which is the point: nobody had to read it carefully to find out it was wrong. Lesson 5
section 06 comes back to this function.

## Formats worth asking for

| task | format | the check |
|---|---|---|
| a change to existing code | a unified diff, from a model that writes them well | `git apply --check`, then the tests |
| a change to one function | the function, whole | it parses, `swap` puts it in, the tests run |
| new code | one complete file or one function | it imports, the linter passes, the tests run |
| data extracted from text | JSON matching a schema | parse it and validate it (lesson 8) |
| a decision | one word from a fixed list | is it in the list? |
| tests | a test file | it runs, and fails on the code before the change |

**Say "and nothing else"** when a program is going to read the reply. An answer that starts with
"Sure, here is the function:" is not a function, and the parser that expected one either fails or,
worse, skips the first line and carries on. `assist --write` is forgiving here, since it takes the
first block of code wherever it is; most programs are not.

The last row deserves its own sentence: **a generated test should fail before the change it tests**.
A test that passes on the old code checks nothing about the new code, which lesson 4 section 04 found
the long way.
