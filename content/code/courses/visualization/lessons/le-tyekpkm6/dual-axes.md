---
title: Two axes, and why to avoid them
version: 1
---

A **dual-axis chart** draws two series on one plot with two vertical scales: one on the left, one on
the right. It looks like an efficient way to show two related things. It is the line chart's most
dangerous form, because it gives the person drawing it control over the one thing the reader will
look at first: **where and whether the lines cross.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 660 300\" role=\"img\" data-fig=\"l04-dual\" aria-label=\"Two dual-axis charts of the same two series, Southeast's and North's monthly orders. On the left, Southeast's axis runs from 0 to 9,000 and North's from 0 to 9,000 as well, and North is a thin line near the bottom. On the right, Southeast's axis runs from 4,000 to 9,000 and North's from 400 to 1,500, and North's line climbs steeply past Southeast's, crossing it in mid 2025. Nothing in the data changed.\"><text x=\"170.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">one honest choice</text><path d=\"M60.0 40.0 L60.0 220.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M280.0 40.0 L280.0 220.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M60.0 220.0 L280.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"54.0\" y=\"220.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--phosphor)\">0</text><text x=\"54.0\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--phosphor)\">4,500</text><text x=\"54.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--phosphor)\">9,000</text><text x=\"286.0\" y=\"220.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--amber)\">0</text><text x=\"286.0\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--amber)\">4,500</text><text x=\"286.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--amber)\">9,000</text><path d=\"M60.0 116.6 L69.6 115.4 L79.1 114.7 L88.7 111.6 L98.3 110.7 L107.8 116.4 L117.4 104.5 L127.0 105.8 L136.5 109.1 L146.1 103.8 L155.7 113.3 L165.2 64.8 L174.8 93.8 L184.3 103.4 L193.9 93.9 L203.5 100.8 L213.0 99.8 L222.6 89.0 L232.2 95.0 L241.7 90.5 L251.3 90.6 L260.9 88.4 L270.4 87.5 L280.0 56.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" stroke-linejoin=\"round\"></path><path d=\"M60.0 211.1 L69.6 210.0 L79.1 209.3 L88.7 209.1 L98.3 208.4 L107.8 208.5 L117.4 208.0 L127.0 207.7 L136.5 206.9 L146.1 207.2 L155.7 204.9 L165.2 201.2 L174.8 204.5 L184.3 204.7 L193.9 203.7 L203.5 202.3 L213.0 202.1 L222.6 200.7 L232.2 201.0 L241.7 199.3 L251.3 198.4 L260.9 196.9 L270.4 198.2 L280.0 191.1\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"5 3\" stroke-linejoin=\"round\"></path><text x=\"500.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">another choice, same data</text><path d=\"M390.0 40.0 L390.0 220.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M610.0 40.0 L610.0 220.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M390.0 220.0 L610.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"384.0\" y=\"220.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--phosphor)\">4,000</text><text x=\"384.0\" y=\"130.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--phosphor)\">6,500</text><text x=\"384.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--phosphor)\">9,000</text><text x=\"616.0\" y=\"220.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--amber)\">400</text><text x=\"616.0\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--amber)\">950</text><text x=\"616.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--amber)\">1,500</text><path d=\"M390.0 178.0 L399.6 175.6 L409.1 174.5 L418.7 169.0 L428.3 167.3 L437.8 177.4 L447.4 156.1 L457.0 158.4 L466.5 164.4 L476.1 154.8 L485.7 171.9 L495.2 84.6 L504.8 136.9 L514.3 154.2 L523.9 137.0 L533.5 149.4 L543.0 147.6 L552.6 128.3 L562.2 139.0 L571.7 130.8 L581.3 131.0 L590.9 127.1 L600.4 125.5 L610.0 68.7\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" stroke-linejoin=\"round\"></path><path d=\"M390.0 212.6 L399.6 203.8 L409.1 198.1 L418.7 196.1 L428.3 190.7 L437.8 191.5 L447.4 187.1 L457.0 185.0 L466.5 177.9 L476.1 180.7 L485.7 161.9 L495.2 131.6 L504.8 158.6 L514.3 160.3 L523.9 152.1 L533.5 140.5 L543.0 138.8 L552.6 127.9 L562.2 130.3 L571.7 116.1 L581.3 108.4 L590.9 96.6 L600.4 107.4 L610.0 49.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"5 3\" stroke-linejoin=\"round\"></path><path d=\"M60.0 270.0 L80.0 270.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"86.0\" y=\"270.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Southeast (left axis)</text><path d=\"M260.0 270.0 L280.0 270.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"5 3\"></path><text x=\"286.0\" y=\"270.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">North (right axis)</text></svg>", "caption": "With two axes, whoever draws the chart sets where the lines cross and how steep each one looks. The crossing on the right means nothing at all."}
```

Both charts show the same data: Southeast's monthly orders, between 5,168 and 8,202, and North's,
between 445 and 1,445. On the left, both axes run from 0 to 9,000, and North is a thin line near the
floor, which is the truth about the two regions' sizes. On the right, Southeast's axis runs from
4,000 to 9,000 and North's from 400 to 1,500. Now North **climbs past Southeast** in 2025.

That crossing is not in the data. **It is a consequence of two axis ranges somebody picked**, and a
different pair would move it earlier, later, or remove it. The same is true of the slopes: either
line can be made steep or flat by its own axis.

## What software does by default

matplotlib, asked for a second axis with `twinx`, fits each axis to its own series. Both lines
then fill the full height of the chart:

```
ana@vm:~/viz$ .venv/bin/python dual.py
left axis:  [5016, 8354]
right axis: [395, 1495]
```

North's line spans from 395 to 1,495 and Southeast's from 5,016 to 8,354, and on the page they cover
the same height. **A region with between a twelfth and a sixth of the orders is drawn as tall as the largest.** Spreadsheets
do the same. The default dual axis is a chart that says two series are the same size.

## What to do instead

- **Index both to a common start.** Set the first month to 100 for each series and draw them on one
  axis. That compares growth honestly, and it is the next section.
- **Draw two charts**, one above the other, sharing the horizontal time axis. Each has its own
  vertical scale, labelled clearly, and nobody reads a crossing into two separate panels.
- **Plot one against the other.** If the question is whether two quantities move together, put one on
  each axis of a scatterplot (lesson 6).

## The one case people defend

Two series in **different units**, such as orders and average delivery time, cannot share an axis
at all, and a dual axis is sometimes drawn for that reason. Even then two stacked panels do the job
better, because the reader still cannot help reading the crossings, and in different units a
crossing is meaningless by definition.
