---
title: Copies, nearer
version: 1
---

Lesson three gave you a number you cannot argue with: light takes time, and a request that crosses
an ocean pays for the crossing twice before a single byte of content moves.

A **content delivery network** is the answer to that number, and it is a simple one. Keep copies of
your files on machines all over the world, and answer each visitor from the nearest one.

## What it actually is

A few hundred locations — *edges* — each holding a cache. Your site's name resolves, for each
visitor, to the edge closest to them, which is what the previous lesson's `CNAME` into a provider's
name is usually arranging.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"A visitor is answered by the nearest edge, which holds a copy. Only when an edge has no copy does a request reach the origin server, once, after which every later visitor is served locally.\"> <rect x=\"20\" y=\"34\" width=\"180\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"110\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a visitor in São Paulo</text> <path d=\"M206 56 L254 56\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path> <rect x=\"260\" y=\"34\" width=\"200\" height=\"44\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the edge in São Paulo</text> <text x=\"480\" y=\"56\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">answers in 8 ms</text> <rect x=\"20\" y=\"106\" width=\"180\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"110\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a visitor in Lisbon</text> <path d=\"M206 128 L254 128\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path> <rect x=\"260\" y=\"106\" width=\"200\" height=\"44\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"128\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the edge in Lisbon</text> <text x=\"480\" y=\"128\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">answers in 6 ms</text> <rect x=\"260\" y=\"178\" width=\"200\" height=\"44\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">an edge with no copy</text> <path d=\"M466 200 L534 200\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path> <rect x=\"540\" y=\"178\" width=\"160\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect> <text x=\"620\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">your one server</text> <text x=\"360\" y=\"252\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">that bottom row happens once per edge, and then stops happening</text> </svg>", "caption": "Distance stops mattering for anything cached, and your server stops hearing about most of the traffic."}
```

A visitor in São Paulo asks the edge in São Paulo. If it has the file, it answers in a few
milliseconds and your server never hears about the request. If it does not, it fetches from your
server once, keeps a copy, and every visitor after that is served locally.

Two things follow, and the second is the one people underuse. Distance stops mattering for anything
cached. And your server's load drops to whatever the edges could not answer, which for a site of
files is close to nothing.

## What it can and cannot make faster

Be precise here, because this is where money is wasted.

**Cached things get dramatically faster** — images, stylesheets, scripts, fonts, and any page that
is the same for everybody. The round trip shrinks from two hundred milliseconds to ten.

**Uncached things get slightly slower.** A request the edge cannot answer still travels to your
server, now with one extra hop in the middle. A personalised dashboard, a search result, a form
submission — none of these is helped, and a badly configured network adds a few milliseconds to
each.

**Your server being slow is untouched.** If a page takes two seconds to build, it takes two seconds
to build in front of an edge as well. This is the misunderstanding that sells the most
subscriptions: a CDN moves things closer, and it has no opinion about how long you take to produce
them.

The instinct to take away: **a CDN is a distance fix, not a speed fix.** Lesson three separated
those two numbers, and this is the tool for one of them.

## What is safe to put there

The rule follows from lesson seven, and getting it wrong is a disclosure rather than a slowdown.

Anything **public and identical for everybody** belongs at the edge, cached for as long as its name
allows — which is where hashed filenames earn their keep, because a fingerprinted file can be kept
for a year on machines you do not control.

Anything **personal is `private`**, and the edge must be told not to store it. A shared cache
holding one visitor's page and handing it to the next is exactly the failure from the caching
reading, now distributed across a hundred countries.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Public files and pages identical for everybody belong at the edge, cached for a long time. Anything personal must be marked private, because a shared cache handing one visitor's page to the next is now distributed worldwide.\"> <text x=\"180\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">cache it at the edge</text> <rect x=\"20\" y=\"36\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">files with a fingerprint in the name</text> <rect x=\"20\" y=\"82\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">images, fonts, stylesheets</text> <rect x=\"20\" y=\"128\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"180\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">pages identical for everybody</text> <text x=\"540\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--amber)\">mark it private</text> <rect x=\"380\" y=\"36\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"540\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">anything behind a login</text> <rect x=\"380\" y=\"82\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"540\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a basket, an order, a balance</text> <rect x=\"380\" y=\"128\" width=\"320\" height=\"38\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"540\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">anything with a name on it</text> <text x=\"360\" y=\"204\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the failure from lesson seven, now distributed across a hundred countries</text> <text x=\"360\" y=\"232\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">decide per route, when the route is written, rather than during an incident</text> </svg>", "caption": "One header decides which column a response is in, and one of the two columns is a disclosure."}
```

The header that separates them is the one from that reading, and the practical habit is to decide
per route rather than globally: files and public pages cached at the edge, anything behind a login
marked `private`, and the decision made when the route is written rather than during an incident.

## The other things it does

Worth knowing, because it is why most sites end up behind one even when distance is not their
problem.

**It absorbs attacks.** A flood aimed at your site hits a few hundred machines with enormous
capacity instead of your one, and the providers filter the obvious kinds without being asked.

**It ends the encryption at the edge**, which is the next reading, and which is also why it holds a
certificate for your name.

**It survives your server being down**, if you ask it to — serving what it has rather than an
error, which is the `stale-if-error` from lesson seven at a much larger scale.

**It costs less than bandwidth from your own machine**, usually, which surprises people who expect
the convenience to be the expensive part.

## Where the copies come from, and the word people get wrong

Two mechanisms, and they are often confused.

**Pull** is the ordinary arrangement, and it is what the picture above describes: the edge fetches
from your origin the first time somebody asks, and keeps the answer. You change nothing about how
you publish.

**Push** means you upload to the network yourself and the origin is never consulted. It is used
where the files are large and predictable — video libraries, software downloads — and it turns
publishing into a step in your build.

The word to be careful with is **origin**. It means your own server, the thing behind the edges,
and it appears in every provider's settings and in every explanation of why something is stale.
Getting comfortable with it now saves reading three paragraphs twice later.

## What it cannot help with at all

One honest paragraph, because a CDN is bought as a general performance product and it is not one.

It does nothing about a slow database query. It does nothing about a page that loads four megabytes
of script. It does nothing about a request that has to be personalised. And it does nothing about
the first visit to a name whose DNS is slow, which the previous lesson covered and which sits
entirely in front of this.

Put beside lesson three: a CDN attacks **latency** for cached things, and leaves **the time your
server takes** exactly where it was. Those are separate numbers, and no amount of the first fixes
the second.

## The two ways it goes wrong

Both are common and both are recognisable.

**Caching something personal**, discussed above, which is the serious one.

**Not being able to see past it.** When a page is wrong, the question *is my server wrong or is the
edge holding something old?* is the same question as the DNS one from the last lesson, and it has
the same answer: ask the origin directly, with the edge bypassed. Every provider offers a way; find
out what it is on the day you set it up rather than on the day you need it.
