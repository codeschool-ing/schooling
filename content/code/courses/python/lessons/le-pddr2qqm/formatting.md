---
title: The f-string, and what goes after the colon
version: 2
---

```python
name = "Ada"
print(f"Hello, {name}")
```
```
Hello, Ada
```

An `f` before the quote, and braces around **any expression** — not just a name:

```python
>>> f"{2 + 2}"
'4'
>>> f"{name.upper()}"
'ADA'
```

## `=` for debugging

```python
>>> total = 41
>>> f"{total=}"
'total=41'
```

The name and the value, from one character. This is the print-debugging idiom in modern Python
and it is worth the muscle memory.

## The format spec

After a colon inside the braces, you say **how**:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 272\" role=\"img\" aria-label=\"The parts of an f-string, left to right: the f that makes the braces mean something, the expression inside them, the colon that separates what from how, and the format spec that says ten wide, right aligned, with a thousands separator and two decimals.\"> <text x=\"180\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--paper-dim)\" xml:space=\"preserve\">f&quot;</text> <text x=\"204\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--paper-dim)\" xml:space=\"preserve\">{</text> <text x=\"216\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--paper)\" xml:space=\"preserve\">total</text> <text x=\"276\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--amber)\" xml:space=\"preserve\">:</text> <text x=\"288\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--phosphor)\" xml:space=\"preserve\">&gt;10,.2f</text> <text x=\"372\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--paper-dim)\" xml:space=\"preserve\">}&quot;</text> <circle cx=\"192\" cy=\"76\" r=\"9\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></circle> <text x=\"192\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1</text> <circle cx=\"246\" cy=\"76\" r=\"9\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></circle> <text x=\"246\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2</text> <circle cx=\"282\" cy=\"76\" r=\"9\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></circle> <text x=\"282\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">3</text> <circle cx=\"330\" cy=\"76\" r=\"9\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></circle> <text x=\"330\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">4</text> <path d=\"M180 96 L276 96\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path> <text x=\"228\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">what to print</text> <path d=\"M288 96 L372 96\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path> <text x=\"330\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">how to print it</text> <rect x=\"150\" y=\"152\" width=\"436\" height=\"24\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"168\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text> <text x=\"196\" y=\"164\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the f is what makes the braces mean anything</text> <rect x=\"150\" y=\"182\" width=\"436\" height=\"24\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"168\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2</text> <text x=\"196\" y=\"194\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">inside the braces, any expression at all</text> <rect x=\"150\" y=\"212\" width=\"436\" height=\"24\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"168\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">3</text> <text x=\"196\" y=\"224\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the colon separates what from how</text> <rect x=\"150\" y=\"242\" width=\"436\" height=\"24\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"168\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">4</text> <text x=\"196\" y=\"254\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">ten wide, right aligned, thousands, two decimals</text> </svg>", "caption": "Everything before the colon is what to print. Everything after it is how."}
```

```python
>>> f"{3.14159:.2f}"
'3.14'
>>> f"{1234567:,}"
'1,234,567'
>>> f"{0.734:.1%}"
'73.4%'
>>> f"{42:>8}"
'      42'
>>> f"{42:08}"
'00000042'
```

| | |
|---|---|
| `.2f` | two decimal places, fixed |
| `,` or `_` | thousands separator |
| `%` | as a percentage, and it multiplies by 100 |
| `>` `<` `^` | right, left, centre, in a width |
| `0` | pad with zeros |
| `e` | scientific |
| `b` `o` `x` | binary, octal, hex |

**The width can itself be a variable**: `f"{name:>{w}}"`.

## Braces you want to keep

Double them: `f"{{literal}}"` prints `{literal}`.

## The two older ways

You will meet both in code you did not write.

```python
"Hello, {}".format(name)     # .format, from Python 2.6
"Hello, %s" % name           # %, from the beginning
```

Both still work. Neither is worth writing now, with one honest exception: logging calls take the
`%` form on purpose, so the formatting is skipped when the message is not going to be emitted.

## What an f-string is not

It is not a template you can store and fill in later — it is evaluated where it is written. And
it is **not** how you build SQL, a shell command or HTML. `sql-databases` has a section on
exactly the hole an f-string opens there, and the answer is a parameter every time.
