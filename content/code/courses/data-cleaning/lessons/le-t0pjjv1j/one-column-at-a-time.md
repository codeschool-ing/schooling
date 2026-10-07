---
title: One column at a time
version: 1
---

The first question for any column is its shape: where the middle is, how wide the spread, how long
the tails. `describe` gives the numbers, and the skew says which way the tail runs:

```
ana@lab:~/clean$ python -c "from explore import delivered as d; print(d[['total', 'items']].describe().round(2).to_string()); print(round(d['total'].skew(), 1), round(d['items'].skew(), 1))"
          total     items
count  26510.00  26510.00
mean      94.06      3.47
std      248.91      1.64
min        0.00      1.00
25%       32.70      2.00
50%       57.60      3.00
75%      106.45      5.00
max    26928.50     13.00
64.0 0.3
```

**The two columns have very different shapes.** Items per order, the number of lines, runs from 1
to 13 with a mean of 3.47 and a median of 3, and a skew of 0.3: nearly symmetrical, a column whose
mean is a fair summary. The total runs from 0 to R$ 26,928.50, with a median of R$ 57.60 and a mean
of R$ 94.06, and a skew of 64. **When the mean is far above the median, the mean is describing the
tail**: half the orders are under R$ 57.60, and an "average order of R$ 94" would describe almost
nobody. Lesson 12's logarithm is the way to look at it; here it is enough to report the median and
the quartiles, R$ 32.70 and R$ 106.45.

A column of times has a shape too, and counting by hour is the simplest look:

```
ana@lab:~/clean$ python -c "from explore import delivered as d; print(d.groupby('hour').size().to_string()); print(round(d['hour'].mean(), 1))"
hour
7      503
8      995
9     1576
10    2011
11    2021
12    1781
13    1512
14    1571
15    1638
16    1513
17    1771
18    2332
19    2660
20    2331
21    1495
22     800
15.0
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l15-hours\" aria-label=\"A bar chart of delivered orders by the hour they were placed, from 7 to 22 o'clock. The bars rise to a plateau at 10 and 11, dip after lunch, and rise again to the tallest bar at 19 with 2,660 orders. The mean hour, 15, falls in the dip between the two waves.\"><path d=\"M70.0 230.0 L70.0 197.3 L108.8 197.3 L108.8 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M108.8 230.0 L108.8 165.4 L147.5 165.4 L147.5 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M147.5 230.0 L147.5 127.7 L186.2 127.7 L186.2 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M186.2 230.0 L186.2 99.4 L225.0 99.4 L225.0 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M225.0 230.0 L225.0 98.8 L263.8 98.8 L263.8 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M263.8 230.0 L263.8 114.4 L302.5 114.4 L302.5 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M302.5 230.0 L302.5 131.8 L341.2 131.8 L341.2 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M341.2 230.0 L341.2 128.0 L380.0 128.0 L380.0 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M380.0 230.0 L380.0 123.6 L418.8 123.6 L418.8 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M418.8 230.0 L418.8 131.8 L457.5 131.8 L457.5 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M457.5 230.0 L457.5 115.0 L496.2 115.0 L496.2 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M496.2 230.0 L496.2 78.6 L535.0 78.6 L535.0 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M535.0 230.0 L535.0 57.3 L573.8 57.3 L573.8 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M573.8 230.0 L573.8 78.6 L612.5 78.6 L612.5 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M612.5 230.0 L612.5 132.9 L651.2 132.9 L651.2 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M651.2 230.0 L651.2 178.1 L690.0 178.1 L690.0 230.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><path d=\"M70.0 230.0 L690.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M89.4 230.0 L89.4 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"89.4\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">7</text><path d=\"M128.1 230.0 L128.1 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"128.1\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8</text><path d=\"M166.9 230.0 L166.9 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"166.9\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">9</text><path d=\"M205.6 230.0 L205.6 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"205.6\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10</text><path d=\"M244.4 230.0 L244.4 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"244.4\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">11</text><path d=\"M283.1 230.0 L283.1 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"283.1\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">12</text><path d=\"M321.9 230.0 L321.9 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"321.9\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">13</text><path d=\"M360.6 230.0 L360.6 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"360.6\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">14</text><path d=\"M399.4 230.0 L399.4 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"399.4\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">15</text><path d=\"M438.1 230.0 L438.1 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"438.1\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16</text><path d=\"M476.9 230.0 L476.9 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"476.9\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">17</text><path d=\"M515.6 230.0 L515.6 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"515.6\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">18</text><path d=\"M554.4 230.0 L554.4 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"554.4\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">19</text><path d=\"M593.1 230.0 L593.1 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"593.1\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><path d=\"M631.9 230.0 L631.9 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"631.9\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">21</text><path d=\"M670.6 230.0 L670.6 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"670.6\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">22</text><text x=\"380.0\" y=\"261.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">hour of the day</text><path d=\"M70.0 40.0 L70.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M66.0 230.0 L70.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M70.0 165.1 L690.0 165.1\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 165.1 L70.0 165.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"165.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1,000</text><path d=\"M70.0 100.1 L690.0 100.1\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 100.1 L70.0 100.1\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"100.1\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2,000</text><text x=\"70.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">orders</text><path d=\"M399.4 230.0 L399.4 52.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"399.4\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">mean hour</text></svg>", "caption": "Two waves, before lunch and after dinner. The average hour is arithmetically right and describes neither of them."}
```

**Two waves**: one building through the morning to a plateau at 10 and 11 o'clock, and a taller one
in the evening, peaking at 19 with 2,660 orders. The quiet hour after lunch sits between them. The mean
hour, on the last line, is 15.0: "orders arrive at around 3 in the afternoon" is arithmetically
true and lands between the waves, at an hour typical of nothing.

That is the general lesson of looking at one column: **a summary number is only honest when the
shape is simple**. When the shape has two humps or a long tail, the shape is the finding, and it
has to be shown rather than averaged.
