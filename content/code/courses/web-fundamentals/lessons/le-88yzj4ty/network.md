---
title: Every request, listed
version: 1
---

The network panel is a list of everything the page asked for, with a row per request and a column
for the things you have spent ten lessons learning to care about.

Open it, reload the page — it records only while it is open, which is the first thing everybody
gets wrong — and the whole of lessons six and seven is on the screen.

## The columns that matter

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A network panel row for each request, with columns for the name, the status code, the type, the size or cache source, and the total time.\"> <rect x=\"20\" y=\"30\" width=\"680\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\"></rect> <text x=\"120\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">name</text> <text x=\"320\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">status</text> <text x=\"440\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">type</text> <text x=\"550\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">size</text> <text x=\"650\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">time</text> <rect x=\"20\" y=\"66\" width=\"680\" height=\"30\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"120\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">precos</text> <text x=\"320\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">200</text> <text x=\"440\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">document</text> <text x=\"550\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">14 kB</text> <text x=\"650\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">62 ms</text> <rect x=\"20\" y=\"102\" width=\"680\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"120\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">app.7f3c2a9.css</text> <text x=\"320\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">200</text> <text x=\"440\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">stylesheet</text> <text x=\"550\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">disk cache</text> <text x=\"650\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">0 ms</text> <rect x=\"20\" y=\"138\" width=\"680\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"120\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">logo.png</text> <text x=\"320\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">304</text> <text x=\"440\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">image</text> <text x=\"550\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">310 B</text> <text x=\"650\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">41 ms</text> <rect x=\"20\" y=\"174\" width=\"680\" height=\"30\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".22\" stroke=\"var(--amber)\"></rect> <text x=\"120\" y=\"189\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">widget.js</text> <text x=\"320\" y=\"189\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">200</text> <text x=\"440\" y=\"189\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">script</text> <text x=\"550\" y=\"189\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">88 kB</text> <text x=\"650\" y=\"189\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">5.4 s</text> <text x=\"360\" y=\"234\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">sorting by the last column takes about a second and finds the bottom row</text> </svg>", "caption": "Lessons six and seven, as a table. A 304 and a cache hit are two different rows, and they look it."}
```

**Name** is the file. **Status** is the three digits of lesson six. **Type** is what the
`Content-Type` said it was. **Size** is what came over the wire, and it says *disk cache* or
*memory cache* when nothing did. **Time** is the whole duration of that request. And the
**waterfall** is where it sat relative to everything else, which is the next reading.

Two of those are worth acting on immediately.

Sorting by **size** finds the four-megabyte image nobody meant to publish, which is the single most
common performance defect in the world.

Sorting by **time** finds the one request that is slow on a page where everything else is fine.
That is a different problem from a page that is uniformly slow, and the two have nothing in common
except the complaint.

## Clicking a row

This is where the panel stops being a list and becomes the protocol.

**Headers** — the request line, every request header, every response header. The `Cache-Control`
from lesson seven, the `Set-Cookie` with its attributes, the `Content-Type`, the redirect's
`Location`. Everything that lesson described as text is here, as text.

**Response** — the body, exactly as it arrived, which is how you find a `200` with an error inside
it.

**Timing** — the breakdown that the next reading is about.

**Cookies** — what was sent and what came back, per request, which is faster than reading the
headers for the one question it answers.

## Four controls that change what you see

**Disable cache**, which makes every load behave like a first visit. Essential while working on a
stylesheet and dishonest while measuring, because a site measured that way is a site nobody
experiences.

**Throttling**, which pretends to be a slower connection. This is the closest thing to the
discipline lesson three asked for: your machine is on a fast connection in the same city as the
server, and almost nobody else is.

**Filter**, by type or by text. *Show me only the requests to another host* is one click and
answers *how much of this page is somebody else's?*

**Preserve log**, which keeps the rows across a navigation. Without it, a redirect or a form
submission wipes the evidence at the moment it becomes interesting. Turn it on before reproducing
anything that navigates.

## Three things it makes visible that were abstract until now

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Three things the panel makes concrete: a redirect chain as one row per hop, a cache hit as a row with a near-zero size and time, and the number of separate hosts a page contacts.\"> <rect x=\"20\" y=\"34\" width=\"680\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"200\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a redirect chain</text> <text x=\"470\" y=\"55\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">one row per hop, with its 3xx</text> <rect x=\"20\" y=\"84\" width=\"680\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"200\" y=\"105\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a cache hit, and a 304</text> <text x=\"470\" y=\"105\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">two different rows, and they look it</text> <rect x=\"20\" y=\"134\" width=\"680\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"200\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">eleven hosts you did not choose</text> <text x=\"470\" y=\"155\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">sort by domain and count them</text> <text x=\"360\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">open the panel first, then reload — it records only while it is open</text> </svg>", "caption": "Three abstractions from earlier lessons, each of which turns out to be a row you can count."}
```

**A redirect chain.** Each hop is its own row, with its `3xx` and its `Location`. The chain of
lesson six that costs three round trips is three rows you can count.

**A cache hit.** The size column says the copy came from disk or memory, and the time is near zero.
The `304` of lesson seven is a row with a status of 304 and a tiny size — and the difference
between those two, which the reading described in words, is visible as two different rows.

**Something you did not ask for.** Sort by domain and find the eleven hosts a page contacts. On
most commercial sites this is the moment the third-party section of lesson ten stops being an
abstraction.

## Copying a request out of the panel

A small feature that is worth a section because it changes how you talk to other people about a
problem.

Right-clicking a row offers *copy as curl*, which produces a command line reproducing that exact
request — every header, every cookie, the body if there was one. Paste it into a terminal and the
request happens again, outside the browser, with nothing of the page involved.

That is the fastest way to answer *is it the browser or the server?* It also gives you something
you can hand to a colleague, or put in a bug report, that reproduces the problem without a
description of where to click.

The one caution is the reason it works: the copied command carries your session cookie and any
authentication header. It is a working credential in plain text, and it does not belong in a
message to a group, a ticket that other people read, or anything that will outlive the session.

## The one thing to check before believing any of it

The panel records from the moment it opens. A page loaded before you opened it shows nothing, or
shows only what happened afterwards.

Open it first, then reload. It is the smallest possible habit and it is the difference between this
panel being useful and being mysterious.
