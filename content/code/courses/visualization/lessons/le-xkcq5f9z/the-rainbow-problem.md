---
title: The rainbow problem
version: 1
---

For decades the default colour map of most scientific software was a **rainbow**: dark blue through
cyan, green, yellow and red. matplotlib's version is called `jet`, and it was the default until 2017.
It looks vivid and it misleads in three ways at once.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 620 270\" role=\"img\" data-fig=\"l12-rainbow\" aria-label=\"Two colour scales, each with its perceived lightness plotted beneath. The rainbow, matplotlib's jet, goes dark blue, bright cyan, green, yellow, red, dark red; its lightness rises to a peak in the middle at 0.92 and falls again, so the lowest and highest values both look dark. Viridis goes from dark purple to bright yellow, and its lightness climbs steadily from 0.29 to 0.92.\"><text x=\"40.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">jet (a rainbow)</text><rect x=\"40.0\" y=\"32.0\" width=\"34.0\" height=\"34.0\" rx=\"2\" fill=\"#000080\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"78.0\" y=\"32.0\" width=\"34.0\" height=\"34.0\" rx=\"2\" fill=\"#0028ff\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"116.0\" y=\"32.0\" width=\"34.0\" height=\"34.0\" rx=\"2\" fill=\"#00d4ff\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"154.0\" y=\"32.0\" width=\"34.0\" height=\"34.0\" rx=\"2\" fill=\"#7dff7a\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"192.0\" y=\"32.0\" width=\"34.0\" height=\"34.0\" rx=\"2\" fill=\"#ffe600\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"230.0\" y=\"32.0\" width=\"34.0\" height=\"34.0\" rx=\"2\" fill=\"#ff4700\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"268.0\" y=\"32.0\" width=\"34.0\" height=\"34.0\" rx=\"2\" fill=\"#800000\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M40.0 230.0 L302.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M40.0 96.0 L40.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M58.7 218.3 L96.1 184.8 L133.6 127.8 L171.0 112.8 L208.4 109.4 L245.9 152.9 L283.3 199.8\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"58.7\" cy=\"218.3\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"96.1\" cy=\"184.8\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"133.6\" cy=\"127.8\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"171.0\" cy=\"112.8\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"208.4\" cy=\"109.4\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"245.9\" cy=\"152.9\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"283.3\" cy=\"199.8\" r=\"3.5\" fill=\"var(--amber)\"></circle><text x=\"340.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">viridis</text><rect x=\"340.0\" y=\"32.0\" width=\"34.0\" height=\"34.0\" rx=\"2\" fill=\"#440154\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"378.0\" y=\"32.0\" width=\"34.0\" height=\"34.0\" rx=\"2\" fill=\"#443983\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"416.0\" y=\"32.0\" width=\"34.0\" height=\"34.0\" rx=\"2\" fill=\"#31688e\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"454.0\" y=\"32.0\" width=\"34.0\" height=\"34.0\" rx=\"2\" fill=\"#21918c\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"492.0\" y=\"32.0\" width=\"34.0\" height=\"34.0\" rx=\"2\" fill=\"#35b779\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"530.0\" y=\"32.0\" width=\"34.0\" height=\"34.0\" rx=\"2\" fill=\"#90d743\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"568.0\" y=\"32.0\" width=\"34.0\" height=\"34.0\" rx=\"2\" fill=\"#fde725\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M340.0 230.0 L602.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M340.0 96.0 L340.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M358.7 214.9 L396.1 196.5 L433.6 179.8 L471.0 163.0 L508.4 147.9 L545.9 129.5 L583.3 109.4\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><circle cx=\"358.7\" cy=\"214.9\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"396.1\" cy=\"196.5\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"433.6\" cy=\"179.8\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"471.0\" cy=\"163.0\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"508.4\" cy=\"147.9\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"545.9\" cy=\"129.5\" r=\"3.5\" fill=\"var(--amber)\"></circle><circle cx=\"583.3\" cy=\"109.4\" r=\"3.5\" fill=\"var(--amber)\"></circle><text x=\"40.0\" y=\"252.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">perceived lightness</text></svg>", "caption": "A rainbow is brightest in the middle, so values near the middle look important and the two ends look alike. Viridis gets lighter at every step, so lighter always means more."}
```

```
ana@vm:~/viz$ .venv/bin/python palettes.py viridis cividis jet RdBu
viridis  #440154 #443983 #31688e #21918c #35b779 #90d743 #fde725
            0.29    0.40    0.50    0.60    0.69    0.80    0.92
cividis  #00224e #2a3f6d #575d6d #7d7c78 #a59c74 #d2c060 #fee838
            0.26    0.38    0.48    0.59    0.69    0.80    0.92
jet      #000080 #0028ff #00d4ff #7dff7a #ffe600 #ff4700 #800000
            0.27    0.47    0.81    0.90    0.92    0.66    0.38
RdBu     #67001f #c94741 #f7b799 #f6f7f7 #a7d0e4 #3783bb #053061
            0.33    0.58    0.83    0.97    0.83    0.59    0.31
```

The second line under each name is the OKLab lightness of each of seven samples, from the lowest value
to the highest. Read jet's:

1. **Its lightness goes up and then down**: 0.27 at the low end, a peak of 0.92 in the middle, 0.38 at
   the high end. The brightest colours sit on middling values, so **the middle of the data draws the
   eye**, and the lowest and highest values both look dark.
2. **Its hue boundaries invent edges.** The eye sees "the yellow region" and "the cyan region" as
   separate bands with sharp borders, though the values change smoothly across them. A rainbow map of
   delivery times would show contours that are not in the data.
3. **It fails for colour blindness.** Its middle relies on telling green from yellow and red, the
   distinctions most often lost.

viridis's line climbs steadily from 0.29 to 0.92, and cividis's almost identically. RdBu, a diverging
map, peaks at 0.97 in the middle by design, which is what a diverging palette is for: **its middle is
meant to be the lightest point.** On jet, the same shape is an accident.

## The spreadsheet's version

Spreadsheets offer a **red, yellow and green** colour scale first in their conditional formatting. It
is a short rainbow with the same problems, and it adds a judgement: green reads as good and red as
bad, which is wrong for most quantities. Use a two-colour scale from white to one colour for amounts,
and a three-colour scale with a white middle, set on the value that means something, for differences.
