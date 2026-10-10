---
title: Better in every part, worse in total
version: 1
---

Caio compares the stores' home deliveries every month, and in February 2026 the comparison said
Savassi delivered on time 86% of the time and Contagem 79%. Bruno Teixeira, who manages Contagem,
was asked to visit Savassi and learn how they did it. **Contagem was better than Savassi at every
kind of delivery it makes, and worse in the total.** That is not a contradiction in the data. It is
a result with a name, Simpson's paradox, and it appears whenever two groups are compared on a total
that mixes parts in different proportions.

## The two stores

Each store delivers two kinds of thing: furniture, which needs two people, a van and an agreed time
slot, and small parcels, which go with a carrier. Type February's deliveries into a new sheet from
A1:

| | A | B | C | D |
|---|---|---|---|---|
| 1 | Store | Kind | Deliveries | On time |
| 2 | Contagem | furniture | 400 | 300 |
| 3 | Contagem | parcels | 100 | 95 |
| 4 | Savassi | furniture | 100 | 70 |
| 5 | Savassi | parcels | 400 | 360 |

In E1 type `Rate`, in E2 the on-time rate, and copy it down to E5:

```localised
=ROUND(D2/C2*100,1)      75
```

The column reads **75 and 95 for Contagem, 70 and 90 for Savassi**. Contagem is five points ahead
with furniture and five points ahead with parcels. Now each store's total, all deliveries together:

```localised
=ROUND((D2+D3)/(C2+C3)*100,1)      79
=ROUND((D4+D5)/(C4+C5)*100,1)      86
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Bars of on-time delivery rate for two stores. Furniture: Contagem 75%, Savassi 70%. Parcels: Contagem 95%, Savassi 90%. All deliveries: Contagem 79%, Savassi 86%. Contagem is ahead in each kind and behind overall. Under the bars, the mix: 80% of Contagem's deliveries are furniture, against 20% of Savassi's.\" data-fig=\"l12-simpson\"><path d=\"M60.0 100.0 H120.0 V250.0 H60.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"90.0\" y=\"92.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">75%</text><path d=\"M134.0 110.0 H194.0 V250.0 H134.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"164.0\" y=\"102.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">70%</text><text x=\"127.0\" y=\"272.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">furniture</text><path d=\"M280.0 60.0 H340.0 V250.0 H280.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"310.0\" y=\"52.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">95%</text><path d=\"M354.0 70.0 H414.0 V250.0 H354.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"384.0\" y=\"62.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">90%</text><text x=\"347.0\" y=\"272.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">parcels</text><path d=\"M500.0 92.0 H560.0 V250.0 H500.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"530.0\" y=\"84.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">79%</text><path d=\"M574.0 78.0 H634.0 V250.0 H574.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"604.0\" y=\"70.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">86%</text><text x=\"567.0\" y=\"272.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">all deliveries</text><path d=\"M40.0 250.0 L700.0 250.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><path d=\"M467.0 30.0 L467.0 280.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></path><path d=\"M60.0 290.0 H74.0 V304.0 H60.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"80.0\" y=\"302.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Contagem: 80% of its deliveries are furniture</text><path d=\"M400.0 290.0 H414.0 V304.0 H400.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"420.0\" y=\"302.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Savassi: 20% furniture</text></svg>", "caption": "Contagem is ahead in each kind of delivery and behind in the total. The total is an average of the two kinds, weighted by a mix the two stores do not share."}
```

## Where the seven points come from

Furniture is the hard kind for both stores, and Contagem makes far more of it. It is the store next to
the warehouse with the largest floor (lesson 2), and it sells the sofas:

```localised
=ROUND(C2/(C2+C3)*100,0)      80
=ROUND(C4/(C4+C5)*100,0)      20
```

**80% of Contagem's deliveries are furniture, against 20% of Savassi's.** A store's total is an
average of its two rates, weighted by its own mix. Contagem's total leans towards its furniture rate
of 75, and Savassi's leans towards its parcel rate of 90. The gap between the totals measures the
mix, not the service. Sending Bruno to Savassi would have sent the better store to learn from the
worse one.

## Comparing like with like

The fix is to compare the two stores on the same mix. The simplest is to give each kind the same
weight, as if each store delivered half furniture and half parcels:

```localised
=ROUND((E2+E3)/2,1)      85
=ROUND((E4+E5)/2,1)      80
```

On a common mix Contagem is ahead, 85 to 80, which is what the rows said all along. **Any common mix
gives Contagem the lead here, because it leads in every part**; which mix to choose matters when the
parts disagree, and the company-wide mix is the usual choice.

## When to suspect it

The paradox is not rare. It needs three things, and all three are common: groups that are compared
on a total, parts that differ a lot in difficulty, and groups whose mix of parts differs. Hospitals
compared on mortality while one takes the hardest cases, regions compared on default rates while one
lends more to new businesses, schools compared on pass rates with different intakes: each is this
table with other nouns. Lesson 19 meets it again in public health, where the part is age.

**Before ranking groups on a total, break it down by the part that is hardest to do well, and look at
the mix.** If a group wins every row and loses the total, the total is measuring the mix.
