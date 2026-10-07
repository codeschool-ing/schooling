---
title: Area, volume and pictograms
version: 1
---

Lesson 2 put the encodings in order of how accurately people read them, and area came well below
length. Lesson 6 gave the rule for bubbles: size them by area, never by radius. This section follows
the same mistake into the places it hides.

North took 7,384 orders in 2024 and 11,852 in 2025, a rise of 60.5%. Draw each year as a circle and
make the radius 1.6 times larger, and the **area**, which is what the eye compares, becomes 2.58
times larger:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 240\" role=\"img\" data-fig=\"l16-area\" aria-label=\"North's orders in 2024, 7,384, and 2025, 11,852, a rise of 60.5%, drawn three ways. First, two circles whose radius grows by 1.61 times: the second circle has 2.58 times the area and looks it. Second, two circles whose area grows by 1.61 times: the radius grows by only 1.27. Third, two bars.\"><text x=\"30.0\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">radius scaled</text><circle cx=\"75.0\" cy=\"156.0\" r=\"34.0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"184.6\" cy=\"135.4\" r=\"54.6\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><text x=\"75.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2024</text><text x=\"184.6\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2025</text><text x=\"30.0\" y=\"36.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">looks 2.6×</text><text x=\"250.0\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">area scaled</text><circle cx=\"295.0\" cy=\"156.0\" r=\"34.0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><circle cx=\"393.1\" cy=\"146.9\" r=\"43.1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></circle><text x=\"295.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2024</text><text x=\"393.1\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2025</text><text x=\"250.0\" y=\"36.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">is 1.6×</text><text x=\"480.0\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">bars</text><path d=\"M480.0 190.0 L610.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M492.0 103.9 h40.0 v86.1 h-40.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"512.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2024</text><text x=\"512.0\" y=\"95.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">7,384</text><path d=\"M557.0 51.7 h40.0 v138.3 h-40.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"577.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2025</text><text x=\"577.0\" y=\"43.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">11,852</text></svg>", "caption": "The eye reads a circle by its area. Scale the radius by the data and the area grows by the square of it; a pictogram scaled in height and width does the same, and a cube in all three goes to the cube."}
```

This is the commonest mistake in infographics, and it is made in good faith: the drawing tool sizes a
shape by its width, so the person scales the width.

## The rule

- **Scale the area, not the radius.** The radius grows by the square root of the ratio: √1.605 =
  1.267. As lesson 6 said, matplotlib's `scatter` takes `s` as an area already; drawing tools that
  size a shape by its width do not.
- **A pictogram scaled in two dimensions has the same problem.** A shopping bag drawn 1.6 times taller
  and 1.6 times wider covers 2.58 times the space.
- **Volume is worse.** A cube or a cylinder scaled in all three dimensions grows by the cube: 1.605³ =
  4.13. And the eye does not even read volume as volume; it reads the area of the drawing, which is
  somewhere in between.

## The safer choice

Even drawn correctly, areas are read less accurately than lengths. When the comparison matters, use
bars. When the picture is the point, as in an icon chart, **repeat** an icon of fixed size instead of
growing one: twelve bags for 12,000 orders and seven for 7,000 are counted, not estimated.
