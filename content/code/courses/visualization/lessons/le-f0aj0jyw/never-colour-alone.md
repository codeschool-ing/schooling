---
title: Never colour alone
version: 1
---

One rule settles most of this lesson, and it is WCAG's success criterion **1.4.1, Use of Color**:
**colour must not be the only way information is conveyed.** If a reader who sees no colour, or the
wrong colours, cannot get the message, the chart has failed, however good its palette.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 460 230\" role=\"img\" data-fig=\"l14-redundant\" aria-label=\"The South and Northeast chart redrawn for everyone and shown as deuteranopia sees it. South is a solid line and Northeast a dashed line with dots on it; Northeast is blue rather than green, so the two still differ in hue; and each line is named at its right-hand end, so no legend is needed.\"><rect x=\"20.0\" y=\"20.0\" width=\"420.0\" height=\"190.0\" rx=\"4\" fill=\"#ffffff\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M40.0 164.2 L52.6 168.0 L65.2 159.2 L77.8 163.7 L90.4 159.7 L103.0 156.0 L115.7 170.5 L128.3 155.1 L140.9 149.6 L153.5 153.8 L166.1 151.8 L178.7 122.6 L191.3 151.3 L203.9 143.2 L216.5 145.4 L229.1 136.0 L241.7 146.2 L254.3 132.2 L267.0 139.6 L279.6 134.3 L292.2 129.0 L304.8 134.6 L317.4 132.2 L330.0 87.8\" stroke=\"#8b7c1f\" stroke-width=\"2.2\" fill=\"none\" stroke-linejoin=\"round\"></path><path d=\"M40.0 174.8 L52.6 176.7 L65.2 171.4 L77.8 169.0 L90.4 167.2 L103.0 160.9 L115.7 159.9 L128.3 159.8 L140.9 151.2 L153.5 149.7 L166.1 143.2 L178.7 118.8 L191.3 146.3 L203.9 136.6 L216.5 138.6 L229.1 129.6 L241.7 127.4 L254.3 121.8 L267.0 122.1 L279.6 114.2 L292.2 113.5 L304.8 102.0 L317.4 106.5 L330.0 56.0\" stroke=\"#456cb3\" stroke-width=\"2.2\" fill=\"none\" stroke-dasharray=\"6 4\" stroke-linejoin=\"round\"></path><circle cx=\"40.0\" cy=\"174.8\" r=\"3.2\" fill=\"#456cb3\"></circle><circle cx=\"77.8\" cy=\"169.0\" r=\"3.2\" fill=\"#456cb3\"></circle><circle cx=\"115.7\" cy=\"159.9\" r=\"3.2\" fill=\"#456cb3\"></circle><circle cx=\"153.5\" cy=\"149.7\" r=\"3.2\" fill=\"#456cb3\"></circle><circle cx=\"191.3\" cy=\"146.3\" r=\"3.2\" fill=\"#456cb3\"></circle><circle cx=\"229.1\" cy=\"129.6\" r=\"3.2\" fill=\"#456cb3\"></circle><circle cx=\"267.0\" cy=\"122.1\" r=\"3.2\" fill=\"#456cb3\"></circle><circle cx=\"304.8\" cy=\"102.0\" r=\"3.2\" fill=\"#456cb3\"></circle><text x=\"338.0\" y=\"93.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"#20263c\">South</text><text x=\"338.0\" y=\"52.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"#20263c\">Northeast</text></svg>", "caption": "Three cues instead of one: the hue differs, the line style differs, and the name sits on the line. Any one of them can fail and the chart still reads."}
```

The chart is shown as deuteranopia sees it, and it still reads, because **three cues carry the
difference** and any one of them is enough:

- **the hue differs**: Northeast is blue instead of green, and blue survives red-green deficiency;
- **the line style differs**: South is solid; Northeast is dashed with dots on it;
- **the name is on the line**: each series is labelled at its right-hand end, so no legend has to be
  matched by colour.

## Ways to add a second cue

| chart | second cue |
|---|---|
| lines | direct labels at the ends; dashes, dots; markers of different shapes |
| bars | labels on or beside the bars; a pattern or hatching on one series |
| scatterplot | different marker shapes per group, as lesson 1 suggested |
| map | values written on the areas that matter; a second map in grey |
| status (good, bad) | a symbol or a word: up and down arrows, "on target", "late" |

**Direct labels are the strongest of these**, because they remove the colour lookup altogether: the
reader does not need to tell two colours apart if the line says what it is.

## What this does not mean

It does not mean charts should be grey. Colour is the fastest channel there is for most readers, and
lessons 12 and 13 use it on purpose. The rule asks for **colour plus something**, so that colour
speeds the reading up for those who see it and nobody is shut out when it fails.
