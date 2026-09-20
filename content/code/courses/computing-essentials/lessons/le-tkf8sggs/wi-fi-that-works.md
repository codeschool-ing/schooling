---
title: Wi-Fi, which is a radio and behaves like one
version: 1
---

Wi-Fi is radio. Everything that is surprising about it stops being surprising once that sentence
is taken literally: it is absorbed by things, it is reflected by things, it is interfered with by
other radios, and it gets weaker with distance in a way that does not care how much you paid.

## Two bands, and the trade is always the same

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 322\" role=\"img\" aria-label=\"A diagram comparing the two Wi-Fi bands across four rooms. Along the top, the room with the router, one wall away, two walls away and three walls away. Below, a bar for two point four gigahertz covering every room, and a bar for five gigahertz covering only the first two, much faster where it reaches.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">The same house, measured on both bands</text><rect x=\"24\" y=\"38\" width=\"168\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"108.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the room with the router</text><rect x=\"192\" y=\"38\" width=\"168\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"276.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">one wall away</text><rect x=\"360\" y=\"38\" width=\"168\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"444.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">two walls away</text><rect x=\"528\" y=\"38\" width=\"168\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"612.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">three walls away</text><text x=\"108.0\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">the box is here</text><text x=\"24\" y=\"124\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">2.4 GHz</text><text x=\"696\" y=\"124\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Mbps</text><rect x=\"24\" y=\"136\" width=\"672\" height=\"34\" rx=\"4\" fill=\"var(--phosphor)\" fill-opacity=\"0.22\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"108.0\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">90</text><text x=\"276.0\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">70</text><text x=\"444.0\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">45</text><text x=\"612.0\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">25</text><text x=\"24\" y=\"186\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Slower everywhere, and it arrives everywhere.</text><text x=\"24\" y=\"220\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">5 GHz</text><text x=\"696\" y=\"220\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Mbps</text><rect x=\"24\" y=\"232\" width=\"336\" height=\"34\" rx=\"4\" fill=\"var(--amber)\" fill-opacity=\"0.22\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"360\" y=\"232\" width=\"336\" height=\"34\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"108.0\" y=\"249\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">420</text><text x=\"276.0\" y=\"249\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">180</text><text x=\"612.0\" y=\"249\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">—</text><text x=\"444.0\" y=\"249\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">—</text><text x=\"24\" y=\"282\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Three times the speed in the first room, and nothing at all in the last two.</text><text x=\"24\" y=\"306\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">The numbers are an illustration, not a measurement: a wall of brick and a wall of plasterboard are different walls.</text></svg>", "caption": "Two bars across a plan of four rooms. The two point four gigahertz bar covers all four rooms, with speeds falling from ninety to twenty-five. The five gigahertz bar covers the first two rooms at four hundred and twenty and a hundred and eighty, and is empty for the last two."}
```

Every modern router transmits on **2.4 GHz** and on **5 GHz**, and often on both at once under
the same name.

- **2.4 GHz travels further and through more walls**, and is slower. It is also crowded: cordless
  phones, baby monitors, Bluetooth, and — genuinely, this is not a joke — microwave ovens all use
  it, along with every neighbour's router.
- **5 GHz is much faster and stops at walls.** In a flat it is usually the better choice in the
  room the router is in and the one next door, and useless three rooms away.

A newer band, **6 GHz**, goes further in the same direction: faster again, and it barely leaves
the room. Phones and laptops from the last few years can use it; nothing older can.

**The decision is usually made for you**, because most boxes advertise one name on both bands and
let each device pick. That works well and it fails in one specific way: a device that connected on
5 GHz in the living room hangs on to it as you walk away, long past the point where 2.4 GHz would
be faster. Turning the Wi-Fi off and on makes it choose again, which is why that pointless-looking
ritual sometimes works.

## Where the box goes

The single largest improvement available to most homes costs nothing:

- **High, central, and out in the open.** A router on the floor behind a sofa is radiating into
  furniture. On a shelf in the middle of the flat, it reaches most of it.
- **Away from metal and water.** A metal cabinet is a shield. A fish tank is a bucket of a
  substance that absorbs 2.4 GHz specifically — this is the same physics a microwave oven uses.
- **Away from the other radios.** A metre from the cordless phone base and the microwave is
  enough.
- **Not in the cupboard by the front door**, which is where the provider installed it because
  that is where the cable comes in. Moving it is a longer cable and an afternoon, and it is
  usually worth more than any equipment upgrade.

## Channels, briefly

Each band is divided into channels, and two routers on the same channel share it — they do not
interfere so much as take turns, which is why a crowded channel feels like *slow* rather than
*broken*.

On 2.4 GHz there are only three that do not overlap: **1, 6 and 11.** Anything else overlaps two
of them and makes things worse for everybody, including you.

Most routers pick automatically and most of the time that is fine. It is worth a manual look only
when a phone app scanning the neighbourhood shows nine networks on channel 6 and none on 11.

## What the bar is actually telling you

The signal bars on a phone report **strength**, and strength is not speed. A full-strength
connection to a router whose line to the street is saturated is a full bar and nothing loading.

The two are worth separating whenever anybody says the Wi-Fi is slow, and the next section but
one is how.
