---
title: A MAC address is an assertion
version: 1
---

**The address on a frame is written by the device that sends it.** The last section changed
`desk`'s address with one command, as root, on its own machine, and the switch believed whatever it
was told. A MAC filter checks a claim, not an identity. Any device whose owner knows an address on
the list can use that address, and the list cannot tell it from the device the address belongs to.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l04-assertion\" aria-label=\"Why a MAC filter believes whatever it is told. Two frames arrive at port-desk. The first comes from the reception printer and carries its address, 52:54:00:a8:3c:63. The second comes from desk after desk set its own card to the same address. The port compares the source address with its list, finds it in both cases and lets both through: the address is written by the device that sends the frame.\"><defs><marker id=\"l04-assertion-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"160.0\" height=\"70.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"100.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the printer</text><text x=\"100.0\" y=\"86.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">its own address</text><rect x=\"220.0\" y=\"55.0\" width=\"210.0\" height=\"40.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"232.0\" y=\"69.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">source</text><text x=\"232.0\" y=\"84.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">52:54:00:a8:3c:63</text><path d=\"M180.0 75.0 L220.0 75.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-assertion-dh-ah-paper-dim)\"></path><path d=\"M430.0 75.0 L490.0 125.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-assertion-dh-ah-paper-dim)\"></path><rect x=\"20.0\" y=\"140.0\" width=\"160.0\" height=\"70.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"100.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">desk</text><text x=\"100.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">address set by its owner</text><rect x=\"220.0\" y=\"155.0\" width=\"210.0\" height=\"40.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"232.0\" y=\"169.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">source</text><text x=\"232.0\" y=\"184.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">52:54:00:a8:3c:63</text><path d=\"M180.0 175.0 L220.0 175.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-assertion-dh-ah-paper-dim)\"></path><path d=\"M430.0 175.0 L490.0 125.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-assertion-dh-ah-paper-dim)\"></path><rect x=\"490.0\" y=\"85.0\" width=\"210.0\" height=\"80.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"595.0\" y=\"105.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">port-desk</text><text x=\"595.0\" y=\"127.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">is the source on the list?</text><text x=\"595.0\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">yes, both times</text></svg>", "caption": "The filter checks a value the device writes itself."}
```

The address that passed was the printer's, and that is the usual weak point. Printers, badge readers,
cameras and phones are the devices whose addresses end up on lists, because they cannot run anything
better. Their addresses are also printed on labels, shown on their own status pages and visible to
anything else on the segment, since every frame they send carries them.

So a MAC filter is a **convenience control**: it stops mistakes and leaves deliberate use of the
socket untouched. Treat it as one, and do not put it alone between a public wall socket and the
portal.

## What the switch can notice

Switches can make the claim harder to exploit without a credential, and a defender should switch
these on where they exist:

- **an address seen on two ports**, or moving from one port to another while the first device is
  still up, which is what happens when something copies the printer's address while the printer
  is still plugged in elsewhere;
- **a port that changes address**, which sticky MAC turns into a shutdown of the port and an alert;
- **a device that behaves unlike its kind**: a "printer" that opens SSH connections to the portal,
  which a network monitor or the EDR of lesson 8 sees and a port filter does not.

None of these was run for this course; they are features of managed switches and monitoring
systems, configured through each vendor's own interface.

## MAC authentication bypass

Networks that use 802.1X, the subject of the rest of this lesson, still have devices that cannot
take part in it, and the printer is the classic one. The common answer is **MAC authentication
bypass** (MAB): if a port hears no 802.1X at all, the switch sends the device's MAC address to the
authentication server as though it were a username, and the server can let it in, usually into a
restricted network segment. MAB is the same assertion with a server behind it. It is safe only when
what the address gets is limited to what that kind of device needs: a printer segment that can reach
the print server and nothing else, so that a laptop pretending to be the printer gains nothing a
printer would not.
