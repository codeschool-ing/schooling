---
title: Three jobs a string method already does
version: 1
---

The first question about a regular expression is whether you need one.

## The three

```python
"error" in line                       # not re.search(r"error", line)
line.startswith("2026-")              # not re.match(r"2026-", line)
line.split(",")                       # not re.split(r",", line)
```

Each pattern above works, is slower, and is harder to read than the method beside it. `replace`
belongs in the list too: replacing a fixed string with another fixed string is not a job for
`re.sub`.

**The test is whether there is VARIATION in what you are looking for.** A fixed string has none,
and a string method is the honest answer.

## Where a pattern earns its keep

- a log line with a timestamp, a level and a message
- a phone number written six different ways
- every URL in a page of text
- a date somebody typed, in one of three formats
- a field that is digits, or is empty, or is `N/A`

Those are shapes with variation in them, and describing the variation is exactly what this
language does.

## HTML, which is the famous wrong answer

```python
re.findall(r"<div>(.*?)</div>", html)     # no
```

It works on the example and fails on a `<div>` inside a `<div>`. Nested structures are not a
shape a regular expression can describe — this is a fact about the language, not a challenge,
and no amount of cleverness fixes it.

The same applies to anything with nesting or quoting rules of its own: JSON, CSV, source code,
XML. Each has a parser, and lessons 9 and 21 have the two you will need.

## And the rule of thumb for length

**A pattern that does not fit on one line is a parser somebody wrote by accident.** Break the
job into steps — split the line, then match the piece — and every step stays something a person
can check.
