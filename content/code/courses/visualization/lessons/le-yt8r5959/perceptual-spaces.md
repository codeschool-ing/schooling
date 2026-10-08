---
title: Perceptual colour spaces
version: 1
---

A **perceptually uniform** colour space is designed so that equal distances in it look like equal
differences to the eye. Two have become standard.

- **CIELAB**, published in 1976 by the International Commission on Illumination, describes a colour by
  lightness, **L**, and two opposing axes, green to red (**a**) and blue to yellow (**b**). It has been
  the reference for colour science for decades and is not perfectly uniform, especially in blues.
- **OKLab**, published by Björn Ottosson in 2020, keeps the same idea with better uniformity and simple
  arithmetic. Its polar form, **OKLCH**, gives lightness, chroma and hue: the three dimensions from the
  first section, measured in a way the eye agrees with. CSS accepts it directly as `oklch()`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 620 290\" role=\"img\" data-fig=\"l11-ramps\" aria-label=\"Two seven-step yellow ramps from pale to dark, with the perceived lightness of each step plotted beneath as a line. The first ramp takes equal steps of HSL lightness, and its line bends: the first four steps are almost the same pale yellow and the last three drop steeply. The second takes equal steps in OKLCH, a space built to match perception, and its line falls straight.\"><text x=\"40.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">equal steps in HSL</text><rect x=\"40.0\" y=\"34.0\" width=\"32.0\" height=\"40.0\" rx=\"2\" fill=\"#fbfbda\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"76.0\" y=\"34.0\" width=\"32.0\" height=\"40.0\" rx=\"2\" fill=\"#f4f49d\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"112.0\" y=\"34.0\" width=\"32.0\" height=\"40.0\" rx=\"2\" fill=\"#eded60\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"148.0\" y=\"34.0\" width=\"32.0\" height=\"40.0\" rx=\"2\" fill=\"#e7e723\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"184.0\" y=\"34.0\" width=\"32.0\" height=\"40.0\" rx=\"2\" fill=\"#b1b114\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"220.0\" y=\"34.0\" width=\"32.0\" height=\"40.0\" rx=\"2\" fill=\"#74740d\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"256.0\" y=\"34.0\" width=\"32.0\" height=\"40.0\" rx=\"2\" fill=\"#373706\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M40.0 250.0 L288.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M40.0 110.0 L40.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M57.7 113.6 L93.1 119.1 L128.6 124.0 L164.0 127.7 L199.4 156.1 L234.9 190.2 L270.3 227.9\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"57.7\" cy=\"113.6\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"93.1\" cy=\"119.1\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"128.6\" cy=\"124.0\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"164.0\" cy=\"127.7\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"199.4\" cy=\"156.1\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"234.9\" cy=\"190.2\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"270.3\" cy=\"227.9\" r=\"3.5\" fill=\"var(--amber)\"></circle><text x=\"340.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">equal steps in OKLCH</text><rect x=\"340.0\" y=\"34.0\" width=\"32.0\" height=\"40.0\" rx=\"2\" fill=\"#fdf7d0\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"376.0\" y=\"34.0\" width=\"32.0\" height=\"40.0\" rx=\"2\" fill=\"#dcd5a6\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"412.0\" y=\"34.0\" width=\"32.0\" height=\"40.0\" rx=\"2\" fill=\"#bdb47d\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"448.0\" y=\"34.0\" width=\"32.0\" height=\"40.0\" rx=\"2\" fill=\"#9e9454\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"484.0\" y=\"34.0\" width=\"32.0\" height=\"40.0\" rx=\"2\" fill=\"#817428\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"520.0\" y=\"34.0\" width=\"32.0\" height=\"40.0\" rx=\"2\" fill=\"#655600\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"556.0\" y=\"34.0\" width=\"32.0\" height=\"40.0\" rx=\"2\" fill=\"#4a3900\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M340.0 250.0 L588.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M340.0 110.0 L340.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M357.7 115.1 L393.1 133.3 L428.6 151.3 L464.0 169.4 L499.4 187.7 L534.9 205.5 L570.3 223.2\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"357.7\" cy=\"115.1\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"393.1\" cy=\"133.3\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"428.6\" cy=\"151.3\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"464.0\" cy=\"169.4\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"499.4\" cy=\"187.7\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"534.9\" cy=\"205.5\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"570.3\" cy=\"223.2\" r=\"3.5\" fill=\"var(--amber)\"></circle><text x=\"40.0\" y=\"272.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">perceived lightness (OKLab L)</text></svg>", "caption": "Equal steps in a perceptual space look equal; equal steps in HSL do not. A sequential palette is only honest if a step of one class is the same visual step everywhere."}
```

Both ramps run from pale yellow to a dark olive in seven steps. Beneath each, the line plots how light
each step looks, measured as OKLab lightness. The left ramp takes **equal steps in HSL lightness**, and
its line bends: the first four steps are almost the same pale yellow, and the last three drop steeply.
A heatmap coloured with it would hide every difference among its lower values and exaggerate the ones
at the top. The right ramp takes **equal steps in OKLCH lightness**, and its line is straight.

Not every hue suffers as much. An HSL ramp of blue comes out nearly even, which is how a palette can
look fine in one colour and fail in the next.

## What this means in practice

You do not need to compute colours in OKLCH by hand. What you need is to know that:

- **good palettes are already built this way.** matplotlib's `viridis`, `cividis` and their relatives,
  the ColorBrewer palettes, and the defaults of most modern tools were designed in perceptual spaces
  and tested for even steps. Lesson 12 is about choosing among them.
- **a palette you make yourself should be checked**, by converting it to grey or to OKLab lightness, as
  the next section does, before it carries data.
- **HSL is fine for picking a hue**, and not for deciding how light colours are.
