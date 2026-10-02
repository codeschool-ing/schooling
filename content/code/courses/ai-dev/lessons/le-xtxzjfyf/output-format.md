---
title: Ask for an answer a program can check
version: 1
---

A reply in prose is read by a person, and a person skims. **A reply in a format a tool understands
can be checked before anybody reads it**: a diff can be tried against the code, JSON can be parsed
and validated, a test file can be run. Asking for that format is the cheapest quality check there
is, because the check already exists.

## A diff, checked before it is applied

`comma.diff` from lesson 5 section 03 is a unified diff. `git apply --check` tries it against the
working tree without changing anything:

```
ana@dev:~/shop$ git apply --check comma.diff && echo "applies cleanly"
applies cleanly
```

A diff that does not match the code, because it was written against a version of the file that is
not the one on disk, or because a line in it was invented, is refused the same way. Here the same
diff with one context line altered, the kind of slip a model makes when it quotes code from memory:

```
ana@dev:~/shop$ sed 's/^-    units/-    unit/' comma.diff | git apply --check
error: patch failed: shop/money.py:3
error: shop/money.py: patch does not apply
```

**The check fails, and nothing was changed.** A reply that had been the whole function in prose
would have been pasted over the real one, and the difference would have been found later, if at all.
The good diff goes in, and the suite runs:

```
ana@dev:~/shop$ git apply comma.diff && python -m pytest -q
........                                                                 [100%]
8 passed in 0.48s
```

## Formats worth asking for

| task | format | the check |
|---|---|---|
| a change to existing code | a unified diff | `git apply --check`, then the tests |
| new code | one complete file or one function | it imports, the linter passes, the tests run |
| data extracted from text | JSON matching a schema | parse it and validate it (lesson 8) |
| a decision | one word from a fixed list | is it in the list? |
| tests | a test file | it runs, and fails on the code before the change |

**Say "and nothing else"** when a program is going to read the reply. An answer that starts with
"Sure, here is the diff:" is not a diff, and the parser that expected one either fails or, worse,
skips the first line and carries on.

The last row deserves its own sentence: **a generated test should fail before the change it tests**.
A test that passes on the old code checks nothing about the new code, which lesson 4 section 04 found
the long way.
