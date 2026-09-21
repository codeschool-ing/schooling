---
title: Greedy by default, and the character that fixes it
version: 1
---

```
*        zero or more
+        one or more
?        zero or one
{3}      exactly three
{2,4}    two to four
{2,}     two or more
```

Each applies to the thing immediately before it: `ab+` is an `a` and one or more `b`s;
`(ab)+` is one or more `ab`s.

## Greedy

**`*` and `+` take as much as they can**, then give characters back one at a time until the rest
of the pattern fits.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 266\" role=\"img\" aria-label=\"The same string matched by a greedy pattern and a lazy one. The greedy star takes everything up to the last closing bracket, because that still fits the pattern. The lazy star stops at the first one.\"> <text x=\"40\" y=\"34\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">greedy</text> <text x=\"40\" y=\"78\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"15\" fill=\"var(--amber)\">&lt;(.*)&gt;</text> <text x=\"160\" y=\"78\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" fill=\"var(--paper)\" xml:space=\"preserve\">&lt;a&gt; and &lt;b&gt;</text> <rect x=\"170.8\" y=\"92\" width=\"97.2\" height=\"5\" rx=\"2\" fill=\"var(--amber)\"></rect> <text x=\"420\" y=\"78\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\">'a&gt; and &lt;b'</text> <text x=\"40\" y=\"134\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">lazy</text> <text x=\"40\" y=\"178\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"15\" fill=\"var(--phosphor)\">&lt;(.*?)&gt;</text> <text x=\"160\" y=\"178\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" fill=\"var(--paper)\" xml:space=\"preserve\">&lt;a&gt; and &lt;b&gt;</text> <rect x=\"170.8\" y=\"192\" width=\"10.8\" height=\"5\" rx=\"2\" fill=\"var(--phosphor)\"></rect> <text x=\"420\" y=\"178\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">'a'</text> <text x=\"360\" y=\"218\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">The greedy one is right about the question it was asked: everything up to the last</text> <text x=\"360\" y=\"235\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">closing bracket is more than everything up to the first, and the pattern still fitted.</text> </svg>", "caption": "Neither is a bug. A star takes as much as it can and gives characters back only until the rest of the pattern fits; a question mark reverses which end it starts from."}
```

```python
re.search(r"<(.*)>", "<a> and <b>").group(1)      # 'a> and <b'
```

That is not a bug. `.*` matched everything up to the last `>`, because everything up to the last
`>` is more than everything up to the first — and the pattern still fitted.

## Lazy

```python
re.search(r"<(.*?)>", "<a> and <b>").group(1)     # 'a'
```

`*?` and `+?` take as LITTLE as they can, then add one character at a time until the rest fits.
One question mark, and the meaning reverses.

## And the better answer

```python
re.search(r"<([^>]*)>", "<a> and <b>").group(1)   # 'a'
```

"Anything that is not a `>`" says what you meant, cannot run past the closing bracket, and does
not depend on the reader knowing which kind of quantifier this is. **Describing the shape beats
tuning the greed**, and it is faster too.

## `?` after a group

```python
r"colou?r"          # color or colour
r"(\+\d{1,3} )?"    # an optional country code, present or not
```

The optional group is how a pattern handles "this part may not be there" — and when it is
absent, its group is `None` rather than an empty string, which is a check somebody forgets.

## The one that is always wrong

```python
r".*"
```

Alone, it matches everything, including nothing. Inside a pattern it is the greedy trap above.
**If your pattern contains `.*` and you are not sure why, that is the line to look at first.**
