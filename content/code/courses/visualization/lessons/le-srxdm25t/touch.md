---
title: Fingers, not pointers
version: 1
---

A mouse pointer is one pixel wide. A finger is not, and it covers what it is trying to touch. Two
things follow for a dashboard on a phone.

## Targets big enough to hit

Every control a reader taps, a filter, a tab, a button that opens a detail, needs to be large enough to
hit without hitting its neighbour.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 560 170\" role=\"img\" data-fig=\"l19-targets\" aria-label=\"Four squares compared at the same scale: 16 CSS pixels, the size of a small filter arrow; 24, the minimum WCAG 2.2 asks for at level AA; 44 points, Apple's recommendation; and 48 density-independent pixels, Google's Material recommendation.\"><rect x=\"30.0\" y=\"88.0\" width=\"32.0\" height=\"32.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"30.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">16 px: a small arrow</text><rect x=\"166.0\" y=\"72.0\" width=\"48.0\" height=\"48.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"166.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">24 px: WCAG 2.2 minimum</text><rect x=\"302.0\" y=\"32.0\" width=\"88.0\" height=\"88.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"302.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">44 pt: Apple</text><rect x=\"438.0\" y=\"24.0\" width=\"96.0\" height=\"96.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"438.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">48 dp: Material</text></svg>", "caption": "A finger is not a mouse pointer. The WCAG floor is 24 by 24 CSS pixels; the platform guidelines ask for nearly twice that, and a dashboard's filters should follow them."}
```

- **WCAG 2.2** asks, at level AA, for targets of **at least 24 by 24 CSS pixels**, or enough space
  around a smaller one that a 24-pixel circle centred on it touches no other target.
- **Apple's** Human Interface Guidelines recommend at least **44 by 44 points**, and **Google's**
  Material Design **48 by 48 density-independent pixels**. Both units are close to a CSS pixel.

The WCAG figure is the floor that a site can be audited against; the platform figures are what feels
comfortable. A dashboard's filters should aim for the second. The small arrow that opens a drop-down
menu on many desktop dashboards is about 16 pixels, too small even for the floor.

## Nothing that needs hovering

A tooltip that appears when the pointer rests on a point is a desktop habit, and on a phone there is
no resting. Touch screens turn a hover into a tap at best, and the tap often triggers something else.

So anything a reader needs must be **visible without hovering**:

- the key values written on the chart, as direct labels;
- the units in the title or the axis;
- the comparison on the card, not in a tooltip behind it.

A tooltip can still add detail for those who want it, as long as nobody needs it to understand the
chart.
