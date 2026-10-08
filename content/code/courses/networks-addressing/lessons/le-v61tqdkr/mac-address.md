---
title: "The MAC address: six bytes and two bits"
version: 2
---

A MAC address looks like a serial number, and that is half right. **It is six bytes, written as
twelve hexadecimal digits in pairs, and its first byte carries two bits that change what the rest
means.** pc1's card from the network card section is `02:25:70:bc:29:c6`: six pairs, six bytes,
48 bits.

The usual description says that the first three bytes name the manufacturer and the last three
are the card's own number. For an address burnt into a card at the factory, that is how it works:
the IEEE sells each manufacturer a block called an **OUI** (*Organizationally Unique Identifier*),
the manufacturer numbers its cards inside the block, and the two halves together are meant to be
unique in the world. Plenty of tools will look up the first three bytes and print a maker's name.

Not every address works that way, and the lab's are the example. Every MAC in this course starts
with `02`. Look at that byte bit by bit:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 268\" role=\"img\" aria-label=\"The MAC address 02:25:70:bc:29:c6, pc1's, as six boxes of one byte each. The first three bytes, 02:25:70, are where a manufacturer's prefix, the OUI, would sit; the last three, bc:29:c6, are the card's own number. The first byte, 02, is opened into its eight bits: 0 0 0 0 0 0 1 0. The lowest bit, on the right, is the I/G bit, 0 here, meaning the frame is for one card; 1 would mean a group. The bit beside it is the U/L bit, 1 here, meaning the address was set locally rather than burnt in by a manufacturer.\"><defs><marker id=\"l2-mac-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"130\" y=\"40\" width=\"70\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"165\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">02</text><rect x=\"208\" y=\"40\" width=\"70\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"243\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">25</text><rect x=\"286\" y=\"40\" width=\"70\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"321\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">70</text><rect x=\"364\" y=\"40\" width=\"70\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"399\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">bc</text><rect x=\"442\" y=\"40\" width=\"70\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"477\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">29</text><rect x=\"520\" y=\"40\" width=\"70\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"555\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">c6</text><text x=\"243\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">first three bytes: the OUI</text><text x=\"477\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">last three: the card's number</text><path d=\"M130 74 L150 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M200 74 L560 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"150\" y=\"140\" width=\"46\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"173\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">0</text><rect x=\"202\" y=\"140\" width=\"46\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"225\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">0</text><rect x=\"254\" y=\"140\" width=\"46\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"277\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">0</text><rect x=\"306\" y=\"140\" width=\"46\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"329\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">0</text><rect x=\"358\" y=\"140\" width=\"46\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"381\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">0</text><rect x=\"410\" y=\"140\" width=\"46\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"433\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">0</text><rect x=\"462\" y=\"140\" width=\"46\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"485\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">1</text><rect x=\"514\" y=\"140\" width=\"46\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"537\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper)\">0</text><text x=\"140\" y=\"157\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">byte 02</text><path d=\"M537 174 L537 200 L590 200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M485 174 L485 238 L590 238\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"596\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">I/G = 0</text><text x=\"596\" y=\"208\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">one card, not a group</text><text x=\"596\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">U/L = 1</text><text x=\"596\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">set locally</text></svg>", "caption": "pc1's MAC address, and the two bits of its first byte that change its meaning."}
```

`02` is `00000010` in binary, and the two lowest bits are the ones that matter:

- **Bit 0, the I/G bit** (*individual/group*). 0 means the address belongs to one card; 1 means
  it names a group, and a frame sent to it is for every card that has joined that group. The
  broadcast address `ff:ff:ff:ff:ff:ff` has every bit set, this one included.
- **Bit 1, the U/L bit** (*universal/local*). 0 means the address was assigned under a
  manufacturer's OUI; **1 means somebody set it locally**, and the first three bytes name no
  manufacturer at all.

So `02` reads: one card, locally administered. The lab chose it on purpose. Its script,
`netlab.sh` from lesson 1, gives every card an address made of `02` and five bytes computed from the device's and the interface's
names, so that pc1 has the same MAC every time the lab is built and a transcript recorded today
matches one recorded next month. The server, `02:9e:43:3e:ca:ae`, and the router, `02:1f:23:e7:e9:d5`,
follow the same rule.

A quick way to recognise a local address: **look at the second hex digit**. If it is 2, 6, a or e,
the U/L bit is set and the I/G bit is clear. Virtual machines and containers use local addresses,
and phones choose a random local address for each Wi-Fi network they join, so that the same phone
cannot be followed from one café's network to the next by its MAC.

Two consequences are worth keeping:

- **A MAC address can be changed in a second**, by whoever controls the machine. It identifies a
  card on a link; it proves nothing about who is using it. Lesson 18 comes back to this when a
  switch port is locked to one address.
- **It means nothing beyond its own link.** A router reads it, strips it and builds a new frame
  with new addresses, so the server on the other side of a router never learns pc1's MAC. The
  gateway section shows the frame that proves it.
