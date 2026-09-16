---
title: How big a piece may be
version: 1
---

A cable will not carry a frame of any size. Every link has a ceiling on how much can travel in one
go, and that ceiling is called the **MTU** — the maximum transmission unit.

On ordinary Ethernet it is **1500 bytes**. Not a round number, and not a law of physics: it is a
figure chosen in the 1970s, balancing the cost of the label against how much you lose when one
frame is corrupted. It has outlived every reason it was picked for by being what everything else
already expects.

## Why a ceiling exists at all

Suppose there were none, and a machine could put a ten-megabyte frame on a shared cable.

Two things go wrong. The first is that while that frame is being transmitted, **nobody else can
use the line**. Every other machine waits for it, and a short, urgent frame — a keystroke, a voice
sample — waits behind ten megabytes of somebody's file. The line stops being shared in any useful
sense.

The second is that a frame is verified as a whole. If a single bit is corrupted, the entire frame
is discarded. At 1500 bytes, a corruption costs 1500 bytes. At ten megabytes it costs ten
megabytes, and on a link with any error rate at all you would spend your life re-sending enormous
frames that almost made it.

So: a ceiling, low enough that the line is shared fairly and a loss is cheap.

## What happens when a packet is too big

Now the interesting case. A packet is travelling along, and it arrives at a router whose next link
has a **smaller** MTU than the one it came in on.

There are exactly two things the router can do.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 268\" role=\"img\" aria-label=\"A 4000-byte packet meeting a link with an MTU of 1500. Above, it is cut into three fragments of 1480, 1480 and 1040 bytes. Below, the alternative: it is refused and a message is sent back to the sender saying the packet was too big.\"><rect x=\"14\" y=\"20\" width=\"200\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".16\" stroke=\"var(--phosphor)\"></rect><text x=\"114\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">one packet — 4000 bytes</text><rect x=\"258\" y=\"14\" width=\"92\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"304\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">next link</text><text x=\"304\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">MTU 1500</text><path d=\"M214 40 L254 40\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><rect x=\"380\" y=\"14\" width=\"326\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><rect x=\"392\" y=\"26\" width=\"110\" height=\"28\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect><text x=\"447\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1480</text><rect x=\"508\" y=\"26\" width=\"110\" height=\"28\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect><text x=\"563\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1480</text><rect x=\"624\" y=\"26\" width=\"70\" height=\"28\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect><text x=\"659\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1040</text><text x=\"543\" y=\"84\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--phosphor)\">CUT IT UP — three fragments, reassembled only at the end</text><text x=\"543\" y=\"104\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">lose any one of them and all three were wasted</text><rect x=\"14\" y=\"152\" width=\"200\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".16\" stroke=\"var(--phosphor)\"></rect><text x=\"114\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">one packet — 4000 bytes</text><text x=\"114\" y=\"206\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">marked \"do not fragment\"</text><rect x=\"258\" y=\"146\" width=\"92\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"304\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">next link</text><text x=\"304\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">MTU 1500</text><path d=\"M214 172 L254 172\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M254 192 C 200 226, 160 226, 118 200\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path><rect x=\"380\" y=\"146\" width=\"326\" height=\"52\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".1\" stroke=\"var(--amber)\"></rect><text x=\"543\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">refused, and a message goes BACK to the sender:</text><text x=\"543\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">too big — the most I take is 1500</text><text x=\"543\" y=\"222\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--amber)\">SEND IT BACK — and the sender is expected to try smaller</text><text x=\"543\" y=\"242\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">which works only if that message actually arrives</text></svg>", "caption": "Two ways to handle a packet that will not fit. The second is the one modern networks use, and the one that fails silently."}
```

**Cut it up.** The router splits the packet into fragments, each small enough to fit, each with its
own header carrying enough information to say where it belongs. They travel independently and are
**reassembled at the final destination** — not at the next router, and not anywhere in between.

That last detail is what makes fragmentation unattractive. Nothing along the way puts the packet
back together, so every fragment carries its own risk of being lost, and losing any one of them
wastes all of them. A 4000-byte packet cut into three has three chances to fail instead of one.

**Refuse it.** The sender can mark a packet *do not fragment*, and then a router that cannot pass
it must throw it away and send a message back: *too big, and the most I will take is this many
bytes.* The sender is expected to receive that, make its packets smaller, and try again.

This second arrangement is what modern networks use, and it works well — right up until the
message does not arrive.

## The fault that looks like nothing else

Here is a shape you will eventually meet in real life, so it is worth being able to recognise it.

Somebody connects to a VPN, or brings up a particular kind of tunnel, and reports that *the
internet is broken* — except it is not, quite. Small things work perfectly. Logging in works.
Short pages load. Then one page hangs, forever, with nothing on the screen.

The pattern is the giveaway, and it is always the same: **small requests succeed and large
transfers hang.**

What is happening is this. The tunnel wraps every packet in some extra header of its own, which
means the usable size inside it is smaller — perhaps 1420 bytes instead of 1500. Small packets fit
regardless. A large one does not, so a router marks it too big and sends the message back.

And somewhere in between, a firewall configured by somebody who decided those messages looked like
suspicious traffic is **discarding them**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 214\" role=\"img\" aria-label=\"A sender, a router that refuses a too-big packet, and a firewall between them dropping the router's too-big message so the sender never learns. The sender is shown waiting and retransmitting the same oversized packet.\"><rect x=\"12\" y=\"70\" width=\"116\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"70\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the sender</text><text x=\"70\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">still trying</text><rect x=\"294\" y=\"70\" width=\"116\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"352\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a firewall</text><text x=\"352\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">drops the warning</text><rect x=\"576\" y=\"70\" width=\"132\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"642\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">a router</text><text x=\"642\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">MTU 1420 ahead</text><path d=\"M128 84 L290 84 M414 84 L572 84\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><text x=\"350\" y=\"52\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">a 1500-byte packet, over and over</text><path d=\"M572 112 L416 112\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"494\" y=\"130\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">\"too big, take 1420\"</text><text x=\"352\" y=\"146\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"18\" fill=\"var(--amber)\">×</text><text x=\"360\" y=\"180\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">the sender is never told, so it never gets smaller</text><text x=\"360\" y=\"202\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">small requests work perfectly — large ones hang for ever</text></svg>", "caption": "A black hole: the packet cannot pass, the warning cannot return, and the sender has no way to learn either fact."}
```

So the sender never learns. It waits, assumes the packet was simply lost, and sends **the same
oversized packet again** — which is refused again, and warned about again, and the warning is
dropped again. The connection hangs indefinitely while every small thing on the same machine
continues to work.

This has a name, *black hole*, and it is worth carrying out of this lesson for one reason: it is
the clearest example in the whole course of a failure caused by a **message that was supposed to
come back and did not**. Almost everything else you will diagnose is something that failed to go
out.

## Finding the size without being told

Because that failure is common, senders do not simply trust the warnings. Most modern systems
**probe**: they send packets of varying sizes and watch which ones get through, deducing the
largest that survives without needing anybody to tell them.

It is slower than being told, and it works when the telling is broken — which, given the section
above, is a reasonable thing to design for.

## One number worth remembering

The most useful thing to carry away is the shape of the arithmetic, because it is what the
questions at the end of this lesson will ask you to do.

Of an Ethernet link's 1500 bytes, about 20 are the packet's own header. So roughly **1480 bytes of
your data** fit in one packet — and if TCP is in use, another 20 or so go to its header, leaving
around **1460**.

Which is why a 4000-byte message is three packets and not two, and why the third one is mostly
empty. Cutting anything into fixed sizes leaves a remainder, and the remainder costs a whole
packet's worth of label.

## Where this leaves you

There is a ceiling on how much travels in one go, it is 1500 bytes on ordinary Ethernet, and a
packet that will not fit is either cut up — which multiplies the risk — or refused with a message
back to the sender, which works unless somebody is discarding those messages.

The packet now has a size, a route and an envelope for each hop. What it still has no way of
saying is **which program on the destination machine it is for** — and that is the next section.
