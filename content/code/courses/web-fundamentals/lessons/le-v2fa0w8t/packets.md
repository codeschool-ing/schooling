---
title: The packet
version: 1
---

Nothing on the internet travels as a whole. Not a page, not a photograph, not a file, not a
sentence you typed into a chat. Everything is cut into pieces first, and the pieces travel
separately.

That is not an optimisation somebody added later. It is the founding decision, and almost
everything in this lesson — and a good deal of the rest of this course — falls out of it.

## The thing the internet refuses to do

Before the internet there was the telephone network, and the telephone network worked by
**reserving a path**.

When you placed a long-distance call, equipment along the route selected a circuit and held it
open: a continuous electrical path from your handset to theirs, yours alone, for the whole
duration of the call. It did not matter whether you were talking or silent. The path was
committed.

That design has one enormous virtue. Once the circuit exists, everything that goes into one end
comes out of the other, in order, at a steady rate, with nothing to think about.

It also has a cost that becomes unbearable at scale.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two panels. On the left, a reserved circuit: one continuous line from a caller to a receiver, with a silent gap in the middle still occupying the whole line. On the right, a shared line carrying short blocks from three different senders interleaved, with no gaps.\"><rect x=\"8\" y=\"14\" width=\"340\" height=\"214\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"178\" y=\"38\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">A reserved circuit</text><text x=\"178\" y=\"57\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">one call owns the line</text><rect x=\"28\" y=\"86\" width=\"300\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".22\" stroke=\"var(--phosphor)\"></rect><text x=\"178\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">held open, end to end</text><rect x=\"128\" y=\"126\" width=\"104\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-dasharray=\"3 3\"></rect><text x=\"180\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nobody speaking</text><text x=\"178\" y=\"186\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">the silence costs the same as the talking</text><text x=\"178\" y=\"208\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">and no one else may use it</text><rect x=\"372\" y=\"14\" width=\"340\" height=\"214\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"542\" y=\"38\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">A shared line</text><text x=\"542\" y=\"57\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">three conversations, interleaved</text><rect x=\"392\" y=\"86\" width=\"54\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><rect x=\"450\" y=\"86\" width=\"54\" height=\"30\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".3\" stroke=\"var(--amber)\"></rect><rect x=\"508\" y=\"86\" width=\"54\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".3\" stroke=\"var(--phosphor)\"></rect><rect x=\"566\" y=\"86\" width=\"54\" height=\"30\" rx=\"2\" fill=\"var(--phosphor-dim)\" fill-opacity=\".4\" stroke=\"var(--phosphor-dim)\"></rect><rect x=\"624\" y=\"86\" width=\"54\" height=\"30\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".3\" stroke=\"var(--amber)\"></rect><text x=\"542\" y=\"140\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">each block carries its own destination</text><text x=\"542\" y=\"186\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">a pause by one is capacity for another</text><text x=\"542\" y=\"208\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">nothing is reserved</text></svg>", "caption": "The trade the internet made. A reserved path is simple and idle most of the time; a shared one is complicated and never idle."}
```

A conversation is mostly silence. You pause, you think, you listen. On a reserved circuit every
one of those pauses is a piece of the network that exists, costs money, and carries nothing. To
serve a thousand simultaneous calls you need a thousand paths, whether or not anybody is
speaking.

The internet declined the whole arrangement. **There is no path between you and the machine
serving this page.** Nothing was reserved when you opened it and nothing will be released when you
close it. The line your message travels on is shared with everybody else's, at every step, all the
time.

And that immediately creates a problem which the rest of this lesson is the answer to: if the line
is shared and nothing is reserved, then **each piece of your message has to say for itself where
it is going**. There is no circuit to carry that knowledge for it.

## A packet is a label and a load

That piece is a **packet**, and it has exactly two parts.

The **header** is the label. It is a fixed, compact set of fields that say where the packet is
going, where it came from, how long it is, and a few other things machinery along the way needs.

The **payload** is the load — the slice of your actual message.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"A packet drawn as a long rectangle split into two. A narrow left part labelled header, listing source, destination, length and time to live. A wide right part labelled payload, holding a slice of the message.\"><rect x=\"14\" y=\"40\" width=\"692\" height=\"96\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"14\" y=\"40\" width=\"246\" height=\"96\" rx=\"4\" fill=\"var(--phosphor)\" fill-opacity=\".1\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"137\" y=\"28\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">HEADER</text><text x=\"483\" y=\"28\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper-dim)\">PAYLOAD</text><text x=\"32\" y=\"62\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">from  198.51.100.4</text><text x=\"32\" y=\"80\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">to    203.0.113.7</text><text x=\"32\" y=\"98\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">length 1500</text><text x=\"32\" y=\"116\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">ttl    58</text><text x=\"483\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">...one slice of what you are sending...</text><text x=\"483\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nothing on the way reads this</text><text x=\"137\" y=\"164\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">read at every step</text><text x=\"483\" y=\"164\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">read only at the end</text><text x=\"360\" y=\"192\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the label is small on purpose — it is paid for on every packet</text></svg>", "caption": "Every packet carries its own addressing. That is the price of a network that reserves nothing for you."}
```

The header is small — typically twenty bytes for the addressing layer — and it is small for a
reason worth noticing. It rides on **every single packet**. A page made of two thousand packets
pays for that label two thousand times. Every field in a header had to argue for its existence
against being multiplied by the traffic of the entire world.

## What a router reads, and what it does not

Here is the part that surprises people, and it matters for the rest of the course.

A router — one of the machines that moves your packet along — reads **the header**. Mostly it
reads one field of the header: the destination. It looks at where the packet is going, decides
which way to send it onwards, and sends it.

**It does not open the payload.** It has no interest in whether your packet contains a paragraph
of a news article, a fragment of a photograph, or a quarter of a second of somebody's voice. It
does not know and does not need to know.

That single fact explains a startling amount:

- **the network is general.** Nobody had to teach routers about video calls before video calls
  could exist. A new kind of application is a new thing to put in payloads, and the machinery in
  the middle never learns about it;
- **HTTPS can work at all.** If the middle had to understand your data, encrypting it would break
  the network. Because the middle only reads the label, you can seal the load;
- **and "the network is slow for this app" is usually the wrong diagnosis.** The network is not
  treating your application specially. It does not know which application it is.

## Every packet travels alone

The consequence people find hardest to believe is this one: **the pieces of one message are not a
convoy.** They are not tied together. Nothing is escorting them.

Each packet is handled on its own, by each machine it meets, on the evidence in its own header.
Two packets of the same message, sent one after the other, can take different routes — and if a
link goes down or a queue builds up between the first and the second, they will.

Which means they can arrive **out of order**. Not as a fault. As ordinary behaviour.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 236\" role=\"img\" aria-label=\"A message cut into four numbered packets on the left. Two different routes across the middle: packets one and four take the upper route, packets two and three take the lower one. On the right they arrive in the order one, three, two, four.\"><rect x=\"10\" y=\"78\" width=\"96\" height=\"78\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"58\" y=\"104\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">sender</text><text x=\"58\" y=\"124\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1 2 3 4</text><text x=\"58\" y=\"142\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">in order</text><rect x=\"272\" y=\"30\" width=\"72\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"308\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">route A</text><rect x=\"272\" y=\"172\" width=\"72\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"308\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">route B</text><text x=\"308\" y=\"22\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">carries 1 and 4</text><text x=\"308\" y=\"224\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">carries 2 and 3 — and queues</text><path d=\"M106 100 C 180 100, 200 47, 266 47\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M106 134 C 180 134, 200 189, 266 189\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M344 47 C 410 47, 430 100, 496 100\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M344 189 C 410 189, 430 134, 496 134\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"500\" y=\"78\" width=\"96\" height=\"78\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"548\" y=\"104\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">receiver</text><text x=\"548\" y=\"124\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">1 3 2 4</text><text x=\"548\" y=\"142\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">as they landed</text><rect x=\"610\" y=\"84\" width=\"98\" height=\"66\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".1\" stroke=\"var(--amber)\"></rect><text x=\"659\" y=\"106\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">this is normal,</text><text x=\"659\" y=\"122\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">not a failure</text><text x=\"659\" y=\"140\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">somebody reorders</text></svg>", "caption": "Four packets, two routes, and an arrival order nobody promised. Putting them back in order is somebody's job — and this lesson ends by naming who."}
```

So: a packet can arrive late, it can arrive out of order, and it can **not arrive at all**. A
queue somewhere fills up and a router drops it, which is not a malfunction — it is what a router
does when more arrives than it can send.

Read that list again and notice what the network is promising. It is promising to **try**. That is
the whole promise. Best effort: I will do what I reasonably can with this packet, and I will not
tell you if I fail.

Everything that feels more reliable than that — a file that downloads correctly, a page that
renders whole, a message that arrives once and in one piece — is built **on top of** this promise
by the two machines at the ends. The middle does not participate. You will meet the machinery for
it in *Ordered and acknowledged, or fast and unacknowledged*, at the end of this lesson.

## Store and forward, and where latency comes from

One more mechanical detail, because it explains a number you will measure in the next lesson.

A router does not begin sending a packet onwards while it is still arriving. It **receives the
whole packet**, then looks at it, then sends it. This is called *store and forward*, and it is
forced: you cannot read a header that has not fully arrived, and you cannot check that a packet is
intact until you have all of it.

So every hop adds a small delay of its own — the time to take the packet in, plus the time it
spends waiting behind whatever else is queued for the same outgoing link.

A dozen hops, each adding its little pause, is a significant part of what you will later measure
as **latency**. It is not friction in a wire. It is a queue of decisions, taken one machine at a
time.

## What a packet does not have

It is worth being explicit about the things a packet is not, because each of them is something
people assume.

A packet has no **connection**. There is nothing in the header that says "this belongs to the
conversation you and I have been having". The idea of a connection exists only in the memory of
the two machines at the ends — you will see exactly how in *Address plus port*.

A packet has no **order**. Nothing in the addressing header says "I am the fourth". Something
above it does, and that something is not the network's.

A packet has no **guarantee**. Nobody signed for it and nobody will tell you if it was dropped.

And a packet has no **route**. It does not carry a plan of where to go. It carries a destination,
and every machine it meets makes its own independent decision about where to send it next. That
decision is the subject of *How a packet crosses a network it does not belong to*, two sections
from here.

## Where this leaves you

The internet does not carry your message. It carries labelled pieces of it, one at a time,
independently, on a line it shares with everybody, and it is allowed to lose them.

Every other idea in this lesson is a repair for something in that sentence. The **frame** is how a
piece survives one step of the journey. **MTU** is how big a piece is allowed to be. The
**socket** is how a piece finds the right program once it arrives. And **TCP** is how two machines
build order and reliability out of a network that offers neither.
