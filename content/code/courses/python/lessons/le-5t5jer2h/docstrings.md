---
title: The first statement of the body
version: 1
---

```python
def split_rows(text, separator=","):
    """Split text into rows of fields.

    Blank lines are skipped. The separator is not escaped — see lesson 9 for
    anything that came out of a spreadsheet.
    """
```

A string literal as the first statement of a function is its docstring. It is not a comment:
it is kept on the function as `__doc__`, `help(split_rows)` prints it, and your editor shows it
where the function is called.

## The three lines worth writing

1. **One line, imperative, saying what it does.** "Split text into rows of fields" — not "This
   function will split…", which spends four words saying it is a function.
2. **What is not obvious**: what happens to the empty case, which errors it raises, which
   argument is a unit rather than a count.
3. **Nothing else.** A docstring restating the parameter names is a second copy of the signature
   that goes stale on the first rename.

## When to skip it

A three-line private helper with a name that says what it does needs no docstring, and adding one
is noise somebody has to maintain. **A function whose name needs a docstring to be understood
probably needs a better name.**

## `"""` even for one line

The triple quotes are the convention whatever the length, so that adding a second line later is
not a change to the first one.

## What reads it

`help()` at the interpreter. Your editor, on hover and at the call site. `pydoc`. And in lesson
16, `doctest` — which takes the examples written inside a docstring and RUNS them, so a
docstring that has drifted from the code fails the test suite rather than misleading whoever
reads it.
