---
title: Seven layers that lost, and stayed
version: 1
---

In 1984 a standards body published a model of how a network ought to be built, in seven layers.
It was thorough, it was international, it was meant to become the stack everybody ran — and it
did not. The thing that won had been running for years already and is the subject of the next
section.

The model stayed anyway, and it is worth knowing why before you learn it: not because your
machine is running it, but because the industry took its **numbers** and never gave them back.
People say *a layer 2 switch*, *a layer 3 problem*, *a layer 7 rule* every working day, and they
mean these seven.

## The seven

Read them from the bottom, because that is the order a message meets them on the way out.

| # | layer | the question it answers | something real |
|---|---|---|---|
| 7 | Application | what does this message mean? | HTTP, SMTP, DNS |
| 6 | Presentation | how are these bytes written down? | character encodings, compression, encryption |
| 5 | Session | is this the same conversation as before? | reopening an interrupted transfer |
| 4 | Transport | which program, and did it all arrive? | TCP, UDP, port numbers |
| 3 | Network | which machine, on which network, and by which route? | IP, routers |
| 2 | Data link | which card on this wire, and did the frame survive? | Ethernet, Wi-Fi, MAC addresses |
| 1 | Physical | what is a one, physically? | voltages, light, radio, the connector |

Layer 1 is where a bit stops being an idea. A one is a voltage on copper, a pulse of light in
glass, a pattern in radio. Nothing at this layer knows what a message is; it knows a one from a
zero and nothing else.

Layer 2 gets those bits from one card to another card **on the same wire**, in frames, with a
check to notice damage. It is the layer that owns MAC addresses, which you met last lesson. Its
reach ends at the edge of the local network, always.

Layer 3 is what makes that edge survivable: addressing and routing across networks that have
never met. It is the narrow waist of the last section, and it is why any of this scales past a
building.

Layer 4 delivers to a **program** rather than a machine — that is what a port is — and, in one of
its two common forms, promises that everything arrives and arrives in order.

Layers 5 and 6 are where the model is at its weakest, and it is more honest to say so than to
invent examples. In a running stack, the jobs are real but they are not separate boxes. The
encryption that layer 6 describes is done by TLS, which a working engineer would sooner call part
of transport or part of the application depending on the argument. And the session that layer 5
describes is usually something the application arranged for itself with a cookie.

Layer 7 is the protocol your program actually speaks, and it is the only layer that knows what any
of it is about.

## Where the numbers earn their keep

The model's lasting contribution is a shared way of saying **how far up a box reads**, and that
turns out to be the most useful single fact about any piece of network equipment.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 350\" role=\"img\" aria-label=\"The seven layers listed down the left. Beside them, four bars of different heights show how far up a hub, a switch, a router and a proxy each read: layer one, layer two, layer three and all seven.\"> <rect x=\"14\" y=\"30\" width=\"186\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"107\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">7 Application</text> <rect x=\"14\" y=\"72\" width=\"186\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"107\" y=\"89\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">6 Presentation</text> <rect x=\"14\" y=\"114\" width=\"186\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"107\" y=\"131\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">5 Session</text> <rect x=\"14\" y=\"156\" width=\"186\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"107\" y=\"173\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">4 Transport</text> <rect x=\"14\" y=\"198\" width=\"186\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"107\" y=\"215\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">3 Network</text> <rect x=\"14\" y=\"240\" width=\"186\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"107\" y=\"257\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">2 Data link</text> <rect x=\"14\" y=\"282\" width=\"186\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"107\" y=\"299\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">1 Physical</text> <rect x=\"230\" y=\"282\" width=\"106\" height=\"34\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".22\" stroke=\"var(--amber)\"></rect> <text x=\"283\" y=\"299\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">a repeater</text> <rect x=\"350\" y=\"240\" width=\"106\" height=\"76\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".22\" stroke=\"var(--amber)\"></rect> <text x=\"403\" y=\"257\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">a switch</text> <rect x=\"470\" y=\"198\" width=\"106\" height=\"118\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".22\" stroke=\"var(--amber)\"></rect> <text x=\"523\" y=\"215\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">a router</text> <rect x=\"590\" y=\"30\" width=\"116\" height=\"286\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"648\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">a proxy</text> <text x=\"460\" y=\"20\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">each bar stops at the last layer that box opens</text> <text x=\"360\" y=\"338\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">everything below the top of a bar is read; everything above it is carried unopened</text> </svg>", "caption": "A piece of network equipment is best described by how far up it reads, and that is the number people quote."}
```

A switch reads to layer 2: it looks at a MAC address, sends the frame out of the right socket, and
never opens the packet. A router reads to layer 3: it opens far enough to see the destination
address, decides the next hop, and goes no further. Each one stops exactly where its job ends,
which is why a switch cannot help you with a routing problem and a router cannot help you with a
duplicate MAC.

The same shorthand names faults. *It is a layer 1 problem* means the cable, the connector, the
radio — check the physical thing before you check anything clever. *Layer 8* is a joke with a
long life, and it means the person using the computer; that a joke about a layer that does not
exist is understood everywhere tells you how thoroughly the numbering took.

## Layer 4 and layer 7, the two you will meet by name

The one place these numbers appear in ordinary web work is in front of servers, and the choice
between them is a real choice with real consequences.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Two load balancers compared. The one that reads to layer four sees only a port number and sends the connection to any server. The one that reads to layer seven sees the path being requested and sends it to the group of servers that handles that path.\"> <text x=\"176\" y=\"20\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">reading up to layer 4</text> <rect x=\"34\" y=\"34\" width=\"284\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect> <text x=\"176\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">all it can see:</text> <text x=\"176\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">a connection to port 443</text> <path d=\"M120 84 L84 140\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path> <path d=\"M176 84 L176 140\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path> <path d=\"M232 84 L268 140\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path> <rect x=\"34\" y=\"146\" width=\"90\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"79\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">server</text> <rect x=\"131\" y=\"146\" width=\"90\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"176\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">server</text> <rect x=\"228\" y=\"146\" width=\"90\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"273\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">server</text> <text x=\"176\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">any of them will do, because</text> <text x=\"176\" y=\"230\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">it cannot tell them apart</text> <text x=\"176\" y=\"258\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">fast, cheap, no certificate needed</text> <text x=\"544\" y=\"20\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\">reading up to layer 7</text> <rect x=\"402\" y=\"34\" width=\"284\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect> <text x=\"544\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">it can also see:</text> <text x=\"544\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">GET /images/logo.png</text> <path d=\"M488 84 L452 140\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path> <path d=\"M544 84 L544 140\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path> <path d=\"M600 84 L636 140\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path> <rect x=\"402\" y=\"146\" width=\"90\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"447\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/images/</text> <rect x=\"499\" y=\"146\" width=\"90\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"544\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">/api/</text> <rect x=\"596\" y=\"146\" width=\"90\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"641\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the rest</text> <text x=\"544\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">it picks the left-hand group, because</text> <text x=\"544\" y=\"230\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">it read the path and they differ</text> <text x=\"544\" y=\"258\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">more work, and it holds your certificate</text> </svg>", "caption": "The same traffic, two boxes, one difference: how far up each is willing to read."}
```

A **layer 4** load balancer reads as far as the port. It can see a connection arriving for port
443 and hand it to one of several machines; it cannot see what is being asked for, because the
request is inside, and — if the traffic is encrypted — it could not read it even if it opened it.
That makes it fast, cheap, and indifferent.

A **layer 7** load balancer reads the request itself. It can send `/images/` to one group of
machines and `/api/` to another, route by hostname, retry a failed request against a different
server, and rewrite headers on the way through. To do any of that it has to decrypt, inspect and
re-encrypt, which costs work and means it holds your certificate.

Neither is the better one. They buy different things, and the sentence people use to decide —
*do we need to route on the URL?* — is a question about which layer you have to read up to.

## What to keep

Not the seven names in order, though they are easy enough. Keep the **shape**: each layer has one
job, each knows only its neighbours, and every device is defined by how far up it is willing to
look.

The next section is the model that is actually running on your machine, and it has four layers.
You will find the seven fit inside it without much trouble.
