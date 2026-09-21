---
title: The assertion is rewritten, and both values are printed
version: 1
---

```python
def test_keeps_punctuation():
    assert slugify("Hello, World") == "hello-world"
```

```text
=================================== FAILURES ===================================
____________________________ test_keeps_punctuation ____________________________

    def test_keeps_punctuation():
>       assert slugify("Hello, World") == "hello-world"
E       AssertionError: assert 'hello,-world' == 'hello-world'
E
E         - hello-world
E         + hello,-world
E         ?      +

test_slug.py:8: AssertionError
```

**A bare `assert` in Python tells you nothing** — it raises `AssertionError` with no message. So
`pytest` rewrites the assertions in your test files as it imports them, keeping hold of the
operands, and prints both when one fails.

That rewriting is the reason a bare `assert` is enough here, and it happens only in files
`pytest` collected — an assertion in your application code stays as bare as it was written.

## Reading the block

`>` marks the line that failed. The `E` lines are the explanation: the rendered comparison, then a
diff where `-` is what was expected and `+` is what arrived, with a `?` line pointing at the
character that differs. The last line is the location.

## And the summary at the bottom

```text
=========================== short test summary info ============================
FAILED test_slug.py::test_keeps_punctuation - AssertionError: assert 'hello,...
========================= 1 failed, 1 passed in 0.02s ==========================
```

**Read the report from the bottom.** On a suite with thirty failures the top of the output is the
first one, which is rarely the interesting one, and the summary gives you every name in four
lines.

## What it will not print

```python
def test_float():
    assert 0.1 + 0.2 == 0.3
```

```text
E       assert (0.1 + 0.2) == 0.3
```

Here the rewriting shows the expression rather than its value, and `0.30000000000000004` — which
is the actual answer and the whole reason the test fails — does not appear. That is the case
`approx` exists for, two sections along.
