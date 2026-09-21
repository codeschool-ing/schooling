---
title: `r""`, and the pattern used in a loop
version: 1
---

```python
re.search("\\d+", s)       # what Python passes: \d+
re.search(r"\d+", s)       # the same, without the doubling
```

A backslash is an escape to Python BEFORE the pattern ever reaches `re`. Without the `r`, every
backslash in the pattern has to be written twice — and the day you forget, `"\b"` is a backspace
character rather than a word boundary, and the pattern silently matches nothing.

**Write every pattern as a raw string, including the ones with no backslash in them yet.** The
one you add later is the one that breaks.

The same goes for the REPLACEMENT in `sub`, where `\1` has the same problem.

## `re.compile`

```python
LINE = re.compile(r"(?P<ts>\S+) (?P<level>\w+) (?P<msg>.*)")

for line in f:
    m = LINE.match(line)
```

A compiled pattern is an object with the same methods — `search`, `match`, `findall`, `sub`. Two
reasons to use it:

- **the pattern gets a name**, at the top of the file, where a reader can find it
- **the flags belong to it**, rather than being repeated at every call

The speed argument is weaker than people think: the module caches compiled patterns, so a loop
calling `re.search` is not recompiling every time. Compile for the name.

## `re.VERBOSE`, for a pattern worth explaining

```python
LINE = re.compile(r"""
    (?P<ts>\d{4}-\d{2}-\d{2})    # the date
    \s+
    (?P<level>\w+)               # ERROR, WARN, INFO
    \s+
    (?P<msg>.*)                  # everything else
""", re.VERBOSE)
```

`re.VERBOSE` ignores whitespace and everything after a `#`, so a long pattern can be laid out and
commented. A literal space then has to be written `\ ` or `[ ]` — which is the cost, and it is
worth paying for any pattern you had to think about.
