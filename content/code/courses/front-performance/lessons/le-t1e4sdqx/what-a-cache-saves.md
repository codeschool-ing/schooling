---
title: What a cache saves
version: 1
---

**A visitor who comes back already has most of the page.** The script, the stylesheet, the fonts and
the pictures were downloaded on the first visit, and the browser keeps them in its **HTTP cache**, on
disk, keyed by their address. What it does with them on the second visit is one of three things:

| what the browser does | what it costs | when |
|---|---|---|
| **uses its copy without asking** | nothing at all: no request leaves the computer | the server said how long the copy stays good, and that time has not passed |
| **asks whether its copy is still right** | one round trip, and a few bytes back: `304 Not Modified` | the copy is no longer fresh, or the server said to check every time, and the server gave it something to check with |
| **downloads it again** | the round trip and the whole file | nothing to check with, or the file changed |

The first is what makes a second visit fast. The second is what makes it correct: a page that changed
is downloaded, and a page that did not costs a round trip and no body. The third is what the planner
does now, for everything, on every visit.

## Other caches on the way

**The browser's is not the only cache.** Between a visitor and a server there can be a **CDN**, a
company's servers in many cities that keep copies close to the people asking, and in a company network
a proxy that does the same for its users. These are **shared caches**: one copy serves many people.
The same headers tell them what they may keep, and lesson 3's regeneration, incremental static pages
kept for a while and rebuilt in the background, is one of them at work.

## What the browser does with no headers

**A response with no caching headers is not uncacheable.** HTTP lets a cache guess a lifetime from how
old the file looks, a tenth of the time since its `Last-Modified` date, and browsers do. A file that has
not changed in a year can be kept for a month on that guess, and a deploy that changes it is not seen
until the month is out. Saying what you mean is the only way to know what will happen, which is what
the rest of this lesson does.
