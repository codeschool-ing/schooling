---
title: Shared or free scales
version: 1
---

The most important decision in a grid of small charts is whether the panels **share one vertical
scale** or each get their own.

The previous figure shared one scale, 0 to 9,000. Here is the same grid with each panel fitted to its
own data.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 180\" role=\"img\" data-fig=\"l10-free\" aria-label=\"The five regional series again as five small charts, but each panel now has its own vertical scale fitted to its own data, from about 4,900 to 8,600 for Southeast down to about 400 to 1,500 for North. Every line fills its panel, and the five look almost the same size.\"><rect x=\"50.0\" y=\"40.0\" width=\"100.0\" height=\"120.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M50.0 151.6 L54.3 149.6 L58.7 148.5 L63.0 143.5 L67.4 142.0 L71.7 151.2 L76.1 132.0 L80.4 134.1 L84.8 139.4 L89.1 130.8 L93.5 146.2 L97.8 67.6 L102.2 114.7 L106.5 130.2 L110.9 114.8 L115.2 125.9 L119.6 124.3 L123.9 106.9 L128.3 116.6 L132.6 109.2 L137.0 109.4 L141.3 105.8 L145.7 104.4 L150.0 53.3\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" stroke-linejoin=\"round\"></path><text x=\"100.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Southeast</text><text x=\"46.0\" y=\"40.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">8,600</text><text x=\"46.0\" y=\"160.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">4,900</text><rect x=\"178.0\" y=\"40.0\" width=\"100.0\" height=\"120.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M178.0 155.1 L182.3 156.7 L186.7 152.0 L191.0 149.9 L195.4 148.3 L199.7 142.6 L204.1 141.7 L208.4 141.6 L212.8 133.9 L217.1 132.6 L221.5 126.8 L225.8 104.9 L230.2 129.6 L234.5 120.8 L238.9 122.7 L243.2 114.6 L247.6 112.6 L251.9 107.6 L256.3 107.8 L260.6 100.8 L265.0 100.1 L269.3 89.9 L273.7 93.9 L278.0 48.7\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" stroke-linejoin=\"round\"></path><text x=\"228.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Northeast</text><text x=\"174.0\" y=\"41.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">5,100</text><text x=\"174.0\" y=\"161.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">1,700</text><rect x=\"306.0\" y=\"40.0\" width=\"100.0\" height=\"120.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M306.0 147.0 L310.3 151.9 L314.7 140.6 L319.0 146.4 L323.4 141.4 L327.7 136.6 L332.1 155.0 L336.4 135.5 L340.8 128.5 L345.1 133.9 L349.5 131.3 L353.8 94.3 L358.2 130.7 L362.5 120.4 L366.9 123.1 L371.2 111.3 L375.6 124.2 L379.9 106.4 L384.3 115.9 L388.6 109.1 L393.0 102.4 L397.3 109.5 L401.7 106.5 L406.0 50.2\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" stroke-linejoin=\"round\"></path><text x=\"356.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">South</text><text x=\"302.0\" y=\"39.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">4,300</text><text x=\"302.0\" y=\"159.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">1,900</text><rect x=\"434.0\" y=\"40.0\" width=\"100.0\" height=\"120.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M434.0 155.5 L438.3 147.7 L442.7 152.4 L447.0 148.8 L451.4 144.1 L455.7 142.8 L460.1 147.1 L464.4 140.2 L468.8 136.1 L473.1 137.3 L477.5 132.7 L481.8 100.2 L486.2 125.8 L490.5 127.4 L494.9 117.9 L499.2 128.1 L503.6 105.3 L507.9 113.2 L512.3 111.4 L516.6 107.9 L521.0 103.2 L525.3 115.7 L529.7 99.7 L534.0 49.8\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" stroke-linejoin=\"round\"></path><text x=\"484.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Centre-West</text><text x=\"430.0\" y=\"35.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">2,100</text><text x=\"430.0\" y=\"155.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">900</text><rect x=\"562.0\" y=\"40.0\" width=\"100.0\" height=\"120.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M562.0 157.6 L566.3 151.6 L570.7 147.8 L575.0 146.5 L579.4 142.9 L583.7 143.4 L588.1 140.5 L592.4 139.0 L596.8 134.3 L601.1 136.2 L605.5 123.6 L609.8 103.3 L614.2 121.4 L618.5 122.5 L622.9 117.0 L627.2 109.2 L631.6 108.1 L635.9 100.8 L640.3 102.4 L644.6 92.9 L649.0 87.7 L653.3 79.8 L657.7 87.1 L662.0 47.9\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" stroke-linejoin=\"round\"></path><text x=\"612.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">North</text><text x=\"558.0\" y=\"41.9\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">1,500</text><text x=\"558.0\" y=\"162.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">400</text></svg>", "caption": "Each panel scaled to itself. The shapes are easier to compare, and the sizes have disappeared: North looks as big as Southeast."}
```

Every line now fills its panel, and the shapes are easier to see: North's growth, which was a thin
rising line near the floor, is now a clear climb, and its December spikes are visible. The price is
that **the sizes have disappeared**. North looks as big as Southeast, though Southeast sells more than
five times as much.

## Which to choose

| the reader's question | scales |
|---|---|
| which region is biggest, and by how much? | shared |
| do they all follow the same pattern? | free |
| which grew fastest, in percentage terms? | shared, after indexing to 100 (lesson 4) |
| what happened in each one, in detail? | free |

**Shared is the safer default**, because a reader will compare the heights of lines in neighbouring
panels whatever the chart says. When the scales are free, **say so on the chart**, in words, and print
each panel's axis values, as the figure does. A grid of free scales without labels is a grid of dual
axes (lesson 4), repeated.

## A middle way

When the series differ by a factor of ten or more, a shared **logarithmic** scale (lesson 6) keeps
every panel comparable and still shows the small ones' shape. Indexing every series to 100 does the
same for growth.
