---
title: Crossing a network you do not belong to
version: 1
---

A router has a packet in its hands. The packet says it is going to `203.0.113.7`. The router is
not `203.0.113.7`, and it has no idea where that is.

What happens next is the machinery that turns a few million independent machines into something a
packet can cross, and it is far simpler than the result suggests.

## Nobody knows the way

Start by discarding the natural assumption. There is no map. No machine anywhere holds a route
from your laptop to the server, and nothing consults one.

Each router knows one thing only: **for a packet going roughly over there, the next machine to
hand it to is this one.** Not the path. The next step.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"A chain of five machines. Above each router a small speech bubble saying only which neighbour it would hand the packet to next. No machine states the full path.\"><rect x=\"10\" y=\"96\" width=\"96\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"58\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">you</text><rect x=\"158\" y=\"96\" width=\"96\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"206\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">router A</text><rect x=\"306\" y=\"96\" width=\"96\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"354\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">router B</text><rect x=\"454\" y=\"96\" width=\"96\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"502\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">router C</text><rect x=\"602\" y=\"96\" width=\"106\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"655\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the server</text><path d=\"M106 118 L154 118\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M254 118 L302 118\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M402 118 L450 118\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M550 118 L598 118\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><rect x=\"148\" y=\"36\" width=\"116\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".1\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"206\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">not mine.</text><text x=\"206\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">give it to B</text><rect x=\"296\" y=\"36\" width=\"116\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".1\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"354\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">not mine.</text><text x=\"354\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">give it to C</text><rect x=\"444\" y=\"36\" width=\"116\" height=\"38\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".1\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"502\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">that range is</text><text x=\"502\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">on my own wire</text><path d=\"M206 74 L206 92\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" stroke-dasharray=\"2 2\" fill=\"none\"></path><path d=\"M354 74 L354 92\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" stroke-dasharray=\"2 2\" fill=\"none\"></path><path d=\"M502 74 L502 92\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" stroke-dasharray=\"2 2\" fill=\"none\"></path><text x=\"360\" y=\"176\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">no machine here knows the route — each knows one step</text><text x=\"360\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the path is what happens, not what was planned</text></svg>", "caption": "A dozen local decisions, taken independently, add up to a journey nobody designed."}
```

The path is an **outcome**, not a plan. It is what happened when a series of machines each answered
the same small question in turn. Nobody chose it and nobody is holding it.

## The table, which is a short list of ranges

The thing a router consults is a **routing table**, and the shape of it is the point.

It is not a list of machines — there are billions, and no table could hold them. It is a list of
**ranges of addresses**, each paired with a neighbour to hand them to.

| for addresses in | hand the packet to |
|---|---|
| `203.0.113.0` – `203.0.113.255` | the wire plugged into port 3 |
| `203.0.0.0` – `203.255.255.255` | router C |
| `10.0.0.0` – `10.255.255.255` | router A |
| **everything else** | the default gateway |

Each line covers a whole block of addresses at once. That is what makes the table small enough to
hold: a router near the middle of the internet keeps a few hundred thousand lines, not a few
billion, because each line stands for an enormous range.

When a packet arrives, the router finds which lines cover the destination — and when more than one
does, **the most specific one wins.** In the table above, a packet for `203.0.113.7` matches both
the first line and the second. The first covers 256 addresses and the second covers sixteen
million, so the first is the answer: out of port 3, on this router's own wire.

That rule is what lets a small, precise exception sit above a huge, vague default without anybody
having to reorder anything.

## The last line, and the one on your own machine

The final line of that table is the interesting one. **Everything else → give it to the default
gateway.**

It is the admission of ignorance, and it is what makes the whole scheme work. A router does not
need to know about most of the internet. It needs to know about what is near it, and it needs to
know one neighbour to hand everything else to — a neighbour that is, in general, closer to the
middle and knows more.

**Your own machine has a routing table too**, and it is very short. If you have ever looked at
network settings and seen a field called *default gateway*, that was this: the address of the
router to hand everything to that is not on your own network.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 226\" role=\"img\" aria-label=\"A laptop with a two-line routing table. The first line covers the local network and points at the local wire. The second line covers everything else and points at the default gateway, drawn as an arrow leaving towards the rest of the internet.\"><rect x=\"12\" y=\"58\" width=\"120\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"72\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">your laptop</text><text x=\"72\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.168.1.24</text><rect x=\"162\" y=\"30\" width=\"360\" height=\"52\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".09\" stroke=\"var(--phosphor)\"></rect><text x=\"180\" y=\"50\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">192.168.1.0 – 192.168.1.255</text><text x=\"180\" y=\"68\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">on my own wire — send the frame straight there</text><rect x=\"162\" y=\"98\" width=\"360\" height=\"52\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".09\" stroke=\"var(--amber)\"></rect><text x=\"180\" y=\"118\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">everything else</text><text x=\"180\" y=\"136\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">hand it to 192.168.1.1 — the default gateway</text><path d=\"M132 74 L158 60\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M132 104 L158 122\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"552\" y=\"88\" width=\"156\" height=\"72\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"630\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">your home router</text><text x=\"630\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">it has a default too</text><text x=\"630\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">and so does its default</text><path d=\"M522 124 L548 124\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"360\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">two lines are enough, because the second one is somebody else's problem</text><text x=\"360\" y=\"216\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">this is the field your network settings call \"default gateway\"</text></svg>", "caption": "Almost every machine on the internet routes with two lines: what is next to me, and somebody else."}
```

Follow the chain of defaults upwards and the picture completes itself. Your laptop hands anything
non-local to your home router. Your home router hands anything it does not recognise to your
provider. Your provider hands what it does not recognise further in. Somewhere near the middle are
routers with no default at all — they are expected to know, and they carry those few hundred
thousand lines.

## The counter that stops a loop

Independent decisions have an obvious hazard. If router A believes the way forward is B, and B
believes it is A, a packet bounces between them for ever, and so does every packet after it. The
link fills up with traffic that is going nowhere.

The defence is a single field in the packet header, and it is blunt: a **counter that starts at
around 64 and is reduced by one at every router.** When it reaches zero, the packet is thrown
away.

That is all. Nobody detects the loop, nobody repairs it, nobody is notified — a misdirected packet
simply has a limited number of chances and then ceases to exist. The field is called *time to
live*, which is misleading: it counts hops, not seconds.

## Why traceroute looks the way it does

You will meet `traceroute` in the next lesson, printing a numbered list of the machines between
you and somewhere else. It is worth knowing now that it is a **trick built on that counter**,
because it explains both what the tool shows and what it cannot.

When a router reduces the counter to zero and discards the packet, it usually sends a short
message back: *I threw this away, and here is who I am.*

So: send a packet with the counter set to 1. The first router reduces it to zero, discards it, and
identifies itself. Send another with 2. The second router does the same. Keep going, and the
replies name the machines along the way, one hop at a time.

Which explains two things people find odd about the output. The list is assembled from a dozen
separate probes, so a later line can name a machine on a **different path** from an earlier one —
nothing guarantees they all took the same route. And some lines show nothing at all: a router is
free to decline to send that message, and many do.

## What you are not being told here

The table is the mechanism; **how the lines get into it is a different subject**, and a large one.

Inside one organisation, routers announce to each other what they can reach, and the table
assembles itself. Between organisations — between your provider and a provider in another country
— there is a separate system by which each announces the address ranges it will accept traffic
for, and those announcements propagate worldwide.

Those systems have names, and they are a course of their own: `networks-addressing` is where they
live. What you need here is what the packet experiences, and the packet experiences a table.

## Where this leaves you

A packet crosses the world by being handed along, one router at a time, each choosing the next
step from a list of address ranges — most specific line first, with a default at the bottom for
everything unfamiliar. No machine holds the route, a counter stops the packet if the decisions
disagree, and the path you see in a diagnostic is a reconstruction rather than a record.

There is one thing a router might do that this section has skipped: what happens when the packet
is **too big for the next cable**. That is the next section, and it is the source of a family of
faults that look like nothing else.
