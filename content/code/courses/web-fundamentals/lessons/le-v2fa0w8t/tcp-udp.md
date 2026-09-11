---
title: Two ways to use the same packets
version: 1
---

Everything so far has been about the network's promise, which is *best effort*: I will try, I may
lose it, I may deliver it late, I may deliver it after the one behind it, and I will not tell you.

A file transfer cannot live with that. A voice call cannot live without it.

So there are two answers, they run over exactly the same packets, and choosing between them is one
of the few genuinely load-bearing decisions in building anything networked.

## What TCP adds

**TCP** takes the network's best effort and builds a **reliable, ordered stream** on top of it.
Every mechanism it uses is a repair for one specific thing on that list.

Packets can arrive out of order, so TCP **numbers** them — not packets, actually, but bytes: every
byte of the stream has a position, and the receiver puts them back in order by number before
handing anything to the program.

Packets can be lost, so the receiver **acknowledges** what it got. The sender keeps a copy of
everything it has sent until an acknowledgement comes back, and if one does not arrive in time, it
**sends that data again**.

The receiver can be overwhelmed, so it advertises how much room it has left. The sender is not
allowed to send more than that, which is why a fast machine talking to a slow one does not simply
bury it.

And the network itself can be congested, so TCP watches for loss — loss being the only signal the
network gives — and **slows down** when it sees it. That is the part nobody asked for and everyone
benefits from: it is the reason a hundred simultaneous downloads share a link instead of
destroying it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 258\" role=\"img\" aria-label=\"Two timelines of the same five packets with the third one lost. In the TCP timeline the receiver holds packets four and five, the sender resends the third, and the program receives all five in order. In the UDP timeline packets four and five are handed straight to the program and the third is simply never mentioned.\"><rect x=\"8\" y=\"14\" width=\"344\" height=\"230\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"180\" y=\"36\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">TCP</text><rect x=\"26\" y=\"56\" width=\"44\" height=\"26\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect><text x=\"48\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1</text><rect x=\"78\" y=\"56\" width=\"44\" height=\"26\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect><text x=\"100\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2</text><rect x=\"130\" y=\"56\" width=\"44\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-dasharray=\"3 3\"></rect><text x=\"152\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">3</text><rect x=\"182\" y=\"56\" width=\"44\" height=\"26\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect><text x=\"204\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4</text><rect x=\"234\" y=\"56\" width=\"44\" height=\"26\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect><text x=\"256\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">5</text><text x=\"152\" y=\"98\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">3 is lost</text><text x=\"180\" y=\"126\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">4 and 5 arrived and are HELD</text><text x=\"180\" y=\"146\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">no acknowledgement for 3 — resend it</text><rect x=\"96\" y=\"162\" width=\"168\" height=\"26\" rx=\"2\" fill=\"var(--phosphor)\" fill-opacity=\".2\" stroke=\"var(--phosphor)\"></rect><text x=\"180\" y=\"175\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3 again, and it lands</text><text x=\"180\" y=\"210\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">the program gets 1 2 3 4 5</text><text x=\"180\" y=\"230\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">complete, in order, and late</text><rect x=\"368\" y=\"14\" width=\"344\" height=\"230\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"540\" y=\"36\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">UDP</text><rect x=\"386\" y=\"56\" width=\"44\" height=\"26\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect><text x=\"408\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1</text><rect x=\"438\" y=\"56\" width=\"44\" height=\"26\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect><text x=\"460\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2</text><rect x=\"490\" y=\"56\" width=\"44\" height=\"26\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-dasharray=\"3 3\"></rect><text x=\"512\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><rect x=\"542\" y=\"56\" width=\"44\" height=\"26\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect><text x=\"564\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4</text><rect x=\"594\" y=\"56\" width=\"44\" height=\"26\" rx=\"2\" fill=\"var(--amber)\" fill-opacity=\".2\" stroke=\"var(--amber)\"></rect><text x=\"616\" y=\"69\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">5</text><text x=\"512\" y=\"98\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">3 is lost</text><text x=\"540\" y=\"126\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">4 and 5 go STRAIGHT to the program</text><text x=\"540\" y=\"146\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nothing waits, nothing is resent</text><text x=\"540\" y=\"176\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nobody ever mentions 3 again</text><text x=\"540\" y=\"210\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">the program gets 1 2 4 5</text><text x=\"540\" y=\"230\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">incomplete, in order, and on time</text></svg>", "caption": "The same loss, handled two ways. Notice that neither column is the mistake — they are answers to different questions."}
```

## What UDP adds

Almost nothing, and that is the feature.

**UDP** puts a port number on a packet and sends it. There is no numbering, no acknowledgement, no
retransmission, no reordering, no flow control and no slowing down. If a packet is lost, it is
lost, and the program is not told.

Reading that as a deficiency is the natural mistake. It is a **choice**, and what it buys is
everything in the previous paragraph *not happening*: no waiting for a connection to be agreed, no
data held back, no delay while something is fetched again.

## The trade, said properly

The honest way to state it is that TCP converts loss into **delay**, and UDP converts loss into
**absence**.

That is the whole thing. Neither is better, and which one is right depends on a single question:
**is your data still useful late?**

For a file, yes — obviously. A file with a missing kilobyte is not a slightly worse file, it is a
corrupt one, and a file that takes half a second longer is fine. Convert loss into delay.

For a voice call, no. The twenty milliseconds of somebody's speech that went missing were due on
the listener's ear twenty milliseconds ago. Delivering them now is worse than useless — it would
have to be inserted somewhere, and there is nowhere. Far better to carry on and let the listener's
brain paper over a gap it barely notices. Convert loss into absence.

## Head-of-line blocking

There is a specific cost to TCP's ordering worth naming, because it has a name and you will meet
it again in lesson 6.

TCP delivers **in order**. If packet 3 is lost, packets 4 and 5 may have arrived perfectly well —
but the program is not given them. It cannot be: they come after 3 in the stream, and handing them
over would deliver the data out of order, which is the one thing TCP exists to prevent.

So 4 and 5 sit in memory, complete and unusable, while 3 is fetched again.

That is **head-of-line blocking**: one missing piece holding up everything behind it. On a good
link it is invisible. On a bad one it is the difference between a page that loads slowly and a
page that appears to freeze and then arrive all at once.

## Where each one actually is

| what | which | why |
|---|---|---|
| web pages, APIs | TCP | a page missing a fragment is broken, not slower |
| e-mail, file transfer | TCP | every byte matters and nothing is urgent |
| DNS lookups | UDP | one small question, one small answer — asking again is cheaper than agreeing first |
| voice and video calls | UDP | late audio is useless audio |
| live game state | UDP | the next position replaces the one that was lost |
| video streaming | TCP, mostly | it is not live, so there is a buffer, and a buffer converts delay into nothing at all |
| HTTP/3 | UDP, with its own machinery on top | see below |

That last row is the one that stops the table being a tidy rule.

## When the answer is neither

HTTP/3 — which a large share of the web now runs on — is built on **UDP**, and it is not because
anybody stopped wanting reliability.

It is because of head-of-line blocking. A browser fetches many things at once, and over one TCP
connection a single lost packet stalls *all* of them, including the ones that had nothing to do
with it. So HTTP/3 takes UDP, which imposes no ordering, and rebuilds numbering, acknowledgement
and retransmission **per stream** rather than for the connection as a whole. One stalled download
no longer holds up the other nine.

The reason it is worth knowing at this level is the shape of the move rather than the detail.
*Reliable* and *unreliable* are not two boxes to be sorted into. UDP is a floor — a port number
and nothing else — and anybody who needs something other than exactly what TCP provides can build
it there. Lesson 6 returns to this when it compares HTTP versions.

## Where this leaves you

Two ways of using the same packets. TCP numbers, acknowledges, resends, reorders, and slows down
when the network is struggling — turning loss into delay, at the cost of a round trip before
anything starts and of one lost packet holding up what is behind it. UDP adds a port and nothing
else, turning loss into absence.

The round trip is the part worth seeing rather than reading about, so that is what the next
section does: the same connection, opened on a clock, beside the same data sent with no agreement
at all.
