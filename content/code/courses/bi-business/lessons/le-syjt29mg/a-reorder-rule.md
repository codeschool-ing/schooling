---
title: A reorder rule
version: 1
---

The warehouse in Contagem ships garden-hose reels to the nine stores and to online customers. Caio
Barreto, the operations director, wants a rule his team can follow without asking anybody: **when the
stock falls to a certain number, order more.** That number is the reorder point, and it is the
simplest prescriptive analysis there is.

## The idea

An order takes time to arrive, so it has to be placed while there is still enough stock to cover
the wait. If the warehouse ships 18 reels a day and the supplier takes 7 days, an order placed with
126 reels on the shelf arrives just as the last one leaves, but only if nothing goes wrong. Deliveries
run late, and some days sell more than others. So the rule adds a cushion, the **safety stock**:

reorder point = average daily demand × (lead time + safety days)

The safety days are a choice, and Caio made it from the record: in the last year, the supplier's
latest delivery came four days late. Four days of safety covers the worst lateness seen so far.

## In the sheet

Add a sheet. Type the reels shipped on 14 days of September 2025, from A1:

| | A | B |
|---|---|---|
| 1 | Day | Reels |
| 2 | 1 | 15 |
| 3 | 2 | 19 |
| 4 | 3 | 17 |
| 5 | 4 | 22 |
| 6 | 5 | 16 |
| 7 | 6 | 18 |
| 8 | 7 | 20 |
| 9 | 8 | 14 |
| 10 | 9 | 19 |
| 11 | 10 | 21 |
| 12 | 11 | 17 |
| 13 | 12 | 18 |
| 14 | 13 | 16 |
| 15 | 14 | 20 |

Below them, in A16 to A20, type `Average`, `Highest`, `Lead time`, `Safety days` and
`Reorder point`. In B18 type `7` and in B19 `4`. Then:

```localised
=ROUND(AVERAGE(B2:B15),0)      18
=MAX(B2:B15)      22
=B16*(B18+B19)      198
```

**The reorder point is 198 reels.** Seven days of demand is 126 of them and the safety stock is the
other 72. The highest day, 22, is there to keep the average honest: a range from 14 to 22 is ordinary
for this product, and no single day is far enough out to suggest a mistake in the data.

## When the lead time changes

In March 2026 the supplier announced that deliveries would take 10 days instead of 7. The rule is a
formula, so the fix is one cell: type `10` in B18, and B20 becomes 252. **The danger is the rule
nobody updates.** At the old point of 198 and a ten-day lead time, the stock is down to 18 reels when
an on-time delivery arrives: one day of sales, instead of four.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"A line of the reels in stock over six weeks. It falls by 18 a day from 396. Each time it reaches the reorder point of 198, a dashed line, an order of 360 is placed. With a seven-day lead time the delivery arrives with 72 reels still on the shelf, the safety stock. A second line, for a ten-day lead time and the same reorder point, is down to 18 reels, one day of sales, when each delivery arrives.\" data-fig=\"l09-stock\"><path d=\"M60.0 260.0 L700.0 260.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"52.0\" y=\"264.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><path d=\"M60.0 186.7 L700.0 186.7\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"52.0\" y=\"190.7\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">200</text><path d=\"M60.0 113.3 L700.0 113.3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"52.0\" y=\"117.3\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">400</text><path d=\"M60.0 40.0 L700.0 40.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"52.0\" y=\"44.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">600</text><text x=\"60.0\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><text x=\"166.7\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">7</text><text x=\"273.3\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">14</text><text x=\"380.0\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">21</text><text x=\"486.7\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">28</text><text x=\"593.3\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">35</text><text x=\"700.0\" y=\"278.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">42</text><text x=\"380.0\" y=\"298.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">days</text><path d=\"M60.0 187.4 L700.0 187.4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"6 4\"></path><text x=\"66.0\" y=\"181.4\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">reorder point: 198</text><path d=\"M60.0 114.8 L75.2 121.4 L90.5 128.0 L105.7 134.6 L121.0 141.2 L136.2 147.8 L151.4 154.4 L166.7 161.0 L181.9 167.6 L197.1 174.2 L212.4 180.8 L227.6 187.4 L242.9 194.0 L258.1 200.6 L273.3 207.2 L288.6 213.8 L303.8 220.4 L319.0 227.0 L334.3 233.6 L349.5 240.2 L364.8 246.8 L380.0 253.4 L380.0 121.4 L395.2 128.0 L410.5 134.6 L425.7 141.2 L441.0 147.8 L456.2 154.4 L471.4 161.0 L486.7 167.6 L501.9 174.2 L517.1 180.8 L532.4 187.4 L547.6 194.0 L562.9 200.6 L578.1 207.2 L593.3 213.8 L608.6 220.4 L623.8 227.0 L639.0 233.6 L654.3 240.2 L669.5 246.8 L684.8 253.4 L684.8 121.4 L700.0 128.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\" stroke-dasharray=\"5 3\"></path><path d=\"M60.0 114.8 L75.2 121.4 L90.5 128.0 L105.7 134.6 L121.0 141.2 L136.2 147.8 L151.4 154.4 L166.7 161.0 L181.9 167.6 L197.1 174.2 L212.4 180.8 L227.6 187.4 L242.9 194.0 L258.1 200.6 L273.3 207.2 L288.6 213.8 L303.8 220.4 L319.0 227.0 L334.3 233.6 L334.3 101.6 L349.5 108.2 L364.8 114.8 L380.0 121.4 L395.2 128.0 L410.5 134.6 L425.7 141.2 L441.0 147.8 L456.2 154.4 L471.4 161.0 L486.7 167.6 L501.9 174.2 L517.1 180.8 L532.4 187.4 L547.6 194.0 L562.9 200.6 L578.1 207.2 L593.3 213.8 L608.6 220.4 L623.8 227.0 L639.0 233.6 L639.0 101.6 L654.3 108.2 L669.5 114.8 L684.8 121.4 L700.0 128.0\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2.5\"></path><path d=\"M227.6 221.4 L227.6 193.4\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></path><path d=\"M227.6 193.4 L231.5 201.5 L223.7 201.5 Z\" fill=\"var(--paper)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M532.4 221.4 L532.4 193.4\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></path><path d=\"M532.4 193.4 L536.3 201.5 L528.5 201.5 Z\" fill=\"var(--paper)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"233.6\" y=\"231.4\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">order 360</text><path d=\"M70.0 18.0 L94.0 18.0\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2.5\"></path><text x=\"100.0\" y=\"22.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">lead time 7 days: lowest 72</text><path d=\"M390.0 18.0 L414.0 18.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\" stroke-dasharray=\"5 3\"></path><text x=\"420.0\" y=\"22.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">lead time 10 days, same point: lowest 18</text></svg>", "caption": "The reorder rule over six weeks. The point of 198 leaves four days of safety when the supplier takes seven days. When the supplier takes ten and nobody changes the point, one day is left, and any late delivery empties the shelf."}
```

And the record says deliveries run up to four days late. With 198 reels the shelf covers 11 days;
a ten-day lead time plus four days of lateness needs 14. **The shelf would be empty for three days,
about 54 reels of lost sales**, and none of them would appear in the sales data, because a sale that
never happens leaves no receipt. That is the trap lesson 8 described, and here it is the whole cost
of one cell left unchanged.

So a reorder rule is a formula plus its inputs, and the inputs need owners. Somebody has to notice
when the supplier changes its lead time, and the rule has to show the inputs it was computed from,
so that a reader can see that 7 is no longer true.
