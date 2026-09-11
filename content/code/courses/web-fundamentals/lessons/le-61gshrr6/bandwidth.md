---
title: Capacity, not speed
version: 1
---

**Bandwidth is how much fits through at once.** It is a rate — an amount per second — and it is the
number on every internet plan ever sold.

It is not speed. Nothing travels faster on a bigger connection. What changes is how much travels
side by side, and keeping those two apart is most of what this lesson is for.

## The pipe, and the honest part of the metaphor

The usual picture is a pipe, and it is a good one as long as you take the right thing from it.

A wider pipe does not make water move faster along it. It makes **more water move at once**. If you
need to move a bathful, a wider pipe finishes sooner — not because the water hurried, but because
more of it went at a time.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 236\" role=\"img\" aria-label=\"Two pipes side by side. The narrow one carries two units of water abreast, the wide one carries six. An arrow under both shows the water moving at the same speed in each; only the amount side by side differs.\"><rect x=\"14\" y=\"20\" width=\"340\" height=\"196\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"184\" y=\"44\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">A narrow pipe</text><rect x=\"38\" y=\"70\" width=\"292\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><rect x=\"48\" y=\"80\" width=\"40\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><rect x=\"96\" y=\"80\" width=\"40\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><text x=\"184\" y=\"134\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">two units side by side</text><text x=\"184\" y=\"170\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">same speed along the pipe</text><text x=\"184\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a bathful takes longer</text><rect x=\"368\" y=\"20\" width=\"340\" height=\"196\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"538\" y=\"44\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">A wide pipe</text><rect x=\"392\" y=\"62\" width=\"292\" height=\"54\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><rect x=\"402\" y=\"70\" width=\"40\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><rect x=\"450\" y=\"70\" width=\"40\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><rect x=\"498\" y=\"70\" width=\"40\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><rect x=\"402\" y=\"92\" width=\"40\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><rect x=\"450\" y=\"92\" width=\"40\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><rect x=\"498\" y=\"92\" width=\"40\" height=\"18\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><text x=\"538\" y=\"134\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">six units side by side</text><text x=\"538\" y=\"170\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">same speed along the pipe</text><text x=\"538\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a bathful takes less time</text></svg>", "caption": "The width is the bandwidth. Nothing in either pipe is moving faster than anything in the other."}
```

Where the metaphor stops being helpful is the length. A pipe from your house to a machine in Japan
is *long*, and how long the pipe is has nothing to do with how wide it is. That length is the next
section.

## Bits, bytes, and the most widespread confusion there is

Your plan says **300 Mbps**. Your download shows **37 MB/s**. Both are correct, and people have
argued about this for thirty years.

- A **bit** is one 0 or 1. Network speeds are quoted in bits per second, with a lowercase `b`.
- A **byte** is eight bits. File sizes and download managers use bytes, with a capital `B`.

So the conversion is a division by eight:

| what the plan says | what a download shows |
|---|---|
| 100 Mbps | about 12.5 MB/s |
| 300 Mbps | about 37.5 MB/s |
| 600 Mbps | about 75 MB/s |
| 1 Gbps | about 125 MB/s |

If you see roughly an eighth of the number you expected, **nothing is wrong**. You are looking at
the same quantity in the other unit.

Why two units at all is partly history and partly marketing: the industry that sells connections
quotes the number that looks eight times bigger. It is not going to change, so the defence is
knowing which letter you are reading.

## The number is a ceiling, and it is shared

Two more things the plan does not spell out.

**It is a maximum, not a promise.** 300 Mbps means *up to* 300, under good conditions, on the part
of the path your provider controls. Nothing about it guarantees what a particular website will send
you.

**And it is shared, more than once over.** Every device in your home shares it. So, further out,
does every household on your street — providers do not build one private 300 Mbps line per
customer, because at any moment almost nobody is using theirs. That arrangement is sound and it is
also why the evening is slower than the morning.

## Where the ceiling actually is

A path is many links, and you do not get the widest of them. **You get the narrowest.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"A chain of five links between a laptop and a server, labelled with capacities of 1200, 300, 40, 940 and 10000 megabits per second. The 40 link is marked as the narrowest, and a note says that is what the whole path delivers.\"><rect x=\"8\" y=\"66\" width=\"84\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"50\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">laptop</text><text x=\"50\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1200</text><rect x=\"148\" y=\"66\" width=\"84\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"190\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Wi-Fi</text><text x=\"190\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">300</text><rect x=\"288\" y=\"60\" width=\"84\" height=\"56\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".14\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"330\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">old cable</text><text x=\"330\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">40</text><rect x=\"428\" y=\"66\" width=\"84\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"470\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">provider</text><text x=\"470\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">940</text><rect x=\"568\" y=\"66\" width=\"96\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"616\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the server</text><text x=\"616\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10000</text><path d=\"M92 88 L144 88\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M232 88 L284 88\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M372 88 L424 88\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M512 88 L564 88\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"360\" y=\"20\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">megabits per second, per link</text><text x=\"360\" y=\"150\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">the whole path delivers 40 — you get the narrowest, never the widest</text><text x=\"360\" y=\"176\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">upgrading any of the other four changes nothing at all</text></svg>", "caption": "The bottleneck is a property of the path, not of your plan. Widening anything but the narrow link buys nothing."}
```

This is worth holding on to, because it is the reason so much money is spent on connections that
change nothing. If the narrow link is a tired cable in the wall, or the Wi-Fi in a far room, or the
server's own outbound capacity, then doubling the plan doubles a number that was never the limit.

## Upload is a different number, and usually a much smaller one

Almost every domestic connection is **asymmetric**: it can receive far more than it can send.

A plan advertised as 300 Mbps very often means 300 down and 30 up, or 300 down and 15 up, and the
second number is printed smaller or not at all. The reason is historical and reasonable — most
households consume far more than they produce, so the capacity was allocated where it was used.

It stopped being harmless when households started producing.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Two bars for one connection. A long bar labelled download at 300 megabits per second, and a much shorter bar below it labelled upload at 30. A note beside them says a video call uses the short one.\"><text x=\"60\" y=\"58\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">download</text><rect x=\"150\" y=\"40\" width=\"460\" height=\"30\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".26\" stroke=\"var(--phosphor)\"></rect><text x=\"380\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">300 Mbps</text><text x=\"60\" y=\"114\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">upload</text><rect x=\"150\" y=\"96\" width=\"46\" height=\"30\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".26\" stroke=\"var(--amber)\"></rect><text x=\"246\" y=\"112\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">30 Mbps — the same plan</text><text x=\"360\" y=\"166\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">your camera, your backups and every file you send use the short bar</text><text x=\"360\" y=\"190\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">which is why they look fine to you and bad to the other person</text></svg>", "caption": "One plan, two very different numbers. Only one of them is on the advertisement."}
```

It explains a complaint you will certainly meet. On a video call, **you see them perfectly and they
say you are frozen.** Their picture arrives over your enormous download; yours leaves over your
small upload, and if a backup is running at the same time it leaves over whatever that backup is
not using.

The same asymmetry is why sending a large file feels so much slower than receiving one of the same
size, and why a home connection makes a poor place to host anything.

## And bandwidth is often not what is slow

The last point is the one the rest of the lesson builds on.

A big transfer — a film, a game, a backup — is limited by bandwidth, and more of it genuinely helps.

**A small transfer is not.** Loading a page means dozens of small requests, and for each of them
the time is dominated by *getting there and back*, not by how much fits abreast. You can double the
width of a pipe all you like; if what you are sending is a postcard, it was never the width that
made it take four hundred milliseconds.

Which is the whole reason the next section exists.

## Where this leaves you

Bandwidth is capacity per second, quoted in bits where your downloads are counted in bytes, a
ceiling rather than a promise, shared with your household and your street, and limited by the
narrowest link on the path rather than by the widest.

What it is not is speed. How long one thing takes to get there and back is a completely separate
number, nobody sells it to you, and it is the one that decides how a page feels.
