---
title: Like-for-like: growth from the stores you already had
version: 1
---

Retail is the industry this course has been inside since lesson 1, so the four questions of lesson
17 have answers you have half met already. What this lesson adds is the part that belongs to
retail and to no other industry:

| lesson 17's question | in retail |
|---|---|
| the decisions made over and over | what to buy, how much, for which store, at what price, and what to promote |
| the indicators that serve them | like-for-like sales, sales per m², days of cover, sell-through, incremental orders, a supplier's on-time-in-full |
| the data, and what is odd about it | every sale is recorded to the item and the minute; **a sale that did not happen leaves no record at all** |
| the typical trap | crediting the stores, the campaign or the buyer with growth that came from somewhere else |

The four sections take one decision each: whether the stores are doing better, what is on the
shelf, whether a campaign worked and whether a supplier is reliable.

## The wrong question: did sales grow?

Varanda's stores sold R$ 82.39 million in 2025 against R$ 77.95 million in 2024. That is growth of
5.7%, and it is the number that went into the year-end email. **It says almost nothing about
whether the stores got better at selling**, because one of the nine did not trade for the whole of
2024. Ipatinga opened in July 2024: six months of sales in the first year, twelve in the second.

Retail's answer is **like-for-like** growth, also called same-store or comparable growth: the
growth of the stores that traded for the whole of both periods, and of nobody else. A new store
inflates total growth in its first full year for a reason that has nothing to do with selling
better, and a closed store deflates it. Comparing like with like takes both out.

## The sheet

Type the nine stores in a new sheet, in thousands of reais, with Ipatinga last:

| | A | B | C |
|---|---|---|---|
| 1 | Store | 2024 | 2025 |
| 2 | Savassi | 11520 | 11880 |
| 3 | Pampulha | 10610 | 10560 |
| 4 | Contagem | 12650 | 12480 |
| 5 | Betim | 8700 | 8840 |
| 6 | Nova Lima | 8980 | 9450 |
| 7 | Sete Lagoas | 6690 | 6720 |
| 8 | Divinópolis | 6540 | 6460 |
| 9 | Juiz de Fora | 8910 | 8960 |
| 10 | Ipatinga | 3350 | 7040 |

In D1 type `Growth %`, in D2 the growth of the first store, and copy it down to D10:

```localised
=ROUND((C2/B2-1)*100,1)      3.1
```

Then two totals. In A11 type `All stores`, and in A12 `Like-for-like`; the second sums only the
eight rows above Ipatinga:

```localised
=SUM(B2:B10)      77950
=SUM(C2:C10)      82390
=ROUND((C11/B11-1)*100,1)      5.7
=SUM(B2:B9)      74600
=SUM(C2:C9)      75350
=ROUND((C12/B12-1)*100,1)      1
```

**All stores grew 5.7%; like-for-like, they grew 1.0%.** Five of the eight comparable stores grew
and three shrank, Contagem among them at −1.3%. How much of the 5.7 points came from the new store
is its extra sales over the 2024 total:

```localised
=ROUND((C10-B10)/B11*100,1)      4.7
=ROUND((C12-B12)/B11*100,1)      1
```

Ipatinga's first full year is 4.7 of the 5.7 points. The other eight stores together are 1.0.

Look also at D10. **Ipatinga "grew" 110.1%**, and nothing about that number is true: it compares a
year with half a year. A store's growth in its first full year belongs in no ranking of stores, and
a report that lists it among the others will put it at the top every time.

## The rule has to be written down

"Traded for the whole of both periods" sounds obvious until the cases arrive. Each of these
happens at a retailer of Varanda's size within a few years:

- a store opens in the middle of the comparison period, as Ipatinga did;
- a store closes for six weeks of refurbishment, or for good;
- a store moves to a bigger building down the road;
- one year has more trading days than the other. 2024 was a leap year, with a 29 February.

Retailers settle these with a written rule, and the rules differ: some count a store as comparable
after twelve full months of trading, others after thirteen; some take a refurbished store out for
the months it was shut, others for the whole year. **The rule matters less than writing it down
and applying it the same way every year**, which is the definition of BI from lesson 1 applied to
one indicator. A like-for-like figure without its rule beside it is a number nobody can check.

The online shop raises the last question. It grew 5.8%, from R$ 14.75 million to R$ 15.61 million,
and it is not a store. Some retailers report like-for-like for the stores alone and the online
channel beside it; others fold the online shop in, on the argument that a customer who orders
online after seeing a sofa in Savassi was sold to by Savassi. Varanda's report keeps the two apart,
and says so in a footnote.

## What the 1.0% changes

Lesson 2 opened on Helena wanting to enlarge Contagem because it sells the most. Like-for-like
puts a second fact beside sales per m²: Contagem is the biggest store, and in 2025 it sold less
than the year before. Neither fact decides the question alone, but a board that saw only the 5.7%
would not have asked about either.
