---
title: What you actually get
version: 1
---

**Throughput is what you end up with.** Not the number on the plan, and not the theoretical
capacity of any link — the rate at which real data actually moved, measured after the fact.

It is always lower than the bandwidth, and the interesting question is where the difference went.

## Four places the difference goes

**The narrowest link.** Covered already, and still the first thing to check. You get the smallest
capacity on the path, and your plan is only one of the candidates.

**Everything that is not your data.** Every layer adds a header, and every header is capacity
spent on labels rather than content. A frame header, a packet header, a TCP header, then TLS, then
HTTP's own headers — on small transfers the overhead is a meaningful fraction, and on a page of
tiny requests it is a large one.

**The other end.** A server serving thousands of people divides its outbound capacity among them.
A slow disk, a busy database, an overloaded machine — all of these cap your throughput at
something far below what either connection could carry. **Your bandwidth is a ceiling on what you
can receive, not a promise about what anybody will send.**

**And the conversation itself.** This is the one nobody expects, and it needs its own heading.

## A pipe that is wide and long cannot be filled by asking politely

Recall from lesson two how TCP works: it sends some data, waits for an acknowledgement, and sends
more. It will not simply blast everything at once, because it has no idea what the network or the
receiver can absorb.

So at any moment there is a limit on how much data is **in flight** — sent but not yet
acknowledged. That limit is called the window.

Now consider what that means on a long path.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A long pipe between two machines with a small block of data inside it and a great deal of empty space. A note says the sender is waiting for an acknowledgement before sending more, so the line sits idle most of the time.\"><rect x=\"12\" y=\"70\" width=\"92\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"58\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">sender</text><rect x=\"616\" y=\"70\" width=\"92\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"662\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">receiver</text><rect x=\"116\" y=\"74\" width=\"488\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><rect x=\"126\" y=\"84\" width=\"74\" height=\"24\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".34\" stroke=\"var(--phosphor)\"></rect><text x=\"163\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">in flight</text><text x=\"406\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">empty — capacity that exists and is not being used</text><text x=\"360\" y=\"56\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1 Gbps of capacity, 200 ms round trip</text><text x=\"360\" y=\"162\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">the sender has stopped and is waiting for an acknowledgement</text><text x=\"360\" y=\"186\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">it will wait 200 ms before it may send again</text><text x=\"360\" y=\"220\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">a 64 kB window over 200 ms is about 2.6 Mbps, whatever the link can do</text></svg>", "caption": "To fill a long pipe you must have enough data in flight to cover the whole round trip. Capacity alone does not do it."}
```

To keep a link busy, the amount in flight has to cover the entire round trip — because that is how
long it takes before permission to send more comes back. The quantity you need is
**capacity × round trip**, and it has a name: the *bandwidth-delay product*.

For 1 Gbps and 200 ms, that is about 25 megabytes in flight. With a window of 64 kilobytes, you
would get roughly 2.6 Mbps out of a gigabit link — not because anything is broken, but because the
sender spends almost all its time waiting.

Modern systems grow the window automatically and reach far better numbers, and this is still the
reason a single transfer across the world rarely reaches what the same transfer reaches next door.
**Distance costs throughput, not only latency.** It is the second reason lesson 9's answer is to
put the content nearer rather than to buy a bigger connection.

## Why one download is slower than eight

Which leads to something you may have noticed and assumed was a trick.

Download manager software has offered to split a file into several simultaneous connections for
decades, and it genuinely helps. Not because each connection is faster, but because **each one has
a window of its own**, and eight windows put eight times as much data in flight.

The same reasoning is why a browser opens several connections per site, and why a speed test opens
many at once. A speed test reports what your line can do with every trick applied — which is a
fair measurement of the line, and a poor prediction of any single transfer you will actually make.

## Where a real hour goes

It helps to put numbers on it once. You are downloading a 1 GB file on a 300 Mbps connection.

The arithmetic everybody does first: 1 GB is 8,000 megabits, at 300 megabits per second, so about
**27 seconds**. It arrives in 48. Here is the missing 21, and none of it is anybody cheating.

| where it went | roughly |
|---|---|
| your line is 300 Mbps *up to*, and delivers around 280 in practice | 2 s |
| headers on every layer — about 5% of what crosses the wire is labels | 1 s |
| TCP starting cautiously and taking a few seconds to reach full rate | 3 s |
| the server dividing its capacity among everyone downloading right now | 9 s |
| a shared segment in the evening, and a couple of retransmissions | 6 s |

The largest single line is **the other end**, and it is the one your plan has no influence over at
all. This is the ordinary case rather than a bad day: a transfer that reaches 70% of the
advertised figure is a healthy transfer.

Which is also the answer to *why is this download slower than the speed test*. The speed test
measured your line to a nearby server with every trick applied. This measured a real conversation
with a real machine that has other people to serve.

## Measuring it honestly

Three habits, and they are what separates a useful measurement from a number.

**Measure the thing you care about.** A speed test measures your line to a nearby server chosen by
your provider. If the complaint is about one particular site, the speed test can be perfect and
tell you nothing.

**Measure more than once, at more than one hour.** A shared connection at nine in the evening is
a different connection from the same one at six in the morning.

**And watch latency while you measure throughput.** This is the habit almost nobody has, and it is
the subject of the next section: a connection can deliver its full advertised throughput while
becoming unusable for everything else at the same moment.

## Where this leaves you

Throughput is the rate real data actually moved. It is bounded by the narrowest link, reduced by
the headers every layer adds, capped by whatever the other end is willing to send, and — on long
paths — limited by how much a single conversation can keep in flight while it waits for
permission.

That last one means distance costs you capacity and not just time. And the measuring habit at the
end of this section is the one that opens the next: **look at what happens to latency while the
line is full.**
