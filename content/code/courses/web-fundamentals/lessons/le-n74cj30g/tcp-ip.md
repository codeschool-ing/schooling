---
title: The four that actually run
version: 1
---

While the seven-layer model was being written, something simpler was already carrying traffic
between universities, and had been for years. It had four layers, no committee behind it, a free
implementation anybody could copy, and it did not attempt to describe everything.

It is what your machine is running right now, and it is named after two of its protocols: TCP/IP.

## The four

| layer | what it does | what runs there |
|---|---|---|
| Application | the protocol your program speaks | HTTP, DNS, SMTP, SSH |
| Transport | to which program, and did it all arrive? | TCP, UDP |
| Internet | to which machine, by which route? | IP, and the errors it reports |
| Link | onto this particular wire | Ethernet, Wi-Fi, and the card |

Four rather than seven, and the difference is not really a disagreement. It is that three of the
seven were folded into one, and two more into another.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"The seven-layer model on the left beside the four-layer model on the right. The top three of the seven correspond to the single application layer, transport and network match one to one, and the bottom two correspond to the single link layer.\"> <text x=\"150\" y=\"20\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper-dim)\">the seven, as published</text> <text x=\"540\" y=\"20\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--phosphor)\">the four, as running</text> <rect x=\"30\" y=\"32\" width=\"240\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"150\" y=\"47\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">7 Application</text> <rect x=\"30\" y=\"66\" width=\"240\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"150\" y=\"81\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">6 Presentation</text> <rect x=\"30\" y=\"100\" width=\"240\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"150\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">5 Session</text> <rect x=\"30\" y=\"140\" width=\"240\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"150\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">4 Transport</text> <rect x=\"30\" y=\"180\" width=\"240\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"150\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">3 Network</text> <rect x=\"30\" y=\"220\" width=\"240\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"150\" y=\"235\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">2 Data link</text> <rect x=\"30\" y=\"254\" width=\"240\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"150\" y=\"269\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">1 Physical</text> <path d=\"M276 47 L414 74\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" fill=\"none\"></path> <path d=\"M276 81 L414 81\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" fill=\"none\"></path> <path d=\"M276 115 L414 88\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" fill=\"none\"></path> <path d=\"M276 155 L414 155\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" fill=\"none\"></path> <path d=\"M276 195 L414 195\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" fill=\"none\"></path> <path d=\"M276 235 L414 262\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" fill=\"none\"></path> <path d=\"M276 269 L414 269\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" fill=\"none\"></path> <rect x=\"420\" y=\"32\" width=\"266\" height=\"98\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".16\" stroke=\"var(--phosphor)\"></rect> <text x=\"553\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Application</text> <text x=\"553\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">HTTP, DNS, SMTP, SSH</text> <rect x=\"420\" y=\"140\" width=\"266\" height=\"30\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".16\" stroke=\"var(--phosphor)\"></rect> <text x=\"553\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Transport — TCP, UDP</text> <rect x=\"420\" y=\"180\" width=\"266\" height=\"30\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".16\" stroke=\"var(--phosphor)\"></rect> <text x=\"553\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Internet — IP</text> <rect x=\"420\" y=\"220\" width=\"266\" height=\"64\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".16\" stroke=\"var(--phosphor)\"></rect> <text x=\"553\" y=\"241\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Link</text> <text x=\"553\" y=\"263\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Ethernet, Wi-Fi, the card</text> <text x=\"360\" y=\"312\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">the two middle layers match one to one; the ends were folded, for two different reasons</text> </svg>", "caption": "The four are not a rival account of the seven. They are the seven with both ends handed to somebody else."}
```

The top three collapse because the split was never observed in practice: a program that speaks
HTTP also decides its own encoding, its own compression and its own idea of a conversation. There
was no boundary there to keep, so this model does not draw one and leaves those decisions to
whoever writes the protocol.

The bottom two collapse for the opposite reason — not because the split is imaginary but because
it is somebody else's. What a one is, physically, and how frames are put on the wire are decided
together by whoever designed Ethernet or Wi-Fi. This model says *put it on the wire* and declines
to specify the wire, which is exactly the narrow waist from the first section, seen from below.

## Why this one won

Four reasons, and only the last is about the design.

It was **running**. A model is an argument; working code that carries a file between two buildings
is not.

It was **free to copy**. It arrived inside an operating system that universities already had, with
a programming interface — sockets, which you met in lesson two — that anybody could write against
in an afternoon.

It **specified less**. Where the seven-layer model tried to say how everything should work, this
one described the middle and let both ends be somebody else's problem. Less to agree about is less
to argue about, and standards die in arguments.

And it **already had the waist**. One internet layer, mandatory, in the middle; everything above
and below negotiable. That is not a happy accident of the design, it is the design.

## The transport layer has two doors

The layer you will make an actual choice about is transport, because there are two protocols
there and they promise different things.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"The transport layer drawn as one box with two doors. Through the left door, TCP, which numbers and retries and delivers in order. Through the right door, UDP, which sends and stops.\"> <rect x=\"150\" y=\"24\" width=\"420\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\"></rect> <text x=\"360\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">your program has something to send</text> <path d=\"M280 68 L212 104\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path> <path d=\"M440 68 L508 104\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path> <rect x=\"40\" y=\"110\" width=\"300\" height=\"128\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".14\" stroke=\"var(--phosphor)\"></rect> <text x=\"190\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">TCP</text> <text x=\"190\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">agrees to talk first</text> <text x=\"190\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">numbers every piece</text> <text x=\"190\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">asks again for what was lost</text> <text x=\"190\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">hands over in order</text> <rect x=\"380\" y=\"110\" width=\"300\" height=\"128\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".14\" stroke=\"var(--amber)\"></rect> <text x=\"530\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\">UDP</text> <text x=\"530\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">no agreement</text> <text x=\"530\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">no numbering</text> <text x=\"530\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">no second attempt</text> <text x=\"530\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">whatever order it lands in</text> <text x=\"190\" y=\"262\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">a page, a file, an email</text> <text x=\"530\" y=\"262\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">a lookup, a call, a live stream</text> <text x=\"360\" y=\"284\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">one layer, two promises — you pick by what a late arrival is worth to you</text> </svg>", "caption": "Both leave by the same layer. The difference is what each is willing to promise about what happens next."}
```

**TCP** sets up a connection first, numbers what it sends, notices what did not arrive, asks for
it again, and hands the far side a stream in the right order. Everything you have loaded in a
browser today came this way. What you pay is time — a handshake before any content moves — and
waiting, because a stream in order means a missing piece holds up the pieces behind it.

**UDP** sends the message and stops. No connection, no numbering, no retry, no order. What arrives
arrives; what is lost is lost, and nothing tells you.

That sounds strictly worse until you find the cases where it is not. A DNS lookup is one small
question and one small answer: setting up a connection would cost more than sending the question
twice if the first went missing. A voice call is worse off with TCP than without it — a syllable
that arrives late is useless, and stopping the call to wait for it turns a click into a freeze.
For anything live, *late* and *lost* are the same thing, and there is no point paying to turn one
into the other.

## Where does HTTPS live?

Reasonably asked, and the honest answer is that it does not fit.

TLS — the part that makes HTTP into HTTPS — sits above transport and below the application. It
takes a stream from TCP and gives the application back a stream that is encrypted and checked. It
is not one of the four, it does not have a number in the seven, and people who need a number
anyway say *layer 6*, or *layer 4.5* with a shrug.

This is the moment to notice something about models generally. They are maps, and a map that
disagrees with the ground is wrong about the map. TLS is running on almost every connection you
make, so a model with no room for it has a gap; the model is still useful, and the gap is still
there. Knowing which parts of a model are load-bearing and which are tidy is most of what it means
to know the model at all.

## What is running on your machine

At this moment, for the page in front of you, the stack is roughly this, top to bottom: the site's
own protocol above HTTP, above TLS, above TCP, above IP, above whatever is carrying it into the
building.

Every one of those is replaceable without the others being told, and the next section shows the
mechanism that makes the replacement possible: each layer wraps what it was given, rather than
rewriting it.
