---
title: One message wearing four headers
version: 1
---

A layer has to add something — its port numbers, its addresses — and it is not allowed to
understand what it was handed. Those two facts leave exactly one move available: **put the thing
you were given inside something of your own, and write on the outside.**

That is encapsulation, and it is the whole mechanism. Nothing is rewritten on the way down. It is
wrapped, and wrapped again, and at the far end unwrapped in the opposite order.

## Four wraps, counted in bytes

Take a small request — the opening line and a couple of headers, about forty bytes of text.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Four strips, each wider than the one above. The top strip is forty bytes of request. Below it the same bytes with a twenty byte transport header in front, then with a twenty byte internet header in front of that, then with a fourteen byte link header in front and a four byte check at the end.\"> <text x=\"394\" y=\"26\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">what the application wrote</text> <rect x=\"394\" y=\"32\" width=\"278\" height=\"38\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect> <text x=\"533\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">GET / HTTP/1.1 ...</text> <text x=\"533\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">40 bytes</text> <text x=\"256\" y=\"94\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">a segment — 60 bytes</text> <rect x=\"256\" y=\"100\" width=\"138\" height=\"38\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".22\" stroke=\"var(--amber)\"></rect> <text x=\"325\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">TCP header</text> <text x=\"325\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">ports, 20 bytes</text> <rect x=\"394\" y=\"100\" width=\"278\" height=\"38\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".12\" stroke=\"var(--phosphor-dim)\"></rect> <text x=\"533\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">the 40 bytes, unopened</text> <text x=\"117\" y=\"162\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">a packet — 80 bytes</text> <rect x=\"117\" y=\"168\" width=\"139\" height=\"38\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".22\" stroke=\"var(--amber)\"></rect> <text x=\"186\" y=\"181\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">IP header</text> <text x=\"186\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">addresses, 20</text> <rect x=\"256\" y=\"168\" width=\"416\" height=\"38\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".12\" stroke=\"var(--phosphor-dim)\"></rect> <text x=\"464\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">the segment, unopened</text> <text x=\"20\" y=\"230\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">a frame — 98 bytes, and this is what goes on the wire</text> <rect x=\"20\" y=\"236\" width=\"97\" height=\"38\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".22\" stroke=\"var(--amber)\"></rect> <text x=\"68\" y=\"249\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">link, 14</text> <text x=\"68\" y=\"263\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">MACs</text> <rect x=\"117\" y=\"236\" width=\"555\" height=\"38\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".12\" stroke=\"var(--phosphor-dim)\"></rect> <text x=\"394\" y=\"255\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">the packet, unopened</text> <rect x=\"672\" y=\"236\" width=\"28\" height=\"38\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".22\" stroke=\"var(--amber)\"></rect> <text x=\"360\" y=\"292\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">the sliver at the far right is the link layer's check, the only part added behind you</text> </svg>", "caption": "Nothing is rewritten going down. Each layer puts what it was handed inside something of its own."}
```

The application hands down forty bytes and stops.

Transport puts a header of its own in front: which port this came from, which port it is for,
where this piece sits in the stream, and a checksum. Twenty bytes at its smallest. What it hands
down is sixty bytes, and it does not distinguish between its header and your text — it just knows
the total.

The internet layer does the same: twenty more bytes in front, carrying the source address, the
destination address, and a hop count. It is handed sixty bytes, it passes down eighty, and it has
no opinion about what the first twenty of those sixty were.

The link layer wraps it once more, with the two MAC addresses, and adds a check at the **end** as
well — the only one of the four to put anything behind you. Ninety-eight bytes go onto the wire,
forty of which you wrote.

Each layer's product has its own name, and the names are worth knowing because error messages use
them: what transport produces is a **segment**, what the internet layer produces is a **packet**,
what goes on the wire is a **frame**. Same bytes, three names, depending on which envelope you
are counting from.

## Every header is addressed to its opposite number

Here is the idea that makes the rest fall into place.

A header is not written for the layer below, and it is not written for the machines in between. It
is written for **the same layer at the other end**. The transport header is a note from your
machine's transport layer to the server's transport layer. The layers below carry it without
reading it, exactly as the post office carries a letter without reading it.

So there are two kinds of movement in this picture, and confusing them is the usual beginner's
knot. **Vertically**, within one machine, layers hand bundles up and down — that is plumbing.
**Horizontally**, each layer holds a conversation with its counterpart across the world, using a
header nothing in between opens. The horizontal conversation is the real one. The vertical
movement exists to make it possible.

## What survives a hop, and what does not

Between you and a server there are perhaps fifteen routers, and the envelopes do not all survive
the trip.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" aria-label=\"The same message at three points of its journey. The link header is different every time, the internet header keeps its addresses and only its hop count falls, and the transport header and the content are identical throughout.\"> <text x=\"20\" y=\"30\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">leaving your laptop</text> <rect x=\"20\" y=\"38\" width=\"150\" height=\"44\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".24\" stroke=\"var(--amber)\"></rect> <text x=\"95\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">link header</text> <text x=\"95\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">to your router</text> <rect x=\"170\" y=\"38\" width=\"160\" height=\"44\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"250\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">IP header</text> <text x=\"250\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">hops left 64</text> <rect x=\"330\" y=\"38\" width=\"160\" height=\"44\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"410\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">TCP header</text> <rect x=\"490\" y=\"38\" width=\"210\" height=\"44\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"595\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">your request</text> <text x=\"20\" y=\"122\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">leaving your router, on a different wire</text> <rect x=\"20\" y=\"130\" width=\"150\" height=\"44\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".24\" stroke=\"var(--amber)\"></rect> <text x=\"95\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">thrown away, rebuilt</text> <text x=\"95\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">to the next router</text> <rect x=\"170\" y=\"130\" width=\"160\" height=\"44\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"250\" y=\"145\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">same addresses</text> <text x=\"250\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">hops left 63</text> <rect x=\"330\" y=\"130\" width=\"160\" height=\"44\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"410\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">not opened</text> <rect x=\"490\" y=\"130\" width=\"210\" height=\"44\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"595\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">not opened</text> <text x=\"20\" y=\"214\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">arriving at the server, thirteen hops later</text> <rect x=\"20\" y=\"222\" width=\"150\" height=\"44\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".24\" stroke=\"var(--amber)\"></rect> <text x=\"95\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">built for the last time</text> <text x=\"95\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">to the server card</text> <rect x=\"170\" y=\"222\" width=\"160\" height=\"44\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"250\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">same addresses</text> <text x=\"250\" y=\"253\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">hops left 50</text> <rect x=\"330\" y=\"222\" width=\"160\" height=\"44\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"410\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">opened at last</text> <rect x=\"490\" y=\"222\" width=\"210\" height=\"44\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"595\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">identical to what was sent</text> <text x=\"360\" y=\"296\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">the left-hand column is new at every hop; everything to the right of it is carried, not read</text> </svg>", "caption": "Fourteen frames were built and destroyed to move one message. The message itself was never touched."}
```

The **frame** is destroyed and rebuilt at every single hop. It was only ever addressed to the next
card on this wire, and once the packet has crossed that wire it is finished. The router strips it,
reads the packet, and builds a completely new frame for the next wire — new MAC addresses, and
possibly a different technology entirely, since the frame that arrived over Wi-Fi may leave over
fibre.

The **packet** survives, almost. Its addresses are the whole point and are not touched. One field
does change at every hop: a hop count that starts somewhere near 64 and drops by one each time,
so that a packet caught in a loop dies instead of circling for ever. When you run a trace and see
a list of routers, that countdown is the trick being used to produce it.

The **segment** and your bytes are not opened by anything along the way. Except by NAT, which
opens the segment to rewrite a port — and now you can say exactly what is wrong with that: it is
a device at the internet layer reading a header addressed to somebody else.

## The unwrapping

At the server it runs in reverse, and each layer asks one question before going further up.

The card checks the frame's destination MAC — *is this for me?* — and its trailing checksum: a
frame that was damaged in transit is discarded here, silently, and the layers above never learn it
existed. The internet layer checks the destination address — *is this for me?* — and looks at one
byte of its header that says what is inside, so it knows to pass the contents to TCP rather than
to something else. Transport checks the destination port — *which program?* — puts the pieces back
in order, and hands the program a stream.

The program receives the same forty bytes that were sent. Four wraps, four unwraps, fifteen frames
built and destroyed, and the text arrives unchanged, having been understood by nothing in between.

That is the payoff the first section promised, and it is entirely mechanical: a layer cannot
corrupt what it refuses to open.
