---
title: The z-score
version: 1
---

A **z-score** measures a value in standard deviations from the mean:

```localised
z = (value − mean) ÷ standard deviation
```

A z-score of 0 is the mean itself. A z of 2 is two standard deviations above it; a z of −1.5 is one and a half below.

## Comparing across scales

A z-score has no units, so it compares values that live on different scales. A 52-minute delivery, when the twelve deliveries have a mean of 38.96 and a standard deviation of 9.77, has z = (52 − 38.96) ÷ 9.77 = **1.33**. A bag of 1011 g, with mean 1003 and standard deviation 6, also has z = **1.33**. The delivery and the bag are equally unusual within their own data, which no comparison of minutes with grams could say.

## Turning a z-score into a probability

For a normal distribution, the z-score turns any question into a question about **one** curve: the **standard normal**, with mean 0 and standard deviation 1. Every normal curve is that curve, stretched and shifted.

What share of bags weigh less than 995 g?

1. The z-score: (995 − 1003) ÷ 6 = **−1.33**.
2. The area to the left of z = −1.33 under the standard normal curve: **0.0912**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 620 250\" role=\"img\" data-fig=\"l08-z-area\" aria-label=\"The normal curve of bag weights, mean 1003 g and standard deviation 6 g, with the area left of 995 g shaded. 995 g is 1.33 standard deviations below the mean, and the shaded area is 0.0912, about 9% of the bags.\"><path d=\"M40.0 190.0 L41.1 189.9 L42.3 189.9 L43.4 189.9 L44.6 189.9 L45.7 189.9 L46.9 189.9 L48.0 189.9 L49.2 189.9 L50.3 189.9 L51.5 189.9 L52.6 189.9 L53.8 189.9 L54.9 189.9 L56.0 189.9 L57.2 189.9 L58.3 189.9 L59.5 189.9 L60.6 189.8 L61.8 189.8 L62.9 189.8 L64.1 189.8 L65.2 189.8 L66.4 189.8 L67.5 189.8 L68.6 189.8 L69.8 189.8 L70.9 189.7 L72.1 189.7 L73.2 189.7 L74.4 189.7 L75.5 189.7 L76.7 189.6 L77.8 189.6 L79.0 189.6 L80.1 189.6 L81.3 189.6 L82.4 189.5 L83.5 189.5 L84.7 189.5 L85.8 189.4 L87.0 189.4 L88.1 189.4 L89.3 189.3 L90.4 189.3 L91.6 189.3 L92.7 189.2 L93.9 189.2 L95.0 189.1 L96.1 189.1 L97.3 189.1 L98.4 189.0 L99.6 188.9 L100.7 188.9 L101.9 188.8 L103.0 188.8 L104.2 188.7 L105.3 188.6 L106.5 188.6 L107.6 188.5 L108.8 188.4 L109.9 188.3 L111.0 188.2 L112.2 188.2 L113.3 188.1 L114.5 188.0 L115.6 187.9 L116.8 187.8 L117.9 187.7 L119.1 187.5 L120.2 187.4 L121.4 187.3 L122.5 187.2 L123.6 187.0 L124.8 186.9 L125.9 186.7 L127.1 186.6 L128.2 186.4 L129.4 186.3 L130.5 186.1 L131.7 185.9 L132.8 185.7 L134.0 185.5 L135.1 185.3 L136.2 185.1 L137.4 184.9 L138.5 184.7 L139.7 184.5 L140.8 184.2 L142.0 184.0 L143.1 183.7 L144.3 183.5 L145.4 183.2 L146.6 182.9 L147.7 182.6 L148.9 182.3 L150.0 182.0 L151.1 181.7 L152.3 181.3 L153.4 181.0 L154.6 180.6 L155.7 180.2 L156.9 179.9 L158.0 179.5 L159.2 179.1 L160.3 178.6 L161.5 178.2 L162.6 177.8 L163.7 177.3 L164.9 176.8 L166.0 176.3 L167.2 175.8 L168.3 175.3 L169.5 174.8 L170.6 174.2 L171.8 173.7 L172.9 173.1 L174.1 172.5 L175.2 171.9 L176.4 171.3 L177.5 170.7 L178.6 170.0 L179.8 169.3 L180.9 168.7 L182.1 168.0 L183.2 167.2 L184.4 166.5 L185.5 165.8 L186.7 165.0 L187.8 164.2 L189.0 163.4 L190.1 162.6 L191.3 161.7 L192.4 160.9 L193.5 160.0 L194.7 159.1 L195.8 158.2 L197.0 157.3 L198.1 156.3 L199.3 155.4 L200.4 154.4 L201.6 153.4 L202.7 152.4 L203.9 151.3 L205.0 150.3 L206.1 149.2 L207.3 148.1 L208.4 147.0 L209.6 145.9 L210.7 144.8 L211.9 143.6 L213.0 142.5 L214.2 141.3 L215.3 140.1 L216.5 138.9 L217.6 137.6 L218.8 136.4 L219.9 135.1 L221.0 133.9 L222.2 132.6 L223.3 131.3 L223.3 190.0 L40.0 190.0 Z\" stroke=\"none\" stroke-width=\"0\" fill=\"var(--amber)\" fill-opacity=\"0.55\"></path><path d=\"M40.0 190.0 L43.4 189.9 L46.9 189.9 L50.3 189.9 L53.8 189.9 L57.2 189.9 L60.6 189.8 L64.1 189.8 L67.5 189.8 L70.9 189.7 L74.4 189.7 L77.8 189.6 L81.3 189.6 L84.7 189.5 L88.1 189.4 L91.6 189.3 L95.0 189.1 L98.4 189.0 L101.9 188.8 L105.3 188.6 L108.8 188.4 L112.2 188.2 L115.6 187.9 L119.1 187.5 L122.5 187.2 L125.9 186.7 L129.4 186.3 L132.8 185.7 L136.2 185.1 L139.7 184.5 L143.1 183.7 L146.6 182.9 L150.0 182.0 L153.4 181.0 L156.9 179.9 L160.3 178.6 L163.7 177.3 L167.2 175.8 L170.6 174.2 L174.1 172.5 L177.5 170.7 L180.9 168.7 L184.4 166.5 L187.8 164.2 L191.3 161.7 L194.7 159.1 L198.1 156.3 L201.6 153.4 L205.0 150.3 L208.4 147.0 L211.9 143.6 L215.3 140.1 L218.8 136.4 L222.2 132.6 L225.6 128.6 L229.1 124.6 L232.5 120.5 L235.9 116.3 L239.4 112.0 L242.8 107.7 L246.2 103.4 L249.7 99.0 L253.1 94.7 L256.6 90.5 L260.0 86.3 L263.4 82.2 L266.9 78.2 L270.3 74.3 L273.7 70.7 L277.2 67.2 L280.6 63.9 L284.1 60.9 L287.5 58.1 L290.9 55.6 L294.4 53.4 L297.8 51.5 L301.2 50.0 L304.7 48.7 L308.1 47.9 L311.6 47.3 L315.0 47.1 L318.4 47.3 L321.9 47.9 L325.3 48.7 L328.8 50.0 L332.2 51.5 L335.6 53.4 L339.1 55.6 L342.5 58.1 L345.9 60.9 L349.4 63.9 L352.8 67.2 L356.3 70.7 L359.7 74.3 L363.1 78.2 L366.6 82.2 L370.0 86.3 L373.4 90.5 L376.9 94.7 L380.3 99.0 L383.8 103.4 L387.2 107.7 L390.6 112.0 L394.1 116.3 L397.5 120.5 L400.9 124.6 L404.4 128.6 L407.8 132.6 L411.2 136.4 L414.7 140.1 L418.1 143.6 L421.6 147.0 L425.0 150.3 L428.4 153.4 L431.9 156.3 L435.3 159.1 L438.7 161.7 L442.2 164.2 L445.6 166.5 L449.1 168.7 L452.5 170.7 L455.9 172.5 L459.4 174.2 L462.8 175.8 L466.3 177.3 L469.7 178.6 L473.1 179.9 L476.6 181.0 L480.0 182.0 L483.4 182.9 L486.9 183.7 L490.3 184.5 L493.8 185.1 L497.2 185.7 L500.6 186.3 L504.1 186.7 L507.5 187.2 L510.9 187.5 L514.4 187.9 L517.8 188.2 L521.2 188.4 L524.7 188.6 L528.1 188.8 L531.6 189.0 L535.0 189.1 L538.4 189.3 L541.9 189.4 L545.3 189.5 L548.7 189.6 L552.2 189.6 L555.6 189.7 L559.1 189.7 L562.5 189.8 L565.9 189.8 L569.4 189.8 L572.8 189.9 L576.2 189.9 L579.7 189.9 L583.1 189.9 L586.6 189.9 L590.0 190.0\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><path d=\"M40.0 190.0 L590.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M108.8 190.0 L108.8 194.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"108.8\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">985</text><path d=\"M177.5 190.0 L177.5 194.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"177.5\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">991</text><path d=\"M246.2 190.0 L246.2 194.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"246.2\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">997</text><path d=\"M315.0 190.0 L315.0 194.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"315.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1003</text><path d=\"M383.8 190.0 L383.8 194.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"383.8\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1009</text><path d=\"M452.5 190.0 L452.5 194.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"452.5\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1015</text><path d=\"M521.2 190.0 L521.2 194.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"521.2\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1021</text><text x=\"315.0\" y=\"221.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">weight of a bag, in grams</text><path d=\"M223.3 190.0 L223.3 60.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"223.3\" y=\"52.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">z = −1.33</text><text x=\"120.2\" y=\"137.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">area 0.0912</text></svg>", "caption": "A probability under a continuous curve is an area. Turn the weight into a z-score, and one table, or one formula, gives the area for any normal curve."}
```

About 9% of bags weigh under 995 g. Before spreadsheets, the second step was read from a printed table of the standard normal; now it is one function:

```localised
=NORM.DIST(995, 1003, 6, TRUE)      0.0912112197258679
```

`NORM.DIST` takes the value, the mean and the standard deviation and does the standardising itself. `TRUE` asks for the area to the left, as in the binomial.

## The other direction

Sometimes the question runs backwards: which weight do 99% of bags exceed? Now the area is known, 0.01 to the left, and the value is wanted. The standard normal puts 1% to the left of z = −2.33, so the weight is 1003 − 2.33 × 6 = **989.04 g**.

```localised
=NORM.INV(0.01, 1003, 6)      989.041912755755
```

If the label promises 990 g and the machine runs at a mean of 1003 g with a standard deviation of 6 g, about 1.5% of bags come in under the label: the z-score of 990 g is −2.17. Moving the mean up, or reducing the standard deviation, are the two ways to fix that, and the z-score says how much of either is needed.

## A z-score does not need a normal curve

Computing a z-score needs only a mean and a standard deviation, and it is meaningful for any data. Turning it into a probability is what needs the normal curve. A z of 1.33 is "1.33 standard deviations above the mean" for the baskets too, but the normal table's 9% would be wrong for them, because their shape is not normal.
