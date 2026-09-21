---
title: Read it from the bottom
version: 1
---

This is the most useful section in the lesson and possibly in the first half of the course.

When Python cannot do what a line says, it stops and prints a **traceback**. It looks like a wall.
It is four facts in a fixed order, and the order is upside down on purpose.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"The five lines of a traceback with the order to read them in. The last line is the first thing to read: it says what happened. The line above the source says where. The top line is the chain of calls that led there, and in a one-file program it says nothing you need.\"> <defs><marker id=\"ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <defs><marker id=\"ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs> <rect x=\"20\" y=\"24\" width=\"420\" height=\"134\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <text x=\"32\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\" xml:space=\"preserve\">Traceback (most recent call last):</text> <text x=\"32\" y=\"68\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\" xml:space=\"preserve\">  File &quot;/home/ada/greet.py&quot;, line 2, in &lt;module&gt;</text> <text x=\"32\" y=\"92\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\" xml:space=\"preserve\">    greeting = &quot;Hello, &quot; + nmae</text> <text x=\"32\" y=\"116\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\" xml:space=\"preserve\">                           ^^^^</text> <text x=\"32\" y=\"140\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\" xml:space=\"preserve\">NameError: name 'nmae' is not defined</text> <text x=\"486\" y=\"44\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">third — how it got there</text> <path d=\"M480 44 L452 44\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-wire)\"></path> <text x=\"486\" y=\"68\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">second — which file and which line</text> <path d=\"M480 68 L452 68\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-wire)\"></path> <text x=\"486\" y=\"140\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">first — what actually happened</text> <path d=\"M480 140 L452 140\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <text x=\"360\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">In a one-file program the top line is one line long and you can ignore it.</text> </svg>", "caption": "Three questions, answered from the bottom up — which is why the most useful line is the one nearest your cursor."}
```

```
Traceback (most recent call last):
  File "/home/ada/greet.py", line 2, in <module>
    greeting = "Hello, " + nmae
                           ^^^^
NameError: name 'nmae' is not defined
```

## Bottom line first: what happened

`NameError: name 'nmae' is not defined`

Two halves. **`NameError`** is the kind of failure — one of maybe a dozen you will meet in your
first month, and lesson 8 names them all. **The text after the colon** is the specific complaint,
written for a person.

## Second from the bottom: where

`File "/home/ada/greet.py", line 2` — the file and the line the interpreter was standing on. Then
the line itself, quoted back, with `^^^^` under the part it could not resolve.

That caret is doing real work. In a long line with four function calls in it, the caret says which
one.

## The top: how it got there

`Traceback (most recent call last)` means what it says: the list above the error is the chain of
calls that led here, **oldest first**. In a one-file program it is one line and you can ignore it.
When your program has functions calling functions, this is the part that tells you the route.

## Why upside down

Because the last line is the answer, and the answer should be closest to where your eye already is
— at the bottom of the terminal, where you just pressed Enter.

## The four you will meet this week

| | it means |
|---|---|
| `NameError` | you used a word Python has no meaning for — usually a typo, sometimes a missing import |
| `SyntaxError` | the file could not be read at all; nothing ran |
| `TypeError` | the operation is real but not for these types — `"2" + 2` |
| `IndentationError` | the spaces at the start of a line do not line up |

**`SyntaxError` is the odd one out**, and it is worth knowing why: the others happen while your
program is running, so anything above the failing line already happened. A `SyntaxError` happens
*before* anything runs, because the interpreter could not finish reading the file. If you see one,
no part of your program executed — not even the `print` on line 1.
