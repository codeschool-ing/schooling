---
title: The queue that helps and hurts
version: 1
---

Here is a complaint you have heard, and possibly made.

*The video call was fine. Then somebody in the house started downloading something, and the call
fell apart — frozen picture, syllables dropping, people talking over each other. The download
carried on perfectly.*

Nothing about that is bandwidth, and the tools most people reach for will all report that
everything is fine. What happened is a **queue**.

## Why a queue has to exist

A router receives packets on several links and sends them out on others, and those links have
different capacities. Traffic arrives from a fast one destined for a slow one all the time.

For that brief moment more is arriving than can leave. The router has two choices: hold the
excess, or throw it away.

Holding it is obviously right. Bursts are what real traffic looks like — a page load is a flurry
and then nothing — and a router with no buffer would discard packets constantly during entirely
normal activity, forcing retransmissions and wasting the capacity it was trying to protect.

So every router has a buffer, and it should. **The buffer is what stops a burst becoming a loss.**

## What a full queue does to the time

Now watch the same buffer when the traffic is not a burst but a sustained download.

A download does not politely stop at your line's capacity. TCP keeps increasing its rate until
something tells it to stop — and the only thing that ever tells it to stop is a **packet being
dropped**. So it climbs, and climbs, and the excess goes into the buffer.

The buffer fills. And it stays full, because the download keeps pushing.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Two panels. On the left an empty queue with one voice packet passing straight through in five milliseconds. On the right the same queue full of download packets, with a voice packet at the back having to wait three hundred milliseconds for its turn.\"><rect x=\"8\" y=\"14\" width=\"340\" height=\"232\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"178\" y=\"38\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">an empty queue</text><rect x=\"28\" y=\"70\" width=\"300\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><rect x=\"284\" y=\"78\" width=\"36\" height=\"20\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".4\" stroke=\"var(--phosphor)\"></rect><text x=\"302\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">voice</text><text x=\"150\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nothing ahead of it</text><text x=\"178\" y=\"142\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">5 ms of waiting</text><text x=\"178\" y=\"180\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the call sounds natural</text><text x=\"178\" y=\"218\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">and the line is mostly idle</text><rect x=\"372\" y=\"14\" width=\"340\" height=\"232\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"542\" y=\"38\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">the same queue, full</text><rect x=\"392\" y=\"70\" width=\"300\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><rect x=\"398\" y=\"78\" width=\"30\" height=\"20\" rx=\"1\" fill=\"var(--phosphor-dim)\" fill-opacity=\".45\"></rect><rect x=\"432\" y=\"78\" width=\"30\" height=\"20\" rx=\"1\" fill=\"var(--phosphor-dim)\" fill-opacity=\".45\"></rect><rect x=\"466\" y=\"78\" width=\"30\" height=\"20\" rx=\"1\" fill=\"var(--phosphor-dim)\" fill-opacity=\".45\"></rect><rect x=\"500\" y=\"78\" width=\"30\" height=\"20\" rx=\"1\" fill=\"var(--phosphor-dim)\" fill-opacity=\".45\"></rect><rect x=\"534\" y=\"78\" width=\"30\" height=\"20\" rx=\"1\" fill=\"var(--phosphor-dim)\" fill-opacity=\".45\"></rect><rect x=\"568\" y=\"78\" width=\"30\" height=\"20\" rx=\"1\" fill=\"var(--phosphor-dim)\" fill-opacity=\".45\"></rect><rect x=\"602\" y=\"78\" width=\"30\" height=\"20\" rx=\"1\" fill=\"var(--phosphor-dim)\" fill-opacity=\".45\"></rect><rect x=\"648\" y=\"78\" width=\"36\" height=\"20\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".5\" stroke=\"var(--amber)\"></rect><text x=\"666\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">voice</text><text x=\"515\" y=\"124\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">download packets, already queued</text><text x=\"542\" y=\"156\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\">300 ms of waiting</text><text x=\"542\" y=\"190\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the call falls apart</text><text x=\"542\" y=\"222\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">and the download is going at full speed</text></svg>", "caption": "Nothing was lost and nothing slowed down. The voice packet simply had four hundred things in front of it."}
```

Your voice packet arrives at that router and joins the back of the line. It is not dropped, it is
not corrupted, it is not misrouted — it is **four hundred packets from the front**, and it waits.

A buffer holding a second's worth of traffic adds a second of latency to everything that touches
it. And because nothing is lost, every count reports success while the call is unusable.

## The name, and why it got worse

This is **bufferbloat**, and the reason it is widespread is almost funny.

Memory got cheap. Equipment makers added generous buffers, because a bigger buffer means fewer
drops, and fewer drops looks better in every test that counts drops. Nobody was measuring latency
under load, so nobody noticed that a buffer big enough never to drop anything is a buffer big
enough to add half a second to everything.

The measure that would have caught it is the one habit from the last section: **watch latency
while the line is full.** A connection that pings at 15 ms idle and 400 ms during a download is
bloated, and that is a complete diagnosis.

## Why it hits some things and not others

The reason the download is unharmed while the call collapses is that they want different things.

The download wants throughput and does not care about delay — an extra 300 ms on a file that takes
a minute is invisible. The call wants delay and barely uses any capacity — audio is tens of
kilobits per second, a rounding error next to the download.

So the queue penalises exactly the traffic that cannot afford it, and rewards exactly the traffic
that caused it. That is not a design anybody chose; it is what a single first-come-first-served
line does when its occupants want opposite things.

## What actually fixes it

Worth knowing, because it is the one problem in this lesson an ordinary person can fix.

The real fix is **smarter queueing**: instead of one long line, keep separate lines and serve a
little from each, so a burst of voice never sits behind a download. Modern equipment implements
this — the setting is often called smart queue management — and turning it on can take latency
under load from 400 ms back to 20.

A related trick is to configure the connection at slightly **under** its true capacity, which
keeps the buffer that is actually causing the problem — usually one you do not control, at the
provider's end — from ever filling up. You give away a few percent of throughput and get the
latency back, which for a household with people on calls is a trade worth making.

What does not fix it is buying more bandwidth. A wider line fills more slowly, so the queue builds
later — and then does exactly the same thing.

## Where this leaves you

Queuing delay is the component of latency that moves, and a buffer that exists for good reasons
becomes the largest source of delay on a connection whenever a sustained transfer fills it.
Nothing is lost, so everything reports success; the traffic that suffers is the traffic that
needed the delay to stay small.

That is delay caused by waiting. The next section is about what it looks like when the delay
**varies** from packet to packet, and about the other thing that happens once a buffer really does
run out.
