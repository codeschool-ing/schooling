---
title: Size classes, where the layout is allowed to change shape
version: 1
---

**A size class is a named band of window sizes, and an app changes its layout only when the window
moves from one band to another.** That keeps the number of layouts small and the same across every
screen of the app. Android and iOS both have them, with different bands and the same purpose.

## Android: window size classes in dp

Android's documentation on window size classes gives the width breakpoints in dp, with what each
band usually holds:

| width class | breakpoint | what the documentation says it represents |
|---|---|---|
| compact | under 600 dp | 99.96% of phones in portrait |
| medium | 600 dp to under 840 dp | 93.73% of tablets in portrait, most large unfolded inner displays in portrait |
| expanded | 840 dp to under 1200 dp | 97.22% of tablets in landscape, most large unfolded inner displays in landscape |
| large | 1200 dp to under 1600 dp | large tablet displays |
| extra-large | 1600 dp and over | desktop displays |

**The heights have bands too**: compact under 480 dp, which the same table says covers 99.78% of
phones in landscape; medium from 480 to under 900 dp; expanded from 900 dp. The documentation adds
that most apps can decide their layout from the width alone, and gives the case where height
matters: a phone in landscape is often medium wide and compact tall, and two panes side by side do
not work in a window that short. The percentages are Google's, as published on that page when it
was read on 30 October 2026; the breakpoints are the part an app writes into its code.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 168\" role=\"img\" data-fig=\"l08-ruler\" aria-label=\"A ruler of window widths from 0 to 1800 dp, divided by Android's width breakpoints: compact below 600 dp, medium from 600 to 840, expanded from 840 to 1200, large from 1200 to 1600, and extra-large from 1600. Four example windows are marked: a phone in portrait at 360 dp, a foldable open in portrait at 700, the same foldable turned at 880, and a tablet in landscape at 1280.\"><defs><marker id=\"l08-ruler-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"360\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">window width in dp, and the class Android gives it</text><rect x=\"40.0\" y=\"100\" width=\"213.3\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"146.65\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">compact</text><rect x=\"253.3\" y=\"100\" width=\"85.3\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"295.95\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">medium</text><rect x=\"338.7\" y=\"100\" width=\"128.0\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"402.7\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">expanded</text><rect x=\"466.7\" y=\"100\" width=\"142.2\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"537.8\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">large</text><rect x=\"608.9\" y=\"100\" width=\"71.1\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"644.4499999999999\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">extra-large</text><path d=\"M40.0 130 L40.0 140\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"40.0\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><path d=\"M253.3 130 L253.3 140\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"253.3\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">600</text><path d=\"M338.7 130 L338.7 140\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"338.7\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">840</text><path d=\"M466.7 130 L466.7 140\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"466.7\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1200</text><path d=\"M608.9 130 L608.9 140\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"608.9\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1600</text><text x=\"680.0\" y=\"152\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">dp</text><text x=\"168.0\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">phone, portrait</text><text x=\"168.0\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">360</text><path d=\"M168.0 55 L168.0 98\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-ruler-ah-paper-dim)\"></path><text x=\"288.9\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">foldable, open</text><text x=\"288.9\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">700</text><path d=\"M288.9 83 L288.9 98\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-ruler-ah-paper-dim)\"></path><text x=\"352.9\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">foldable, turned</text><text x=\"352.9\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">880</text><path d=\"M352.9 55 L352.9 98\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-ruler-ah-paper-dim)\"></path><text x=\"495.1\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">tablet, landscape</text><text x=\"495.1\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1280</text><path d=\"M495.1 83 L495.1 98\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-ruler-ah-paper-dim)\"></path></svg>", "caption": "Android's width classes as bands on one ruler. The example windows are round numbers, not measurements of real devices; what matters is which band a window falls in, and that the same device lands in different bands as its window changes."}
```

## iOS: compact or regular, on each axis

**Apple's Human Interface Guidelines give each axis one of two size classes, compact or regular**,
so a window is one of four combinations: compact width and compact height, compact width and
regular height, and so on. The system sets them from the device, the window and multitasking,
and the guidelines say to decide layout from the size classes rather than from the device type or
the orientation, because those do not say how much space there is. Apple does not publish the
classes as dp-style numbers for an app to compare; the app reads which class it is in.

## React Native: the window's size, and a rule of your own

React Native has no size classes. **`useWindowDimensions` returns the window's width and height
in its density-independent units**, and its documentation says it updates them when the window
size or the font scale changes, so a component that reads it is drawn again when the window
changes. Where the bands fall is the app's decision, and the simplest honest choice is to use
Android's numbers on both platforms, which is what this lesson's program does.

## The same question in three spellings

The fragments below ask whether the window is wide enough for two panes. They are adapted from
each platform's documentation, and **they were not compiled or run for this course**.

```kotlin
// Compose: the window size class, from the Material 3 adaptive library
val sizeClass = currentWindowAdaptiveInfo().windowSizeClass
val twoPanes = sizeClass.isWidthAtLeastBreakpoint(WindowSizeClass.WIDTH_DP_EXPANDED_LOWER_BOUND)
```

```swift
// SwiftUI: the horizontal size class, from the environment
@Environment(\.horizontalSizeClass) private var widthClass
var twoPanes: Bool { widthClass == .regular }
```

```tsx
// React Native: the window's width in dp or points, and a breakpoint the app chose
const { width } = useWindowDimensions();
const twoPanes = width >= 840;
```

**Each of the three is read again when the window changes**: Compose and SwiftUI redraw what
depends on the value, and `useWindowDimensions` updates. None of them asks "is this a tablet".
The SwiftUI one is coarser than the other two, with two values for the axis rather than five,
and an app that needs a finer line reads the window's width as well.
