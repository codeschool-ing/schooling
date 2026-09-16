---
title: The frame, and one hop
version: 1
---

A packet knows where it is ultimately going. It does not know how to get there, and — this is the
part that takes a moment — **it cannot travel anywhere by itself**.

A packet is an idea. Cables carry electricity, fibre carries light, and radios carry radio. None
of them carry ideas. So at every physical step of the journey, the packet has to be wrapped in
something the local medium actually knows how to deliver.

That wrapper is a **frame**.

## Two envelopes, two lifetimes

Here is the whole distinction, and it is worth reading slowly because everything else in this
section is a consequence.

**The packet is addressed to the destination.** It is created by the machine that sent it, and the
same packet — the same header, the same payload — arrives at the other end. It crosses the whole
journey.

**The frame is addressed to the next machine on this cable.** It is created at the start of one
hop, and it is destroyed at the end of that same hop. The next hop builds a brand new one.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 254\" role=\"img\" aria-label=\"A packet crossing four machines. Above the line, one long bar labelled packet spanning the whole journey. Below it, four separate short bars, one per hop, each labelled frame and each a different colour, showing they are built and destroyed per hop.\"><rect x=\"14\" y=\"96\" width=\"104\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"66\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">your laptop</text><rect x=\"202\" y=\"96\" width=\"104\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"254\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">home router</text><rect x=\"390\" y=\"96\" width=\"104\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"442\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">ISP router</text><rect x=\"578\" y=\"96\" width=\"128\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"642\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the server</text><rect x=\"14\" y=\"36\" width=\"692\" height=\"28\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".14\" stroke=\"var(--phosphor)\"></rect><text x=\"360\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">ONE PACKET — the same one, the whole way</text><text x=\"360\" y=\"26\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">to 203.0.113.7</text><rect x=\"118\" y=\"174\" width=\"84\" height=\"26\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".16\" stroke=\"var(--amber)\"></rect><text x=\"160\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">frame 1</text><rect x=\"306\" y=\"174\" width=\"84\" height=\"26\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".16\" stroke=\"var(--amber)\"></rect><text x=\"348\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">frame 2</text><rect x=\"494\" y=\"174\" width=\"84\" height=\"26\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".16\" stroke=\"var(--amber)\"></rect><text x=\"536\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">frame 3</text><path d=\"M118 142 L160 170\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\" fill=\"none\"></path><path d=\"M202 142 L162 170\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\" fill=\"none\"></path><path d=\"M306 142 L348 170\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\" fill=\"none\"></path><path d=\"M390 142 L350 170\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\" fill=\"none\"></path><path d=\"M494 142 L536 170\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\" fill=\"none\"></path><path d=\"M578 142 L538 170\" stroke=\"var(--amber)\" stroke-width=\"1\" stroke-dasharray=\"3 3\" fill=\"none\"></path><text x=\"360\" y=\"228\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">THREE FRAMES — each built for one cable and thrown away at its end</text></svg>", "caption": "One packet, three frames. The packet is the journey; a frame is a single step of it."}
```

Three hops, three frames. Each one is written, carried a few metres or a few hundred kilometres,
read, and discarded. The packet inside is untouched.

If you take one thing from this section, take this: **a frame is not a small packet.** They are
different objects with different addresses and different lifetimes, and confusing them is what
makes the next four lessons feel arbitrary.

## Two kinds of address, for two kinds of question

The two envelopes carry two different kinds of address, because they answer two different
questions.

The packet's address answers *where in the world*. The frame's address answers *which socket on
this cable*.

| | the packet's address | the frame's address |
|---|---|---|
| answers | where in the world is this going | which machine on this wire takes it next |
| given by | the network you are on, and it changes when you move | the network card, at the factory |
| survives | the whole journey | one hop |
| you will meet it properly in | lesson 4 | lesson 4 |

For now you need nothing more than "a number that names a machine" for the first and "a number
burned into a network card" for the second. Lesson 4 is where both get read properly — the
notation, the ranges, and how a machine learns its neighbour's card number in the first place.

## The box that never opens the envelope

Not every box in the path builds a new frame. Some of them just pass frames along, and the
difference between the two is the clearest way to understand where a frame stops.

A **switch** is the box your office or your home network is built out of. It has several ports,
things are plugged into them, and its job is to take a frame in at one port and put it out of the
right one. It keeps a table of which card number lives on which port, and it consults that table.

What it does **not** do is open the frame. It never looks at the packet inside. It does not know
or care what the packet's final destination is — as far as a switch is concerned, a frame is
addressed to a machine on this network, and the only question is which port that machine is on.

A **router** is the other kind of box, and it does the opposite. It takes the frame apart,
**throws it away**, reads the packet inside, decides which of its own connections the packet
should go out on, and builds a **brand new frame** for that next hop.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 246\" role=\"img\" aria-label=\"Two panels side by side. On the left a switch passing a frame from one port to another with the frame unchanged and the packet inside untouched. On the right a router unwrapping the frame, reading the packet, and building a new frame.\"><rect x=\"8\" y=\"14\" width=\"340\" height=\"218\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"178\" y=\"38\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">A switch</text><text x=\"178\" y=\"56\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">same frame, different port</text><rect x=\"26\" y=\"88\" width=\"128\" height=\"40\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".14\" stroke=\"var(--amber)\"></rect><text x=\"90\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">frame</text><rect x=\"38\" y=\"108\" width=\"104\" height=\"16\" rx=\"1\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect><text x=\"90\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">packet</text><rect x=\"202\" y=\"88\" width=\"128\" height=\"40\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".14\" stroke=\"var(--amber)\"></rect><text x=\"266\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">same frame</text><rect x=\"214\" y=\"108\" width=\"104\" height=\"16\" rx=\"1\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect><text x=\"266\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">untouched</text><path d=\"M156 108 L198 108\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"178\" y=\"162\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">never opens it</text><text x=\"178\" y=\"184\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">never sees the destination</text><text x=\"178\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the frame does NOT stop here</text><rect x=\"372\" y=\"14\" width=\"340\" height=\"218\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"542\" y=\"38\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">A router</text><text x=\"542\" y=\"56\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">new frame, same packet</text><rect x=\"390\" y=\"88\" width=\"128\" height=\"40\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".14\" stroke=\"var(--amber)\" stroke-dasharray=\"3 3\"></rect><text x=\"454\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">frame discarded</text><rect x=\"402\" y=\"108\" width=\"104\" height=\"16\" rx=\"1\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect><text x=\"454\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">packet read</text><rect x=\"566\" y=\"88\" width=\"128\" height=\"40\" rx=\"2\" fill=\"var(--phosphor-dim)\" fill-opacity=\".2\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"630\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">NEW frame</text><rect x=\"578\" y=\"108\" width=\"104\" height=\"16\" rx=\"1\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect><text x=\"630\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">same packet</text><path d=\"M520 108 L562 108\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"542\" y=\"162\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">opens it, every time</text><text x=\"542\" y=\"184\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">reads the destination, then decides</text><text x=\"542\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the frame stops HERE</text></svg>", "caption": "The two boxes, and the difference that matters: a switch moves a frame, a router replaces one."}
```

So the answer to *where does a frame stop* is precise: **a frame stops at the first router.** It
passes through any number of switches on the way — they are not stops, they are corridors — and it
ends the moment it reaches something that has to read the packet inside.

## Why two layers instead of one

A fair question at this point: why not have one envelope? Why not put the world-wide address on
the thing the cable carries and be done with it?

Because the cable and the world are different problems, and they change on different schedules.

The world-wide part has to work the same everywhere: the same packet has to be meaningful to a
machine in another country, on hardware bought from a different manufacturer, twenty years later.

The cable part has to be whatever **this particular medium** needs. Ethernet has a way of putting
bits on copper and detecting a collision. Wi-Fi has a completely different problem — a shared
radio space, interference, a device that moves — and solves it with acknowledgements and retries
that Ethernet has never needed.

Splitting them means each can change without touching the other. Wi-Fi was invented, went through
five generations, and became the way most people connect — and **not one packet header had to
change**. Your laptop's frame going out over radio is nothing like your router's frame going out
over fibre, and the packet they carry is byte for byte identical.

This wrapping — a thing that means something, inside a thing that can be delivered — is a pattern
rather than a one-off. It happens more than twice, and the full stack of it is *Layered networks*,
lesson 5. Here you are seeing one real instance of it; there it becomes the principle.

## What a frame adds at the end

One small thing at the tail of a frame is worth naming, because it explains a word you will meet
in the next lesson.

A frame carries a **checksum** — a number computed from its contents, written at the end by the
sender, and recomputed by the receiver. If the two disagree, something was corrupted on the way: a
bad connector, interference, a failing cable.

What happens then is the interesting part. The receiver **throws the frame away and says
nothing**. There is no complaint sent back, no request to resend, no log entry anybody will read.
The frame simply does not exist any more, and the packet inside it went with it.

Which means corruption on a wire arrives at the two machines at the ends looking exactly like a
router dropping a packet in a full queue: something was sent, and nothing came. The network's
promise is still only best effort, and now you have seen two different ways it can quietly fail to
keep it.

## Where this leaves you

A packet crosses the whole journey. A frame crosses one hop, and is built and destroyed at each
end of it. Switches move frames without opening them; routers open them, read the packet, and
build a new frame for the next step.

Which raises the question that this section has been carefully not answering: when a router reads
the packet's destination, **how does it decide where to send it next?** That is the next section,
and it is the piece that turns a pile of independent machines into something a packet can cross.
