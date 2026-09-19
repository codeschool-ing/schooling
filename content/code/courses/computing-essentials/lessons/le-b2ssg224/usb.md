---
title: USB, where the naming is worse than the technology
version: 1
---

USB is the port everything eventually plugs into, and its names are the single most confusing
thing in this course. That is not your fault and it is not an accident of history: the standard
was renamed, twice, in a way that made older names apply to newer things.

## Shapes first, because those at least are honest

| shape | where you meet it |
|---|---|
| **USB-A** | the flat rectangle. The one everybody pictures, on every desktop and hub |
| **USB-B** | the tall square-ish one. Printers and audio interfaces |
| **Micro-B** | the small trapezoid. Phones before about 2018, and still on cheap devices |
| **USB-C** | the small oval, and the only one that goes in either way up |

Five shapes, and one of them is being replaced by another. **USB-C is winning and it is a shape,
not a speed** — which is the confusion the rest of this section exists to clear up.

## The names, which describe the same wires three times

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Three rows. The first says 5 gigabits a second and lists the names USB 3.0, USB 3.1 Gen 1, USB 3.2 Gen 1 and SuperSpeed USB 5Gbps. The second says 10 gigabits and lists USB 3.1 Gen 2, USB 3.2 Gen 2 and SuperSpeed USB 10Gbps. The third says 20 gigabits and lists USB 3.2 Gen 2x2 and SuperSpeed USB 20Gbps. A note says the speed is the only column that means anything and every name beside it is the same wire.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">The same three speeds, renamed twice</text><text x=\"24\" y=\"48\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what it does</text><text x=\"180\" y=\"48\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">and what it has been sold as</text><rect x=\"24\" y=\"62\" width=\"672\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"40\" y=\"84\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">5 Gb/s</text><text x=\"180\" y=\"84\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">USB 3.0 · USB 3.1 Gen 1 · USB 3.2 Gen 1 · SuperSpeed USB 5Gbps</text><rect x=\"24\" y=\"118\" width=\"672\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"40\" y=\"140\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">10 Gb/s</text><text x=\"180\" y=\"140\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">USB 3.1 Gen 2 · USB 3.2 Gen 2 · SuperSpeed USB 10Gbps</text><rect x=\"24\" y=\"174\" width=\"672\" height=\"44\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"40\" y=\"196\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">20 Gb/s</text><text x=\"180\" y=\"196\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">USB 3.2 Gen 2x2 · SuperSpeed USB 20Gbps</text><text x=\"24\" y=\"240\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">The left column is the only one that means anything. Every name beside it is the same wire.</text></svg>", "caption": "Read the speed and ignore the name. A box advertising USB 3.2 is advertising a number between 5 and 20 gigabits and has not said which."}
```

**`USB 3.2` on a box is not information.** It covers everything from 5 to 20 gigabits. The only
useful figure is the one in gigabits, which is why the marketing names were eventually changed to
put the number in front — `SuperSpeed USB 10Gbps` says what it does.

## Power, which travels the same cable and is a separate negotiation

A plain USB-A port supplies `2.5 W`, enough for a mouse and not for much else. **USB Power
Delivery** lets the two ends negotiate up, in steps, as far as `240 W`.

The consequence people meet is this: **a USB-C charger is not a USB-C charger.** A phone charger
delivering `20 W` plugged into a laptop that wants `65 W` will charge it — slowly, or only while
it is asleep, or not at all while it is working hard. Nothing is broken and nothing says so. The
wattage is printed on the charger, in small type, and it is the number that matters.

## Video, which is a third separate thing

**DisplayPort Alternate Mode** lets a USB-C port carry a video signal by handing some of its
wires over to DisplayPort. A USB-C socket may or may not do it, and again the shape does not say.

This is why a USB-C-to-HDMI cable works on one laptop and does nothing on another one beside it.
The cable is fine. The second machine's port never had the video wires connected.

## Thunderbolt, which is the one that promises everything

**Thunderbolt 3 and 4** use the USB-C shape and guarantee what USB leaves optional: `40 Gb/s`,
video, power, and enough bandwidth to run an external graphics enclosure or a drive at full
speed. The lightning-bolt symbol beside the port is the promise.

`USB4` is the standard built out of Thunderbolt 3, so the two now overlap almost completely. If
the port has the bolt, everything above is guaranteed.

## The cable is a component, not a wire

A USB-C cable can be any of: charging only, `480 Mb/s` data, `10 Gb/s`, `40 Gb/s`, `60 W`,
`240 W`. **They look identical.** The cable in the box with a phone is almost always the slowest
kind, and using it to back up a drive turns a ten-minute job into two hours with no warning
anywhere.

Keep the good cables and label them. That is not fussiness; it is the only way to tell.
