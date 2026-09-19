---
title: 2.4 and 5 GHz, and the choice between reaching and being fast
version: 1
---

A Wi-Fi router broadcasts on two or three bands at once, and they are not grades of the same
thing. They are different physics, and the choice between them is the same trade as the last
section, drawn in one decision.

| | 2.4 GHz | 5 GHz | 6 GHz |
|---|---|---|---|
| through walls | best | moderate | worst |
| range | furthest | good | short |
| speed | lowest | high | highest |
| how crowded | badly | much less | almost empty |
| also used by | microwaves, baby monitors, Bluetooth | radar in some channels | nothing yet |

**Lower frequency travels further and bends around things better.** That is not a design choice
anybody made; it is what longer waves do. So `2.4 GHz` is the one that reaches the end of the
garden and the one every cheap device in the neighbourhood is also using.

## Channels, and why only three of them are real

The `2.4 GHz` band is divided into 13 channels whose centres are `5 MHz` apart — but each channel
is `22 MHz` wide. **They overlap.** Channel 2 sits on top of most of channel 1 and most of
channel 3.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Two rows. The upper row shows three wide blocks side by side, labelled 1, 6 and 11, touching but not overlapping. The lower row shows the same blocks for 1 and 6 as dashed outlines with a solid block labelled 3 sitting across both of them, covering the right-hand part of block 1 and the left-hand part of block 6. A note says anything other than 1, 6 or 11 sits on top of two neighbours and takes turns with both.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Thirteen channels, and only three of them fit beside each other</text><text x=\"24\" y=\"52\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">the three that do not overlap</text><rect x=\"60\" y=\"68\" width=\"166\" height=\"48\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"143\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">1</text><rect x=\"249\" y=\"68\" width=\"166\" height=\"48\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"332\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">6</text><rect x=\"438\" y=\"68\" width=\"166\" height=\"48\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"521\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">11</text><text x=\"24\" y=\"150\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">and what channel 3 lands on</text><rect x=\"60\" y=\"166\" width=\"166\" height=\"48\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 4\"></rect><rect x=\"249\" y=\"166\" width=\"166\" height=\"48\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 4\"></rect><rect x=\"136\" y=\"178\" width=\"166\" height=\"48\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"219\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--amber)\">3</text><text x=\"24\" y=\"260\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Anything but 1, 6 or 11 sits on top of two neighbours and has to take turns with both of them.</text></svg>", "caption": "Three channels, and every other number is a way of sharing two people's air instead of one's."}
```

**Only channels 1, 6 and 11 fit side by side without touching.** A router on channel 3 is not
picking a quiet spot between two busy ones — it is queueing with both of them at once, and making
itself a problem for both.

## What to actually do with a home router

- **Put the main devices on 5 GHz** and leave `2.4 GHz` for the things that are far away, cheap,
  or old: a doorbell, a printer in the next room, a thermostat.
- **Check what the neighbours are on** with a free Wi-Fi analyser on a phone, and move to
  whichever of 1, 6 or 11 is emptiest. This is free and it is usually the largest single
  improvement available.
- **Do not set the 2.4 GHz channel width to 40 MHz.** It doubles the speed in theory and in a
  block of flats it means occupying two of the three usable channels.
- **Move the router.** Central, off the floor, out of the metal cabinet. A router in a corner is
  spending three quarters of its signal on the street.

## Mesh, repeaters and what the difference is

A **repeater** listens to the router and shouts again. It talks on the same radio it listens on,
so **it halves the speed of everything behind it**, and a second repeater halves it again.

A **mesh** system has a radio dedicated to the link between its units, so the units talk to each
other without stealing from the clients. It costs more and it is the right answer for a house
where one box cannot reach.

**A cable to the far unit beats both**, whenever there is any way to run one. That is the whole
of the advice, and it is unglamorous.
