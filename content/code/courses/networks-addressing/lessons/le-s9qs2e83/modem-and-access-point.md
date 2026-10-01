---
title: "Modem and access point: where the cable stops"
version: 1
---

The other devices in this lesson move frames between cables of the same kind. These two sit at the
edge, where Ethernet meets a medium that is not Ethernet: the provider's line on one side of the
building, the radio on the other. **Neither of them was run in this lab**, which has no telephone
line, no coaxial cable and no radio, so this section describes them and shows no output.

## The modem

The word is short for *modulator-demodulator*. **A modem turns the signal the provider's line
carries into frames a computer can use, and back.** The line is whatever reached the building: a
telephone pair for DSL, a coaxial cable from a cable-TV network, or a fibre. Each has its own way of
putting bits on the medium and its own rules for sharing it with the neighbours, and the modem is
the device that speaks them; on its other side it offers an ordinary Ethernet port. On fibre the
same job is done by an optical terminal, which providers call an ONT and customers still call the
modem.

So a modem lives at layer 1, plus whatever link layer the provider's technology uses on the line.
It reads no IP address. When the line drops, the modem's own lights say so before any computer
does, which is why the first question on a support call about a home connection is what those
lights show.

## The access point

**An access point is a bridge between radio and cable.** Phones and laptops send it Wi-Fi frames,
which carry MAC addresses like Ethernet ones, and it passes them on to the wired network, and
passes the wired network's frames back over the air. It works at layers 1 and 2: the radio, and
the frames on it. An access point does not route and does not give out addresses; the router and
the DHCP server behind it do that, and lesson 10 is about the second.

Two facts about radio change how access points are used:

- **Every station on one channel shares the same air**, the way the machines on a hub share one
  cable. Only one of them can transmit at a time, so a single access point with forty phones on it
  is slow for all forty.
- **Coverage is a matter of distance and walls.** A building is covered by several access points
  on the same wired network, each on its own channel and all announcing the same network name, and
  a phone moves from one to the next as its owner walks.

## The box on the shelf

The equipment a provider installs in a home is all of this in one case:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"The box a provider installs in a home, opened up. Inside one case are four devices. The provider's line enters a modem, which turns the line signal into Ethernet. The modem feeds a router doing NAT, which gives the home one public address. The router feeds a switch with a few Ethernet ports for cabled PCs, and an access point that turns radio into Ethernet for Wi-Fi devices.\"><defs><marker id=\"l1-home-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"150\" y=\"30\" width=\"452\" height=\"205\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"162\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">one case, four devices</text><rect x=\"162\" y=\"108\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"172\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">modem</text><text x=\"172\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">line to Ethernet</text><rect x=\"300\" y=\"108\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"310\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">router + NAT</text><text x=\"310\" y=\"142\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one public address</text><rect x=\"438\" y=\"60\" width=\"150\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"448\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">switch</text><text x=\"448\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a few Ethernet ports</text><rect x=\"438\" y=\"162\" width=\"150\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"448\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">access point</text><text x=\"448\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">radio to Ethernet</text><path d=\"M282 133 L300 133\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M420 125 L438 90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M420 141 L438 182\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"14\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">provider's line</text><text x=\"14\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fibre, cable, DSL</text><path d=\"M118 133 L162 133\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M588 85 L612 85\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"616\" y=\"85\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cabled PCs</text><path d=\"M588 187 L612 187\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"616\" y=\"187\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Wi-Fi devices</text></svg>", "caption": "What the home \"router\" is: four devices in one case. A business network keeps them apart."}
```

A modem towards the provider's line, a router that does NAT so the whole home shares one public
address, a small switch with a few ports on the back, and an access point. **What everybody calls
"the router" at home is four devices**, and that is why it is the one thing everybody restarts:
four jobs, one power plug.

A business network takes the box apart on purpose. The provider's equipment ends at its own modem
or terminal; the company's router and firewall come after it; the switches sit in a rack; and the
access points are spread across ceilings, each one fed by a single cable that carries its power
too, which is lesson 21. Separate devices can each be replaced, sized and placed where they work
best, and when one fails, the other three keep working.
