---
title: Reading the five numbers
version: 1
---

Clicking a request and opening its timing produces a small chart that nearly everybody skips. It is
the most useful thing in this lesson, because it takes the single number *this took 5.4 seconds*
and splits it into pieces that each point at a different person.

## The five bars

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"One request's time split into five bars: queued, DNS, connecting and TLS, waiting for the server, and downloading. Only the waiting bar belongs to the server.\"> <text x=\"20\" y=\"26\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">one request, 5.4 seconds, split into what it was actually doing</text> <rect x=\"20\" y=\"38\" width=\"60\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"50\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">queued</text> <rect x=\"86\" y=\"38\" width=\"54\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"113\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">DNS</text> <rect x=\"146\" y=\"38\" width=\"90\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"191\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">connect, TLS</text> <rect x=\"242\" y=\"38\" width=\"380\" height=\"34\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".3\" stroke=\"var(--amber)\"></rect> <text x=\"432\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">waiting — the server thinking</text> <rect x=\"628\" y=\"38\" width=\"72\" height=\"34\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"664\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">download</text> <text x=\"20\" y=\"110\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the same total, with the bars swapped, is an entirely different problem</text> <rect x=\"20\" y=\"122\" width=\"60\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"50\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">queued</text> <rect x=\"86\" y=\"122\" width=\"54\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"113\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">DNS</text> <rect x=\"146\" y=\"122\" width=\"90\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"191\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">connect, TLS</text> <rect x=\"242\" y=\"122\" width=\"80\" height=\"34\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".3\" stroke=\"var(--amber)\"></rect> <text x=\"282\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">waiting</text> <rect x=\"328\" y=\"122\" width=\"372\" height=\"34\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"514\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">downloading — the file is simply large</text> <text x=\"360\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">the total is the same and the person who fixes it is not</text> <text x=\"360\" y=\"226\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">which is the whole reason to open the breakdown instead of reading the total</text> </svg>", "caption": "One number, five pieces, and each piece points at a different fix. Skipping this is how weeks get spent."}
```

**Queued or stalled** — the request was waiting for a turn. On HTTP/1.1 that is the six-connection
limit of lesson six; if this bar is large and there are many rows, the version of the protocol is
the story.

**DNS** — the name lookup of lesson eight. Present on the first request to a host and absent
afterwards, because the answer was cached. A large one here means a slow resolver or a cold name,
and it is in front of everything else.

**Connecting, and TLS** — the round trips of lessons five and six: the connection, then the
negotiation. These are paid once per connection, which is why a page spread across six hosts pays
them six times.

**Waiting** — the request has been sent and nothing has come back. This is the server thinking, and
it is the one number in this list that belongs to the server alone.

**Downloading** — bytes arriving. This is bandwidth and size, and it is the only bar that gets
smaller when the file does.

## What each one tells you to do

The reason to split them is that the fix is different for every bar, and choosing the wrong one is
how weeks get spent.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Each bar and what it tells you to do: waiting means the application, downloading means the file, connecting means too many hosts, DNS means a cold lookup and queued means contention.\"> <rect x=\"20\" y=\"30\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".24\" stroke=\"var(--amber)\"></rect> <text x=\"140\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">waiting</text> <text x=\"300\" y=\"49\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the application or the database — no CDN touches it</text> <rect x=\"20\" y=\"76\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"140\" y=\"95\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">downloading</text> <text x=\"300\" y=\"95\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the file: compress it, resize it, or send less</text> <rect x=\"20\" y=\"122\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"140\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">connect, TLS</text> <text x=\"300\" y=\"141\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">too many hosts, or a server far away</text> <rect x=\"20\" y=\"168\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"140\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">DNS</text> <text x=\"300\" y=\"187\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a cold lookup, in front of everything else</text> <rect x=\"20\" y=\"214\" width=\"680\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"140\" y=\"233\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">queued</text> <text x=\"300\" y=\"233\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">contention: too many at once, on a version that queues</text> </svg>", "caption": "Five bars, five different people. Read which one is large before deciding anything at all."}
```

A large **waiting** bar is the application or the database. No amount of compression, no CDN, no
smaller image touches it.

A large **downloading** bar is the file. Compress it, resize it, choose a better format, or send
less.

Large **connecting** and **TLS** bars mean too many hosts, or a server far away. Fewer hosts, or a
CDN, which is lesson nine's distance fix.

A large **DNS** bar means a cold lookup, and the tools for it — a hint to resolve early, or a
shorter chain of names — are in lesson eight.

A large **stalled** bar means contention: too many requests at once on a protocol version that
queues them.

## Reading the whole chart rather than one row

The waterfall column shows every request on one timeline, and the shape of it says things no
individual row does.

**A staircase** — each request starting when the previous finished — means things are being
discovered one at a time. A stylesheet that imports a stylesheet, a script that fetches a script, a
chain of redirects. This is the shape to look for first, because a serial chain is the most
expensive thing a page can do and it is usually unintentional.

**A wall** — everything starting together — is what you want, and if the page is still slow with
that shape the problem is in one of the bars rather than in the arrangement.

**A long gap with nothing in it** is the browser busy rather than the network: parsing, a script
running, a layout. The network panel goes quiet and the performance panel is where the time went.

## The three lines down the chart

Vertical markers, and they are the moments lesson ten named.

The first is **DOMContentLoaded** — the tree is ready. The second is **load** — everything has
finished. On a healthy page the gap between them is small; a wide one means a great deal is
arriving after the visitor could have started reading, which may be fine and is worth knowing
about.

Some browsers also mark the **first paint**. Everything to the left of that line is the blank
screen of lesson ten, and if it is wide, the render-blocking section of that lesson is where to
look.

## Where the total actually went

One more reading of the chart, because it answers the question a manager asks.

The bottom of the panel reports the number of requests, the bytes transferred, and the times of the
two events above. Those four numbers are the summary, and each one has a different owner: the count
is the page's design, the bytes are the files, and the events are everything this course has been
about.

The sentence worth being able to say is the one that separates them. *The server answered in forty
milliseconds; the first paint was at two seconds; the difference is one stylesheet and a blocking
script.* Every part of that comes off this chart, and it is a different conversation from *the site
is slow*.

## Three habits

**Reload with the panel open**, throttled to something a real visitor might have.

**Read the biggest bar first**, and read which bar it is before deciding anything.

**Compare against a second load**, without disabling the cache, because that is the experience
most visitors have and the one measurement nobody takes.

Those three, on any site, answer more questions in five minutes than an afternoon of guessing. And
that is the whole of this lesson: the numbers were always there, and now you know which one you are
reading.
