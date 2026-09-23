---
title: Anchors, and the two functions that are not the same
version: 2
---

| anchor | matches |
|---|---|
| `^` | the start of the string (or of a line, with `re.MULTILINE`) |
| `$` | the end of the string (or of a line) |
| `\b` | a word boundary |
| `\A` `\Z` | the start and end of the STRING, whatever `MULTILINE` says |

## `\b`

```python
re.search(r"\bcat\b", "the cat sat")      # matches
re.search(r"\bcat\b", "concatenate")      # does not
```

A word boundary is the place between a `\w` and a non-`\w`. It is what turns "contains" into
"contains as a word", and it is the single most useful anchor.

## `match` against `search`

```python
re.match(r"\d+", "abc 123")       # None  — anchored at the start
re.search(r"\d+", "abc 123")      # '123' — anywhere
re.fullmatch(r"\d+", "123 ")      # None  — must cover the whole string
```

**`match` is anchored at the beginning and `search` is not.** That is the whole difference, and
it is the most common confusion in the module — `re.match(r"error", line)` looking for a level
in the middle of a line finds nothing and says nothing.

`match` is NOT anchored at the end: `re.match(r"\d+", "123abc")` matches happily. `fullmatch` is
the one that requires the whole string, and it is what you want for validating a field.

## `$` and the trailing newline

```python
re.search(r"\d$", "42\n")        # matches
```

`$` matches at the end of the string AND just before a final newline. That is convenient when
reading lines and surprising when validating — `\Z` is the strict version, and `fullmatch` avoids
the question.

## `re.MULTILINE`

```python
re.findall(r"^ERROR.*", text, re.MULTILINE)
```

Makes `^` and `$` mean the start and end of each LINE rather than of the whole string. Without
it, a pattern anchored with `^` finds at most one match in a multi-line string — which reads as
the pattern being wrong.
