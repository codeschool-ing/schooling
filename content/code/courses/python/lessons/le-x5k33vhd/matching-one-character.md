---
title: What character, and the classes worth memorising
version: 2
---

Most characters match themselves. `cat` matches `cat`. The interesting ones are the rest.

## The dot

`.` matches any character except a newline. That exception matters when you are working line by
line and surprises people who are not — `re.DOTALL` turns it off.

## Classes

| class | matches |
|---|---|
| `[aeiou]` | any one of those |
| `[a-z]` | any lowercase letter |
| `[a-zA-Z0-9]` | a letter or a digit |
| `[^0-9]` | anything that is NOT a digit |

Square brackets are a set of characters, and ONE of them matches. The `^` at the START of a class
negates it; anywhere else it is a literal `^`.

## The shorthands

| shorthand | means | negation |
| --- | --- | --- |
| `\d` | a digit | `\D` |
| `\w` | a letter, digit or underscore | `\W` |
| `\s` | a space, tab or newline | `\S` |

`\w` includes accented letters in Python 3 by default, which is right for `ção` and surprising if
you expected ASCII. `re.ASCII` narrows it.

## Escaping, inside and outside

```python
r"\."          # a literal dot
r"[.]"         # also a literal dot — inside a class, most things are literal
r"[\d.]"       # a digit or a dot
r"[a\-z]"      # a, a hyphen, or z — the escape makes the hyphen literal
```

**Inside a class almost nothing is special**, which is why `[.]` needs no backslash. The
exceptions are `]`, `\`, `^` at the start, and `-` between two characters — and putting the
hyphen first or last avoids the question entirely: `[-a-z]`.

## `re.escape`

```python
pattern = re.escape(user_input)
```

When the text comes from somewhere else, every character in it must be taken literally. `re.escape`
does that, and writing the backslashes yourself is how a dot in somebody's name becomes a wildcard.
