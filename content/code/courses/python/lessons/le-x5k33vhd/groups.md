---
title: Parentheses, and getting something back
version: 1
---

```python
m = re.search(r"(\d{4})-(\d{2})-(\d{2})", line)
m.group(0)      # the whole match
m.group(1)      # '2026'
m.groups()      # ('2026', '09', '21')
```

Parentheses CAPTURE. `group(0)` is everything the pattern matched; the rest are numbered left to
right by their opening bracket.

## Named groups

```python
m = re.search(r"(?P<year>\d{4})-(?P<month>\d{2})", line)
m["year"]              # '2026'
m.group("month")       # '09'
m.groupdict()          # {'year': '2026', 'month': '09'}
```

**Name them the moment there are more than two.** `m.group(3)` is a number somebody has to count
by finding the third opening bracket, and inserting a group at the front renumbers everything
after it — silently.

## Non-capturing

```python
r"(?:https?)://(\S+)"
```

`(?:…)` groups without capturing, which is what you want when the parentheses are there for the
`?` or the `|` rather than to collect something. It keeps the numbering of the groups you DO want
stable.

## A group that did not participate

```python
m = re.match(r"(\+\d+ )?(\d+)", "5551234")
m.group(1)       # None, not ''
```

An optional group that was not there gives `None`. `m.group(1) or ""` is the usual answer, and
forgetting it is an `AttributeError` on `None` a few lines later.

## Alternation

```python
r"ERROR|WARN|INFO"
r"(?:ERROR|WARN|INFO)"        # when it is part of something bigger
```

`|` has the LOWEST precedence of anything in the language, so `^ERROR|WARN$` means "starts with
ERROR" or "ends with WARN" — almost never what was meant. Parenthesise it.
