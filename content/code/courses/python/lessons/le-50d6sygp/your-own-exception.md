---
title: A class, and when it is worth one
version: 1
---

```python
class ConfigError(Exception):
    """The configuration file could not be used."""
```

That is the whole definition. It inherits `Exception`, it has a docstring saying what it means,
and it needs no body.

## When it is worth defining

**When a caller might want to catch exactly your failure and nothing else.** That is the test,
and it is about the caller rather than about you.

A library that reads configuration should raise `ConfigError`, because the program above it wants
to say "your config is wrong" and exit 2 — and it cannot do that if what arrives is a `ValueError`
indistinguishable from any other.

A script that reads its own file does not need one. `ValueError` is fine, because nobody is
catching it.

## A base class per package

```python
class ReportError(Exception): ...
class ConfigError(ReportError): ...
class SourceError(ReportError): ...
```

One base, and the specific ones below it. Now a caller writes `except ReportError` to mean
"anything this library says went wrong", or names the specific one when it can do something
different about it. **This is the hierarchy from the first section, built for your own code.**

## Carrying data

```python
class RowError(Exception):
    def __init__(self, row, message):
        super().__init__(f"row {row}: {message}")
        self.row = row
```

The message is for a person; the attribute is for a program. A handler that wants to collect the
bad row numbers needs `e.row`, and parsing it back out of the message is the thing this avoids.

Call `super().__init__(...)` so the message reaches `str(e)` — an exception whose `str` is empty
is one a log will print as a blank line.

## What not to do

**Do not inherit from `BaseException`.** That puts your class beside `KeyboardInterrupt`, outside
every `except Exception` anybody has written.

And do not define fifteen of them for one program. Each one is a name a reader has to learn, and
most code needs one or two.
