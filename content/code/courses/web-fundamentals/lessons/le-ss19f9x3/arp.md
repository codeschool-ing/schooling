---
title: Asking the wire
version: 1
---

Your machine has a packet for `192.168.1.99`. The mask says that address is local, so there is no
gateway involved: the frame goes straight there.

Except a frame is addressed to a **MAC**, and your machine does not know `192.168.1.99`'s MAC. It
has an address on one layer and needs one on the other, and nothing it has been told so far
connects them.

## The answer is to shout

There is no directory. Nothing on a local network holds a list of which IP belongs to which card.
So the machine asks everybody at once.

It builds a frame addressed to the **broadcast** MAC — `ff:ff:ff:ff:ff:ff`, which every card on
the wire accepts — carrying one question: *who has `192.168.1.99`? Tell `192.168.1.24`.*

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"One machine sends a broadcast question to four others on the same wire. Three ignore it. The one that holds the address answers directly with its MAC address.\"><rect x=\"14\" y=\"40\" width=\"132\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"80\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">asking</text><text x=\"80\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.168.1.24</text><text x=\"360\" y=\"26\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">to ff:ff:ff:ff:ff:ff — who has 192.168.1.99?</text><rect x=\"246\" y=\"40\" width=\"108\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"300\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.168.1.7</text><text x=\"300\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">not me</text><rect x=\"366\" y=\"40\" width=\"108\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"420\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">192.168.1.8</text><text x=\"420\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">not me</text><rect x=\"486\" y=\"40\" width=\"120\" height=\"52\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".16\" stroke=\"var(--phosphor)\"></rect><text x=\"546\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">192.168.1.99</text><text x=\"546\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">that is me</text><path d=\"M146 66 L242 66\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M358 66 L362 66\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M478 66 L482 66\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M486 122 L150 122\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"318\" y=\"140\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">straight back, not to everybody: a4:83:e7:2f:91:0c</text><text x=\"360\" y=\"182\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the question goes to everyone; the answer goes to one</text><text x=\"360\" y=\"206\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">and both of them write the pairing down for a few minutes</text></svg>", "caption": "There is no directory, so the machine asks the whole wire. Only the one that recognises the address replies."}
```

Every machine on the wire receives the question. Every machine that is not `192.168.1.99` discards
it. The one that is answers — **directly, not to everybody** — with its MAC address.

That exchange is **ARP**, the address resolution protocol, and it is the join between the two
layers this lesson is about.

## The cache, and why the first packet is slower

Doing that before every frame would be absurd, so the answer is written down. Every machine keeps
an **ARP cache** of IP-to-MAC pairings, typically for a few minutes.

Which is why the very first packet to a machine you have not spoken to recently is a little
slower: there is a broadcast and a reply before it can even be wrapped. It is a millisecond on a
local network, and it is the reason the first attempt at anything is never the one to measure.

The entries expire on purpose. A card can be replaced, a machine can be given a different address,
and a cache that never forgot would be wrong for ever after either.

## What a machine does before it asks

The cache is consulted first, obviously. What is less obvious is that a machine fills it without
being asked to.

Because the question is a broadcast, **every machine on the wire sees it** — and the question
carries the asker's own address and MAC. So a machine that overhears *who has `.99`? tell `.24`*
learns where `.24` is, whether or not it cares. By the time two machines need to talk, each has
often already heard of the other.

Some machines go further and announce themselves on purpose. A machine that has just been given an
address sends a question about **its own** address — not because it expects an answer, but so that
everything on the wire updates its cache, and so that a reply would reveal somebody else already
using it. That is how a duplicate address is detected, and it is why two machines configured with
the same address produce a complaint on both rather than silence.

## Nobody checks the answer

Here is the part worth carrying beyond this course.

**ARP has no authentication of any kind.** The question goes to everybody, and the first answer is
believed. Nothing verifies that the machine replying is the one that holds the address, because
there is nothing on a local network that could do the verifying.

So any machine on your wire can answer *I am the gateway* and receive traffic meant for the
gateway. It is called ARP spoofing, it is the foundation of most attacks that happen on a local
network rather than across the internet, and it is not a bug: it is what a protocol designed in
1982 for a trusted cable looks like today.

The practical consequence is simple and it is why HTTPS matters more than people think. **A local
network is not a place where you can trust who you are talking to.** What protects you is
encryption between the two ends, not the wire between them.

## IPv6 does it differently and the same

IPv6 has no ARP. It uses *neighbour discovery*, which asks a group rather than shouting at
everybody, and is a better-behaved design.

It solves the same problem in the same shape — a question on the local wire, an answer, a cache
with a timeout — and it inherits most of the same trust properties. Knowing the shape is what
carries over.

## Where this leaves you

ARP is how a machine turns a local IP address into the MAC address a frame needs: a broadcast
question, a direct answer, and a cache with a short life. It is the join between the address that
crosses the world and the address that crosses one wire, and it trusts whoever replies first.

All of this has assumed your machine already has an address. **Where did it come from?** Nobody
typed it. That is the next section, and it is the last piece before the video.
