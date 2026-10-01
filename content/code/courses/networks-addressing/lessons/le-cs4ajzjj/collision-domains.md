---
title: "Collision domains: who has to take turns"
version: 1
---

"Collision" sounds like an accident that a good network avoids. On early Ethernet it was part of
the design. **A collision domain is the set of devices whose transmissions can collide: devices
sharing one medium, so that only one of them may send at a time.** The question this section
answers is how big that set is, and the answer depends entirely on what joins the devices.

## Sharing a wire

The first Ethernets were one coaxial cable running past every machine, and a hub, lesson 1, is
the same thing folded into a box. Every machine hears every signal, so if two start at once, both
frames are garbled. Ethernet's answer was **CSMA/CD** (*carrier sense, multiple access, collision
detection*):

1. listen, and send only when the medium is quiet;
2. keep listening while sending; if the signal on the wire is not your own, a collision happened;
3. stop, send a short jam signal so that everybody notices, and wait a random time before trying
   again, so the two senders do not collide a second time.

It works, and it gets worse the more machines share the medium: more of them waiting for quiet,
more collisions, more random waits. A link where a device can either send or receive but not both
at once is **half duplex**, and CSMA/CD is what a half-duplex Ethernet runs.

## One per port

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Two panels side by side. On the left, a hub: pc1, pc2, pc3 and srv cabled to it, all four cables inside one dashed outline labelled one collision domain, because a hub repeats every bit to every port and only one machine may send at a time. On the right, a switch with the same four machines, each cable inside its own dashed outline: four collision domains, one per port, and on a full-duplex link none of them ever collides.\"><defs><marker id=\"l18-coll-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"180\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">hub: layer 1</text><text x=\"540\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">switch: layer 2</text><rect x=\"16\" y=\"56\" width=\"328\" height=\"128\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"180\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">one collision domain</text><rect x=\"24\" y=\"66\" width=\"72\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"60\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><path d=\"M60 98 L60 184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"104\" y=\"66\" width=\"72\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"140\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc2</text><path d=\"M140 98 L140 184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"184\" y=\"66\" width=\"72\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"220\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc3</text><path d=\"M220 98 L220 184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"264\" y=\"66\" width=\"72\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"300\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">srv</text><path d=\"M300 98 L300 184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"24\" y=\"184\" width=\"312\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"180\" y=\"201\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">every bit, out of every port</text><text x=\"540\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">four collision domains, one per port</text><rect x=\"382\" y=\"56\" width=\"76\" height=\"128\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><rect x=\"384\" y=\"66\" width=\"72\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"420\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><path d=\"M420 98 L420 184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"462\" y=\"56\" width=\"76\" height=\"128\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><rect x=\"464\" y=\"66\" width=\"72\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"500\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc2</text><path d=\"M500 98 L500 184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"542\" y=\"56\" width=\"76\" height=\"128\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><rect x=\"544\" y=\"66\" width=\"72\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"580\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc3</text><path d=\"M580 98 L580 184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"622\" y=\"56\" width=\"76\" height=\"128\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><rect x=\"624\" y=\"66\" width=\"72\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"660\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">srv</text><path d=\"M660 98 L660 184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"384\" y=\"184\" width=\"312\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"540\" y=\"201\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">each frame, out of one port</text><text x=\"180\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">half duplex: one talker at a time</text><text x=\"540\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">full duplex: no collisions at all</text></svg>", "caption": "The same four machines on a hub and on a switch: who has to take turns."}
```

A switch changes the arithmetic. It receives each frame whole before sending it on, so a frame on
one port never meets a frame on another: **every port of a switch is its own collision domain**.
With one device per port, the only two things that could collide are the device and the switch
itself, and modern Ethernet removes even that. A twisted-pair cable has separate pairs for each
direction, so both ends can send at the same moment: that is **full duplex**, and on a full-duplex
link there is no shared medium, nothing to sense and nothing to collide. CSMA/CD is switched off.

pc1's card reports what it negotiated, and its counters say what happened:

```
ana@pc1:~$ sudo ethtool eth0 | grep -E "Speed|Duplex"
	Speed: 10000Mb/s
	Duplex: Full
ana@pc1:~$ ip -s link show eth0 | tail -2
    TX:  bytes packets errors dropped carrier collsns           
          1788      24      0       0       0       0 
```

`Duplex: Full`, and **`collsns` 0** after the traffic of this lesson's earlier blocks. `Speed: 10000Mb/s` needs a
warning: this is a virtual card, which carries no signal at all, and the number is simply what the
`veth` driver declares. A physical card reports the speed it agreed with the port at the other end.

## Where collisions still turn up

You will not see collisions on a healthy switched network, and that is exactly why seeing them is
informative. The usual cause is a **duplex mismatch**: one end of a link set to full duplex by
hand, the other left to negotiate and falling back to half. The half-duplex end sees the other
end transmitting while it sends, counts collisions, backs off and retransmits; the full-duplex end
sees damaged frames. The link works, slowly and badly, and **rising collision or error counters on
a switched link point at the two ends' settings**, not at the cable. Setting both ends the same
way, usually both to negotiate, is the repair.

The rest is history worth recognising in an exam or an old building: a hub, or a chain of hubs and
repeaters, is one collision domain however many ports it has; a bridge or a switch splits it at
every port.
