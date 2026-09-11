---
title: One job each, and a narrow door
version: 1
---

Everything you have met so far was invented by different people, at different times, for
different reasons. The cable came out of telephone engineering. The packet came out of a research
network. The address came out of a committee. The browser came out of a physics laboratory, two
decades after the rest of it.

None of them was designed with the others in mind. All of them work together this evening. That
is not luck, and it is not tidiness: it is a decision somebody made about who is allowed to know
what.

## The alternative, counted

Suppose there were no layers — that a program wanting to send something had to know how to send
it. Not hand it over: actually put it on the wire, with whatever a wire happens to be today.

Then a browser would need one version for Ethernet, one for Wi-Fi, one for fibre, one for a
mobile network, one for satellite. So would an email client, a video call, a file transfer.

Five ways of carrying and eight things to carry is forty pieces of work — and a forty-first the
morning somebody invents a new kind of radio, plus eight more to teach the programs about it.

With one agreed layer in between, the arithmetic changes shape. Each of the eight programs learns
a single thing: how to hand a message down. Each of the five technologies learns a single thing:
how to accept a message from above. Thirteen pieces of work, and the new radio costs one — a one
that no program has to be told about at all.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Five application protocols at the top narrow down to one internet layer in the middle, which widens again to five carrying technologies at the bottom. Anything can be added at the top or the bottom by agreeing with the middle alone.\"> <text x=\"360\" y=\"20\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">anything at all, invented by anybody</text> <rect x=\"20\" y=\"34\" width=\"116\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect> <text x=\"78\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">the web</text> <rect x=\"152\" y=\"34\" width=\"116\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect> <text x=\"210\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">email</text> <rect x=\"284\" y=\"34\" width=\"116\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect> <text x=\"342\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">video call</text> <rect x=\"416\" y=\"34\" width=\"116\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect> <text x=\"474\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">file transfer</text> <rect x=\"548\" y=\"34\" width=\"152\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect> <text x=\"624\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">whatever is next</text> <path d=\"M78 72 L300 132\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path> <path d=\"M210 72 L330 132\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path> <path d=\"M342 72 L356 132\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path> <path d=\"M474 72 L386 132\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path> <path d=\"M624 72 L416 132\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path> <rect x=\"248\" y=\"138\" width=\"224\" height=\"52\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".16\" stroke=\"var(--phosphor)\"></rect> <text x=\"360\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">one way to address</text> <text x=\"360\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">and deliver a packet</text> <path d=\"M300 196 L78 256\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path> <path d=\"M330 196 L210 256\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path> <path d=\"M356 196 L342 256\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path> <path d=\"M386 196 L474 256\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path> <path d=\"M416 196 L624 256\" stroke=\"var(--wire)\" stroke-width=\"1.1\" fill=\"none\"></path> <rect x=\"20\" y=\"260\" width=\"116\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect> <text x=\"78\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Ethernet</text> <rect x=\"152\" y=\"260\" width=\"116\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect> <text x=\"210\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Wi-Fi</text> <rect x=\"284\" y=\"260\" width=\"116\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect> <text x=\"342\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">fibre</text> <rect x=\"416\" y=\"260\" width=\"116\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect> <text x=\"474\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">mobile</text> <rect x=\"548\" y=\"260\" width=\"152\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect> <text x=\"624\" y=\"278\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">whatever is next</text> <text x=\"360\" y=\"316\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">anything at all, built by anybody</text> </svg>", "caption": "Agree with the middle and you are done. Nothing at the top has to be told about anything at the bottom."}
```

That shape has a name here: the **narrow waist**. Above it, anything at all; below it, anything at
all; in the middle, one thing everybody agrees on and nobody is allowed to go around.

## Two rules, and the second one is the load-bearing one

The arrangement only pays if the rules are kept, and there are two of them.

The first: **a layer talks to the layer directly above and the layer directly below.** Not two
down. Not sideways. The door is narrow on purpose, because a narrow door is one you can replace
what is behind.

The second: **a layer does not look inside what it was given.** It takes a bundle of bytes, does
its own job, adds its own part, and passes the bundle on. What those bytes mean is the business of
whichever layer produced them, and of the matching layer at the far end.

The second rule is the one doing the work. If a router along the way opened your message and
behaved differently depending on what it said, then the message could not change unless the
routers changed too — and there are a great many routers, owned by a great many people who have
never heard of you. Because the router does not open it, a protocol designed this afternoon
travels tonight across equipment installed a decade ago, which has never heard of it and does not
need to.

## What has already been replaced under your feet

This is not a hypothetical benefit; it has been collected several times in your lifetime.

The page you are reading was designed when a household reached the internet over a telephone line
at a few thousand bits a second. Since then the bottom of the stack has been torn out and
replaced by DSL, then by cable, then by fibre, then — for most people most of the time — by a
radio link to a box in the hallway. Underneath the street, copper became glass.

Not one line of any web page was rewritten for any of it. The application layer was not asked,
because the application layer is not entitled to an opinion about what the bottom of the stack is
made of.

It runs upwards too. The addresses of the last lesson are being replaced, slowly, and a machine
speaking IPv6 runs the same browsers, the same servers and the same protocols as one speaking
IPv4. The layer changed; its neighbours' expectations did not.

## What it costs

Three prices, and they are all real.

**Bytes.** Every layer adds a header, and a header is space you are paying for without sending any
of your own content. On a large transfer that is a rounding error. On small, frequent messages it
is most of the traffic.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two bars drawn to the same scale. In the first, one byte of content carries fifty-four bytes of headers. In the second, fourteen hundred and sixty bytes of content carry the same fifty-four.\"> <text x=\"20\" y=\"26\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a keystroke sent on its own</text> <rect x=\"20\" y=\"38\" width=\"176\" height=\"38\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"108\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">frame 14</text> <rect x=\"196\" y=\"38\" width=\"252\" height=\"38\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"322\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">IP 20</text> <rect x=\"448\" y=\"38\" width=\"252\" height=\"38\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <text x=\"574\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">TCP 20</text> <text x=\"20\" y=\"98\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">your byte is the sliver at the far right — 1 of 55, under two per cent</text> <text x=\"20\" y=\"146\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a full packet of a download, same scale</text> <rect x=\"20\" y=\"158\" width=\"6.5\" height=\"38\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <rect x=\"26.5\" y=\"158\" width=\"9\" height=\"38\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <rect x=\"35.5\" y=\"158\" width=\"9\" height=\"38\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect> <rect x=\"44.5\" y=\"158\" width=\"655.5\" height=\"38\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"372\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1460 bytes of what you actually asked for</text> <text x=\"20\" y=\"218\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">the same 54 bytes of headers — now three and a half per cent</text> <text x=\"20\" y=\"240\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">the headers are a fixed cost, so the bill depends entirely on how much you put behind them</text> </svg>", "caption": "The overhead never changes size. What changes is how much you sent with it."}
```

**Work.** Each boundary is a handover: a length to be checked, a header to be found, bytes to be
copied or accounted for. Small, and performed for every packet of every connection of every
machine, which is how small things become the reason a device runs warm.

**Blindness.** A layer that cannot see what its neighbours know sometimes guesses, and sometimes
guesses badly. The classic case is loss. The transport layer treats a missing packet as a sign
that the network is overloaded, and slows down — which is right on a congested wire, and wrong on
Wi-Fi, where a packet is much more often lost to a microwave oven than to congestion. Slowing down
does not help with the microwave. Transport cannot tell the difference, because the layer that
could tell it is not allowed to.

## The pressure to cheat

Once you know the rules, you start noticing where they are broken, and the clearest example is one
you met in the last lesson.

A router belongs to the layer that handles addresses. A port number belongs to the layer above it.
NAT reads and rewrites both — which means a device is reaching up into a header it has no business
opening, and depends on that header staying the shape it expects.

The consequence arrives later, and lands on somebody else. A new transport protocol, laid out
differently, meets millions of boxes that were built to reach up and find a port where a port used
to be. They do not understand it, so they drop it, and the new protocol fails on networks that
have no idea they are the reason. It is not a hypothetical, either: it is why the newest transport
in common use had to disguise itself as an older one to get through, a story this course returns
to when it reaches HTTP/3.

A layer violation buys something immediately and charges for it for twenty years.
