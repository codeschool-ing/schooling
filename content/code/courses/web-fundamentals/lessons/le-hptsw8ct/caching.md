---
title: The request that was never made
version: 1
---

The other memory in a browser has nothing to do with who you are. It saves **requests**, and the
fastest request in this course is the one that does not happen.

A cache asks two questions, in order. May I keep this? And may I use what I kept without checking?
Almost everything below is an answer to one of those.

## Fresh, stale, and the two outcomes

A response arrives with an instruction:

```
Cache-Control: max-age=3600
```

For the next hour that copy is **fresh**. A request for the same address in that hour produces no
network activity at all: the browser serves its own copy and nothing leaves the machine. Zero
bytes, zero milliseconds, and no line in any server log.

After the hour it is **stale**, which does not mean useless. It means *ask before using*.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A cached copy that is still fresh is used with no request at all. A stale copy produces a conditional request, answered either with a small 304 that keeps the copy or with a full 200 carrying new content.\"> <rect x=\"230\" y=\"26\" width=\"260\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"360\" y=\"45\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the page asks for something again</text> <path d=\"M300 70 L180 110\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path> <path d=\"M420 70 L540 110\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path> <rect x=\"20\" y=\"116\" width=\"320\" height=\"70\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the copy is still fresh</text> <text x=\"180\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">no request at all</text> <rect x=\"380\" y=\"116\" width=\"320\" height=\"70\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"540\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the copy has gone stale</text> <text x=\"540\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">If-None-Match: \"a4f21c\"</text> <path d=\"M470 192 L400 228\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path> <path d=\"M610 192 L640 228\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path> <rect x=\"240\" y=\"234\" width=\"290\" height=\"56\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"385\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">304 — nothing changed</text> <text x=\"385\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">no body: 300 bytes, and the copy is fresh again</text> <rect x=\"546\" y=\"234\" width=\"154\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"623\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">200 — new</text> <text x=\"623\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the whole thing</text> </svg>", "caption": "Three outcomes, and the leftmost one never touches the network. That is what freshness buys."}
```

The asking is a **conditional request**. The browser sends what it already has, as a fingerprint,
and the server compares:

```
If-None-Match: "a4f21c"
```

If nothing has changed, the answer is `304 Not Modified` — a status line and a few headers, with no
body at all. Three hundred bytes instead of two hundred kilobytes, and the browser keeps what it
had, now fresh again.

If something has changed, the answer is an ordinary `200` with the new content, and the cycle
starts over.

That fingerprint is the `ETag`, which a server sets on the way out. It can be a hash of the
content, a version number, anything — the only requirement is that it changes when the content
does. There is an older mechanism using dates and `If-Modified-Since`, still perfectly common,
which is the same idea with one second of resolution instead of exactness.

## The three instructions people confuse

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Three instructions compared. max-age keeps a copy and uses it without asking. no-cache keeps a copy and asks every time. no-store keeps nothing at all.\"> <rect x=\"20\" y=\"30\" width=\"216\" height=\"120\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"128\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">max-age=3600</text> <text x=\"128\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">keeps a copy</text> <text x=\"128\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">and uses it without</text> <text x=\"128\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">asking anything</text> <rect x=\"252\" y=\"30\" width=\"216\" height=\"120\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">no-cache</text> <text x=\"360\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">keeps a copy</text> <text x=\"360\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">and asks every time</text> <text x=\"360\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">before using it</text> <rect x=\"484\" y=\"30\" width=\"216\" height=\"120\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\"></rect> <text x=\"592\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">no-store</text> <text x=\"592\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">keeps nothing</text> <text x=\"592\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">for a statement or</text> <text x=\"592\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a shared machine</text> <text x=\"360\" y=\"192\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">the two middle names are the ones people swap</text> <text x=\"360\" y=\"220\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">no-cache asks; no-store refuses</text> </svg>", "caption": "Only one of these three declines to keep a copy, and it is not the one whose name says cache."}
```

`max-age=N` — keep it, and use it without asking for N seconds.

`no-cache` — keep it, and **ask every time** before using it. Despite the name, this is not a
refusal to cache. It is the arrangement that gives you a `304` on most requests and correct content
on all of them, and it is what you want for anything that changes unpredictably.

`no-store` — do not write this down at all. This is the refusal, and it is the right answer for a
bank statement or anything personal on a shared machine.

Getting these two names the wrong way round is common enough to be worth a moment of deliberate
memorising: **`no-cache` asks, `no-store` refuses.**

## Who is holding the copy

The other half of `Cache-Control` is about *which* cache, and getting it wrong is not a performance
problem but a disclosure.

`private` means only the browser that asked may keep this. `public` means anything along the way
may: a CDN, a company proxy, a cache at the provider.

A page containing somebody's name, their order history, their balance — that is `private`, and
marking it `public` puts one visitor's page into a shared cache from which the next visitor is
served. It is a small header and it has leaked real people's data more than once, because the
defect is invisible to whoever is testing on their own machine.

There is a directive for shared caches specifically — `s-maxage` — which lets you tell a CDN one
thing and browsers another. It is worth knowing it exists at the point where you have a CDN and
want to keep something at the edge for longer than in anybody's browser.

## Stale on purpose

Two directives are worth knowing because they change what happens during the worst minute of a
site's day.

`stale-while-revalidate` says: when the copy goes stale, **serve it anyway** and fetch a fresh one
in the background. The visitor waits for nothing, and the next visitor gets the new version. It
costs a moment of slightly old content in exchange for never making anybody wait for a
revalidation.

`stale-if-error` says: if the origin is broken, serve the old copy rather than an error. A site
whose servers have fallen over can keep answering with yesterday's pages, which is a very different
outage from a blank screen.

Both are instructions to caches that support them — a CDN, usually, rather than a browser — and
both are the kind of thing that is cheap to set beforehand and impossible to set during the
incident it would have covered.

## The header a cache is allowed to ignore

One honest note, because it saves an argument later. These are instructions and not laws.

A browser may evict anything at any moment because it is short of disk. A proxy may be configured
by somebody who disagrees with you. A CDN applies its own rules on top of yours. `max-age` is an
upper bound on how long a cache may use a copy, not a promise that it will.

So a cache is a thing you can rely on statistically and never individually — which is why
correctness must never depend on a copy still being there, and why the caching questions worth
asking are all of the form *what happens if this is missed?*

## What it is worth

Put numbers on it, because the abstraction hides how large this is.

A page with sixty resources, on a second visit. Without caching, sixty requests and perhaps two
megabytes. With conditional requests, sixty requests and perhaps twenty kilobytes of `304`s — the
round trips are still paid. With fresh copies, **zero requests**, and the page assembles from disk
before the network has been consulted.

The difference between the second and the third of those is the whole reason the next reading
exists. Freshness is worth a great deal, and the price of asking for it is that you have promised
something you cannot easily take back.
