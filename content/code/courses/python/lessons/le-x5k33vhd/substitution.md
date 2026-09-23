---
title: `sub`, and a replacement that is a function
version: 2
---

```python
re.sub(r"\s+", " ", text)                    # collapse runs of whitespace
re.sub(r"(\d{4})-(\d{2})-(\d{2})", r"\3/\2/\1", text)     # reorder a date
```

`sub` returns a NEW string — nothing is changed in place, like every other string operation in
Python.

## Backreferences in the replacement

`\1`, `\2` and so on are the groups; `\g<year>` is a named one. The replacement is a raw string
too, for the same reason the pattern is.

```python
re.sub(r"(?P<user>\w+)@example\.tld", r"\g<user>@example.com", text)
```

**`\g<1>` is the form to use when a digit follows**: `\1 0` and `\g<1>0` differ, and the first one
is a group called 10.

## A function as the replacement

```python
def redact(m):
    return m.group(0)[:2] + "…"

re.sub(r"\b\w+@\S+\b", redact, text)
```

When the replacement is a function it is called once per match, with the `Match`, and whatever it
returns is inserted. That is where `sub` stops being find-and-replace and becomes a program: you
can look the value up, convert it, count it, or decide to leave it alone by returning
`m.group(0)`.

## `count`, and `subn`

```python
re.sub(pattern, repl, text, count=1)      # only the first
new, n = re.subn(pattern, repl, text)     # and how many were replaced
```

`subn` gives the count, which is how you find out that a substitution you expected to happen did
not.

## The one to be careful with

```python
re.sub(r".*", "x", "abc")        # 'xx'
```

`.*` matches `abc` and then matches the empty string at the end, so the replacement happens
twice. Patterns that can match nothing behave strangely in `sub`, and the fix is `+` or a shape
that requires at least one character.
