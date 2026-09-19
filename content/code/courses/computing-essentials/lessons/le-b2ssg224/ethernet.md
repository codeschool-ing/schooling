---
title: Ethernet, the one place where the numbers are honest
version: 1
---

The network socket is the least confusing connector on the machine. One shape, called `RJ45`, one
protocol, and speeds that are what they say. It has a plastic clip that breaks, and that is about
the whole of its drama.

What is worth knowing is not the port. It is that **a link runs at the speed of its slowest
part**, and there are usually four parts.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Four boxes in a row joined by arrows: the machine's port at one gigabit, the cable at one gigabit, the wall socket at one hundred megabits, and the router's port at one gigabit. A wide box underneath says what the link actually runs at, and gives one hundred megabits. A note says four links and the slowest decides.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">One slow part, and the whole link is that slow</text><rect x=\"24\" y=\"56\" width=\"150\" height=\"64\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"99\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the machine's port</text><text x=\"99\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">1 Gb/s</text><path d=\"M180 88 L192 88 M186 83 L192 88 L186 93\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><rect x=\"198\" y=\"56\" width=\"150\" height=\"64\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"273\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the cable</text><text x=\"273\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">1 Gb/s</text><path d=\"M354 88 L366 88 M360 83 L366 88 L360 93\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><rect x=\"372\" y=\"56\" width=\"150\" height=\"64\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"447\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the socket in the wall</text><text x=\"447\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">100 Mb/s</text><path d=\"M528 88 L540 88 M534 83 L540 88 L534 93\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><rect x=\"546\" y=\"56\" width=\"150\" height=\"64\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"621\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the router's port</text><text x=\"621\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">1 Gb/s</text><rect x=\"24\" y=\"166\" width=\"672\" height=\"52\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"44\" y=\"192\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">what the link actually runs at</text><text x=\"676\" y=\"192\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\">100 Mb/s</text><text x=\"24\" y=\"242\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Four parts, and the slowest one decides. Nothing anywhere reports the other three as wasted.</text></svg>", "caption": "The failure has no symptom of its own: everything connects, everything works, and one number is a tenth of what it should be."}
```

## The speeds, and which you will meet

| | what it is | where |
|---|---|---|
| `100 Mb/s` | *Fast Ethernet*, and it is not | old wall sockets, cheap switches, some printers |
| `1 Gb/s` | *Gigabit*, the ordinary one | every machine and router sold for fifteen years |
| `2.5 Gb/s` | the new middle | recent motherboards, better routers |
| `10 Gb/s` | for moving large files between machines | servers, and enthusiasts |

**Almost every home problem is the first row appearing somewhere unexpected**, and the usual
places are a wall socket wired years ago and a switch bought for ten reais.

## Cable categories, briefly and without the marketing

| | rated for |
|---|---|
| `Cat 5e` | 1 Gb/s at 100 m. Fine for almost every house |
| `Cat 6` | 1 Gb/s at 100 m, 10 Gb/s up to about 55 m |
| `Cat 6a` | 10 Gb/s at 100 m |
| `Cat 7`, `Cat 8` | more, in conditions a home does not have |

`Cat 6` is the sensible default for anything new, because the price difference is small and it is
what you would wish you had put in the wall. Anything above `Cat 6a` in a house is a number on a
package.

## Ethernet against Wi-Fi, which is not really a contest

A cable gives you a **steady** speed, a **low and constant** delay, and immunity to the
neighbours' router. Wi-Fi gives you a speed that changes when somebody walks between the rooms.

For reading and writing, nobody notices the difference. For a video call, a large upload, or a
game, the thing a cable fixes is not the speed at all — it is the **variation**. A connection
that averages well and stutters once a minute is worse to be on than a slower one that never
does.

## The clip, which is the only part that breaks

The plastic tab that holds the plug in snaps off, and then the cable falls half out and the link
drops when somebody moves a chair. It is a two-minute repair with a new plug and a crimping tool,
and until then it is a fault that looks exactly like an unreliable network.
