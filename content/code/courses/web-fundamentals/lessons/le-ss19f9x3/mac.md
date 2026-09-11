---
title: The address in the card
version: 1
---

A network card has a number burned into it at the factory. Six bytes, written as twelve
hexadecimal digits in pairs: `a4:83:e7:2f:91:0c`.

This is the **MAC address**, and it is the one a frame is addressed to — which, from lesson two,
means it is the address that matters for exactly one hop and is thrown away at the end of it.

## What makes it different from an IP address

Two properties, and between them they explain why both exist.

**It does not change.** It belongs to the card rather than to the network. Move a laptop from home
to an office to another country and the MAC is identical in all three, while the IP address is
different every time.

**It has no structure.** An IP address can be split into a network part and a host part, which is
what makes routing possible: a router can hold one line for a million addresses. A MAC cannot be
split into anything. There is no "network of MACs" — the first three bytes identify the
manufacturer and nothing else useful.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 208\" role=\"img\" aria-label=\"A comparison of the two addresses. The IP address is shown as changing in three places while the MAC address stays identical, and a note says one is given by the network and the other by the factory.\"><text x=\"140\" y=\"34\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">the same laptop</text><text x=\"400\" y=\"34\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">its IP address</text><text x=\"614\" y=\"34\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">its MAC address</text><rect x=\"24\" y=\"48\" width=\"232\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"140\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">at home</text><text x=\"400\" y=\"70\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">192.168.1.24</text><text x=\"614\" y=\"70\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">a4:83:e7:2f:91:0c</text><rect x=\"24\" y=\"94\" width=\"232\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"140\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">at the office</text><text x=\"400\" y=\"116\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">10.14.3.87</text><text x=\"614\" y=\"116\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">a4:83:e7:2f:91:0c</text><rect x=\"24\" y=\"140\" width=\"232\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"140\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">on a café network</text><text x=\"400\" y=\"162\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">172.20.9.5</text><text x=\"614\" y=\"162\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">a4:83:e7:2f:91:0c</text><text x=\"400\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">given by the network</text><text x=\"614\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">given by the factory</text></svg>", "caption": "Where you are, and what you are. The network decides the first; the manufacturer decided the second."}
```

Put the two together and the division of labour is clear. The IP address says **where in the
world**, and is grouped so that routing is possible. The MAC says **which card on this wire**, and
needs no structure because the question is only ever asked among the few dozen things plugged into
the same switch.

## Why a frame needs one at all

A fair objection at this point: if every machine already has an IP address, why does the frame not
simply carry that?

Because the cable does not know what an IP address is, and that is not a figure of speech. Ethernet
was designed to move frames between cards on a shared medium, and it predates the idea that those
frames would be carrying internet packets at all. It carries anything: it has been used for
protocols that no longer exist and will be used for ones not yet written.

**The layer below must not know what the layer above is carrying.** That is the rule lesson five
generalises, and the MAC address is the clearest example of it in the whole course: a complete
addressing scheme belonging to the wire, ignorant of the addressing scheme riding inside it.

There is a practical payoff too. Because the card knows its own address and accepts only frames
carrying it, a machine can ignore almost everything on a shared wire without waking anything up.
The card filters in hardware; the operating system never sees the rest.

## Three kinds of destination

A frame's destination is not always one card.

**Unicast** is one specific card, which is nearly all traffic.

**Broadcast** is `ff:ff:ff:ff:ff:ff`, and every card on the wire accepts it. It is how a machine
asks a question when it does not yet know who to ask — which is the next section, and the section
after that.

**Multicast** is a group: cards that have opted in accept it and the rest do not. It is how a
television finds a speaker to play to, and how a printer announces itself.

The reason to know the three is that broadcast traffic reaches every machine and costs every
machine a little work, which is the argument for smaller networks you met a section ago. A network
is not slow because it is large; it is slow because everything on it is interrupted by everything
else asking questions.

## It was supposed to be unique, and it is not quite

Manufacturers are allocated blocks, so in principle every card in the world has a different
number. In practice duplicates exist — virtual machines generate them, cheap hardware reuses them,
and a card's address can simply be changed in software on most systems.

Which matters for one reason: **a MAC is not an identity**. Anything that trusts one — a network
that admits a device because it recognises the number, a licence tied to it — is trusting a value
the device chose to report.

The reverse is also worth knowing. Because the number is stable, it can be used to **recognise** a
device across visits, which is what phones defend against by inventing a different MAC for every
network they join. If you have wondered why a phone's address looks different on each Wi-Fi, that
is deliberate.

## Where this leaves you

A MAC address identifies a network card, is fixed to the hardware rather than to the network, has
no internal structure, and is what a frame is addressed to for its single hop.

Which leaves the question this lesson has been building towards. A machine has a packet for
`192.168.1.99`, it has worked out from the mask that this is local, so it must build a frame — and
a frame needs a **MAC address**. It does not have one. It has never seen this neighbour before.

How it finds out is the next section.
