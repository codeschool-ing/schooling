---
title: Six classes, and what each is telling you
version: 1
---

## `ValueError`

The type is right and the value is not. `int("abc")`, `date(2026, 13, 1)`, a percentage of 150.

**It nearly always means the data came from outside** — a file, a form, an argument — so the
handler usually names which field and which value rather than fixing anything.

## `TypeError`

The type is wrong. `len(5)`, `"a" + 1`, calling something that is not callable, a function given
three arguments when it takes two.

**This one is usually YOUR bug rather than the data's.** Catching it is rarely the answer; the
traceback is.

## `KeyError` and `IndexError`

A key that is not in the dictionary, a position that is not in the sequence. Both are
`LookupError` underneath, so one clause can take both.

`KeyError` says the key in its message and nothing else, which is confusing the first time:
`KeyError: 'port'` is the whole story. And remember `.get(key, default)`, which is the forgiving
version of the same question.

## `FileNotFoundError`, and its family

`OSError` is the filesystem and the operating system, and the useful children are
`FileNotFoundError`, `PermissionError` and `IsADirectoryError`. `except OSError` catches all of
them, which is right when your answer is the same for each.

**The message carries the path**, so a handler rarely needs to add it — check before you write
`f"could not open {path}"` around something that already said so.

## `AttributeError`

The object has no such attribute. `None.strip()` raises it, and that is by far the most common
cause: something returned `None` and you used it as if it had not.

**`AttributeError: 'NoneType' object has no attribute …` means "the value was `None`"**, and the
question is which line produced the `None`, not what to do about this one.

## `ZeroDivisionError`, and a note on the rest

There are dozens more and you do not learn them from a list. You learn them by reading the ones
you get: the class says what kind, the message says which, and the last line of the traceback
says where.

**Reading a traceback from the BOTTOM up is the skill.** The last line is the error; the line
above it is where it happened; everything above that is how you got there — and the first line
of yours in that list is where to look.
