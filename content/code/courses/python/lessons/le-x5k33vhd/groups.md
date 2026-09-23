---
title: Parentheses, and getting something back
version: 2
---

```python
m = re.search(r"(\d{4})-(\d{2})-(\d{2})", line)
m.group(0)      # the whole match
m.group(1)      # '2026'
m.groups()      # ('2026', '09', '21')
```

Parentheses CAPTURE. `group(0)` is everything the pattern matched; the rest are numbered left to
right by their opening bracket.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 256\" role=\"img\" aria-label=\"The line with the whole match bracketed above it and the three captured groups bracketed below, numbered one to three by their opening bracket, left to right.\"> <text x=\"360\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">(\\d{4})-(\\d{2})-(\\d{2})</text> <text x=\"180\" y=\"76\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"17\" fill=\"var(--paper)\" xml:space=\"preserve\">order 2026-09-21 ok</text> <path d=\"M246 56 L246 46 L356 46 L356 56\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path> <text x=\"372\" y=\"46\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper-dim)\">m.group(0)</text> <path d=\"M246 94 L246 104 L290 104 L290 94\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path> <circle cx=\"268\" cy=\"122\" r=\"9\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></circle> <text x=\"268\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text> <text x=\"268\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">'2026'</text> <path d=\"M301 94 L301 104 L323 104 L323 94\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path> <circle cx=\"312\" cy=\"122\" r=\"9\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></circle> <text x=\"312\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2</text> <text x=\"312\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">'09'</text> <path d=\"M334 94 L334 104 L356 104 L356 94\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path> <circle cx=\"345\" cy=\"122\" r=\"9\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></circle> <text x=\"345\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">3</text> <text x=\"345\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">'21'</text> <text x=\"360\" y=\"190\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Name them the moment there are more than two: m[&quot;year&quot;] survives an inserted group</text> <text x=\"360\" y=\"207\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">and m.group(3) is a number somebody has to count brackets to check.</text> </svg>", "caption": "Group zero is everything the pattern matched. The rest are numbered by their opening bracket — which is why inserting one at the front renumbers the others, silently."}
```

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
