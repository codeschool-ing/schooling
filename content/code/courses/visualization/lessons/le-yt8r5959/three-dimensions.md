---
title: Three dimensions of colour
version: 1
---

A screen makes every colour from three lights, red, green and blue, each between 0 and 255. `#2b52c9`,
the blue of this course's charts, is 43 red, 82 green and 201 blue. That description, **RGB**, is how
the hardware works, and it is almost useless for choosing colours: nobody can say what 43, 82, 201
looks like, or how to make it a little lighter.

People describe colour with three different questions, and chart design uses the same three.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 620 210\" role=\"img\" data-fig=\"l11-three\" aria-label=\"Three rows of colour swatches. The first changes hue all the way round, red, orange, yellow, green, cyan, blue, purple, magenta and back to red, at full saturation. The second keeps one blue hue and changes saturation, from grey to vivid blue. The third keeps the same blue and changes lightness, from black to white.\"><rect x=\"130.0\" y=\"20.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#ff0000\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"130.0\" y=\"82.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#808080\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"130.0\" y=\"144.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#030812\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"168.0\" y=\"20.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#ff8000\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"168.0\" y=\"82.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#747c8b\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"168.0\" y=\"144.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#081837\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"206.0\" y=\"20.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#ffff00\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"206.0\" y=\"82.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#687897\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"206.0\" y=\"144.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#0d285c\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"244.0\" y=\"20.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#80ff00\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"244.0\" y=\"82.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#5d74a2\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"244.0\" y=\"144.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#133882\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"282.0\" y=\"20.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#00ff00\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"282.0\" y=\"82.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#5170ae\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"282.0\" y=\"144.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#1848a7\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"320.0\" y=\"20.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#00ff80\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"320.0\" y=\"82.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#466cb9\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"320.0\" y=\"144.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#1d58cc\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"358.0\" y=\"20.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#00ffff\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"358.0\" y=\"82.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#3a68c5\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"358.0\" y=\"144.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#336de2\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"396.0\" y=\"20.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#007fff\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"396.0\" y=\"82.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#2e64d1\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"396.0\" y=\"144.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#5888e7\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"434.0\" y=\"20.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#0000ff\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"434.0\" y=\"82.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#2361dc\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"434.0\" y=\"144.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#7da2ec\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"472.0\" y=\"20.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#7f00ff\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"472.0\" y=\"82.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#175de8\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"472.0\" y=\"144.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#a3bdf2\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"510.0\" y=\"20.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#ff00ff\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"510.0\" y=\"82.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#0c59f3\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"510.0\" y=\"144.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#c8d8f7\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"548.0\" y=\"20.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#ff0080\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"548.0\" y=\"82.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#0055ff\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"548.0\" y=\"144.0\" width=\"34.0\" height=\"44.0\" rx=\"2\" fill=\"#edf2fc\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"118.0\" y=\"42.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">hue</text><text x=\"118.0\" y=\"104.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">saturation</text><text x=\"118.0\" y=\"166.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">lightness</text></svg>", "caption": "Three questions about any colour: which colour family (hue), how much colour against grey (saturation), how light or dark (lightness)."}
```

- **Hue** answers *which colour?* Red, orange, yellow, green, blue, purple. It is measured as an angle
  round a circle, 0 to 360 degrees, with red at 0, green near 120 and blue near 240, and the circle
  closes back on red.
- **Saturation**, also called **chroma**, answers *how much colour, against grey?* At zero a colour is
  a grey; at full saturation it is as vivid as it can be.
- **Lightness** answers *how light or dark?* From black, through the colour, to white.

## What each dimension can do in a chart

Lesson 1 split colour into two channels. Now they have names.

| dimension | carries an order? | use in a chart |
|---|---|---|
| hue | **no**: the circle has no start | telling categories apart |
| lightness | **yes**: everybody sorts light to dark | showing more and less |
| saturation | weakly | emphasis: vivid for what matters, muted for the rest |

**Lightness is the dimension that carries quantity**, and it is also the one the eye reads most
reliably, because it is what survives in dim light, on a bad projector, in a black-and-white printout
and, as lesson 14 explains, for most people who see colour differently.

**Saturation is the dimension of emphasis.** A single vivid colour among muted ones is where the eye
goes first, which lesson 13 uses on purpose and which a chart full of vivid colours wastes.

## The colour picker's version

Most software exposes these three as **HSL** (hue, saturation, lightness) or its cousin **HSV**. They
are easy to use and they are not what they claim to be, which is the next section.
