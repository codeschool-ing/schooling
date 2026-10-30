---
title: Points, percentages and the size of the window
version: 1
---

**A number in a React Native style is a density-independent pixel**, which Android calls a *dp* and iOS
a *point*. It has no unit written after it, and it means the same physical size on every phone,
roughly a 160th of an inch. A row 62 high is 62 on a small phone and on a large one, and covers more
real pixels on the one whose screen is denser.

## No px, no em, no rem

The units of CSS are not here. There is no `px` to write, because a number already is the unit; no
`em` or `rem`, because nothing cascades a font size to measure against; no `vh` or `vw`. What remains:

| written as | means | the planner uses it for |
|---|---|---|
| `16` | 16 points | almost everything |
| `"50%"` | half of the parent's size on that axis | nothing yet; a two-column layout would |
| `flex: 1` | a share of the free space | the week bar |
| `aspectRatio: 16 / 9` | height from width, or the reverse | a course cover in lesson 13 |

## The window, when it matters

A layout written in flex and percentages adapts by itself, and the next section measures the planner at
a tablet's width to show it. When a decision depends on the size, *two columns above 600 points wide*,
the component asks for the window:

```tsx
const { width, height, fontScale } = useWindowDimensions();
```

`useWindowDimensions` re-renders the component when the window changes, on rotation, on a tablet in
split screen, on a foldable opened. **Read it in the component that decides**, not once at start-up in
a constant, which is the mistake that leaves a rotated tablet with a phone's layout.

## The person's text size

`fontScale` in that answer is the person's chosen text size, from the phone's accessibility settings,
as a multiplier. React Native applies it to every `fontSize` by itself: a `Text` of 17 is drawn at 17
times the scale. **Do not fight it.** A row with a fixed `height` cuts off its own text at large scales;
give rows `padding` and let the text set the height, as the planner's rows do. `maxFontSizeMultiplier`
on a `Text` caps the scale where a layout truly cannot grow, a tab bar's labels for instance, and it is a
decision to make knowing that it takes something away from somebody who asked for it.

## Real pixels, when you need them

`PixelRatio.get()` returns the density, 2 or 3 on most phones, and `PixelRatio.roundToNearestPixel`
snaps a value to a whole device pixel, which keeps a hairline from blurring. `StyleSheet.hairlineWidth`
is the thinnest line the screen can draw. These matter for the occasional divider and for images, as
lesson 4 said; nothing else in the planner needs them.
