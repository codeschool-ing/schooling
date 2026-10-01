---
title: A loop has no way out
version: 1
---

The instinct is sound and the result is not. A second cable between two switches looks like
insurance: if one cable fails, the other is still there. **On a switched network, a second path
with nothing to manage it is a fault that takes the whole segment down within seconds**, with
every cable plugged in and every light green.

Two facts from earlier lessons are enough to explain it. A switch floods a broadcast out of every
port except the one it arrived on (lesson 18), and so does any frame for a MAC address it has not
learnt yet. And **an Ethernet frame carries no hop count**. An IP packet has a TTL that every router
lowers by one, the field `traceroute` plays with in the networks course, so a packet caught in a
routing loop dies after at most 255 hops. A switch rewrites nothing in the frame it forwards, so a frame going round a ring of
switches never gets older.

## The lab: three switches in a triangle

The lab for this lesson is three switches, `sw1`, `sw2` and `sw3`, each a Linux bridge, cabled to
each other in a triangle, with one PC on port `p10` of each. Spanning tree is switched off, and the
lab starts with the cable between `sw3` and `sw1` unplugged:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Three switches cabled in a triangle with spanning tree off: sw1 at the top, with pc1 on its port p10; sw2 at the bottom left and sw3 at the bottom right, with pc2 and pc3 on their ports p10. sw1 p2 is cabled to sw2 p1, sw2 p3 to sw3 p2, and sw3 p1 to sw1 p3, the cable plugged in for three seconds. Two copies of one broadcast go round the triangle, one clockwise and one the other way, and neither ever stops. In those three seconds p2 on sw1 received 201,975 frames.\"><defs><marker id=\"stl-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"stl-p\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><path d=\"M360 40 L360 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M170 254 L170 282\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M550 254 L550 282\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M320 114 L210 210\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M400 114 L510 210\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M230 232 L490 232\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"298\" y=\"126\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p2</text><text x=\"422\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p3</text><text x=\"214\" y=\"194\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p1</text><text x=\"506\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p1</text><text x=\"238\" y=\"221\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p3</text><text x=\"482\" y=\"221\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p2</text><text x=\"368\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p10</text><text x=\"178\" y=\"268\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p10</text><text x=\"558\" y=\"268\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">p10</text><rect x=\"320\" y=\"10\" width=\"80\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"25.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><rect x=\"130\" y=\"282\" width=\"80\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"170.0\" y=\"297.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc2</text><rect x=\"510\" y=\"282\" width=\"80\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"550.0\" y=\"297.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc3</text><rect x=\"300\" y=\"70\" width=\"120\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sw1</text><rect x=\"110\" y=\"210\" width=\"120\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"170.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sw2</text><rect x=\"490\" y=\"210\" width=\"120\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"550.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sw3</text><path d=\"M425.1 151.8 L469.1 190.2\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" marker-end=\"url(#stl-a)\"></path><path d=\"M412.0 220.0 L308.0 220.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" marker-end=\"url(#stl-a)\"></path><path d=\"M250.9 190.2 L294.9 151.8\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" marker-end=\"url(#stl-a)\"></path><path d=\"M484.9 172.2 L440.9 133.8\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" marker-end=\"url(#stl-p)\"></path><path d=\"M308.0 244.0 L412.0 244.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" marker-end=\"url(#stl-p)\"></path><path d=\"M279.1 133.8 L235.1 172.2\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" marker-end=\"url(#stl-p)\"></path><path d=\"M14 22 L44 22\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" marker-end=\"url(#stl-a)\"></path><text x=\"52\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">one copy, flooded clockwise</text><path d=\"M14 44 L44 44\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" marker-end=\"url(#stl-p)\"></path><text x=\"52\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">another copy, the other way round</text><text x=\"486\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">plugged in for three seconds</text><text x=\"706\" y=\"22\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">p2 on sw1 received</text><text x=\"706\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">201,975 frames in those seconds</text></svg>", "caption": "The loop the lab closed for three seconds. A switch floods a broadcast out of every port but the one it came in on, so each copy is sent on round the triangle, in both directions, and nothing in an Ethernet frame runs out."}
```

On `sw1`, that cable is the one on `p3`:

```
root@sw1:~# bridge link show
462: p2@if461: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
465: p3@if466: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 master br0 state disabled priority 32 cost 2 
467: p10@if468: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 master br0 state forwarding priority 32 cost 2 
root@sw1:~# ip -s link show p2 | sed -n "3,6p"
    RX:  bytes packets errors dropped  missed   mcast           
          1766      21      0       0       0       0 
    TX:  bytes packets errors dropped carrier collsns           
          1188      14      0       0       0       0 
```

`NO-CARRIER` and `state disabled` are the unplugged cable. The counters on `p2`, the cable to `sw2`,
say that since the lab came up that port has received 21 frames and sent 14. A quiet network.

Then the missing cable was plugged in, and three seconds later it was pulled out again. Nobody
typed anything in between. The same counters afterwards:

```
root@sw1:~# ip -s link show p2 | sed -n "3,6p"
    RX:  bytes packets errors dropped  missed   mcast           
      15019266  201975      0       0       0       0 
    TX:  bytes packets errors dropped carrier collsns           
      16857698  219701      0       0       0       0 
```

**From 21 frames received to 201,975, and from 14 sent to 219,701, in about three seconds on one
port.** No program sent them. Whatever broadcast or multicast frame was on the wire when the
triangle closed was flooded by each switch to the other two, which flooded it on, and it came back
to the switch it started from, which flooded it again. It goes round in both directions at once,
because a flood leaves by every port, and every lap adds copies.

## What a loop does to a network

That is a **broadcast storm**, and in this lab it stopped only because the cable was pulled. On real
switches it fills every link in the loop to its full speed and keeps it there, and every device on
the segment has to receive every broadcast in the storm. PCs slow down, switches spend their
processor on flooding, and the management interface you would use to fix it stops answering.

The storm also wrecks the MAC table. A switch learns a MAC address from the port a frame arrives on
(lesson 18). When copies of the same frame arrive on `p2` and then on `p3`, `sw1` moves the sender's
address from one port to the other, over and over. That is called **MAC flapping**, and frames for
that address go out of whichever port won last, which may well be the wrong one.

And none of it ends by itself: no field in the frame runs out. The fix has to be a protocol that
lets switches discover the loop and switch off just enough ports to break it. That protocol is the
rest of this lesson.
