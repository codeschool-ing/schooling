---
title: A port is three promises wearing one shape
version: 1
---

Every socket on a machine is really three separate facts stacked on top of each other, and only
the first one is visible:

1. **The shape** — what will physically plug in.
2. **The protocol** — what language runs over those wires.
3. **The speed** — how fast that protocol is running here, on this machine.

A connector shows you the first and says nothing about the other two. Almost every frustrating
afternoon with a cable comes from assuming that it does.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"One box on the left labelled as a single USB-C socket, with four lines fanning out from it to four boxes on the right. The four are USB 2.0 at 480 megabits a second with no video, USB 3.2 Gen 2 at 10 gigabits and perhaps video, USB4 at 40 gigabits with video, and Thunderbolt 4 at 40 gigabits with video and a drive at full speed. A note at the foot says nothing on the outside of the machine says which of the four you have.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">One socket shape, four different things behind it</text><rect x=\"24\" y=\"110\" width=\"180\" height=\"68\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"114\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">one USB-C socket</text><path d=\"M204 144 L280 60\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M204 144 L280 116\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M204 144 L280 172\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M204 144 L280 228\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><rect x=\"280\" y=\"40\" width=\"416\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"296\" y=\"60\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">USB 2.0</text><text x=\"680\" y=\"60\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">480 Mb/s, and no picture at all</text><rect x=\"280\" y=\"96\" width=\"416\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"296\" y=\"116\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">USB 3.2 Gen 2</text><text x=\"680\" y=\"116\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">10 Gb/s, and a picture if you are lucky</text><rect x=\"280\" y=\"152\" width=\"416\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"296\" y=\"172\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">USB4</text><text x=\"680\" y=\"172\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">40 Gb/s, and a picture</text><rect x=\"280\" y=\"208\" width=\"416\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"296\" y=\"228\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Thunderbolt 4</text><text x=\"680\" y=\"228\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">40 Gb/s, a picture, and a drive at full speed</text><text x=\"24\" y=\"278\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Nothing on the outside of the machine says which of the four you have.</text></svg>", "caption": "The shape is the only one of the three promises you can see, and it is the one that matters least."}
```

## How to find out what a socket actually is

There is no trick that works from across the room. There are three that work:

- **The symbol beside it.** A lightning bolt means Thunderbolt; a `D` shape means DisplayPort
  comes out of it; `SS` means SuperSpeed, which is `5 Gb/s` or better. A bare socket with no
  symbol is the slow one, and that absence is deliberate.
- **The colour inside a rectangular USB-A.** Black or white is USB 2.0. Blue is USB 3.x. Red or
  yellow usually means it stays powered while the machine is asleep. This is a convention rather
  than a standard, so it is a strong hint and not a fact.
- **The specification for the model.** The only one that is reliable, and the reason the other
  two are worth knowing is that you rarely have it to hand.

## The rule that comes out of this

**A chain runs at the speed of its slowest link, and there are four links.** The port, the cable,
the device and whatever the machine is doing with its remaining lanes. A `40 Gb/s` port with a
charging-only cable in it transfers nothing at all, and neither end reports an error.

That is worth holding on to, because it means **"it does not work" and "it works slowly" have the
same set of causes here**, and you find them by the same method: change one link at a time.
