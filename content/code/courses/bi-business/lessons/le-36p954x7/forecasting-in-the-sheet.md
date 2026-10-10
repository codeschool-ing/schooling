---
title: Forecasting in the sheet, and testing it on the past
version: 1
---

A method is judged by how it would have done on a period that has already happened. **This is a
backtest: pretend it is the end of June 2025, forecast July to December with each method, and compare
every forecast with what Varanda really sold.** The past is the one place where the right answer is
known, so it is the only place where a forecasting method can be marked.

## The table

Add a sheet. Type the second half of 2025 and the same months of 2024, in thousands of reais, from A1:

| | A | B | C |
|---|---|---|---|
| 1 | Month | Actual 2025 | Same month 2024 |
| 2 | Jul | 7140 | 6870 |
| 3 | Aug | 7810 | 7380 |
| 4 | Sep | 8150 | 7640 |
| 5 | Oct | 7960 | 8020 |
| 6 | Nov | 10040 | 9310 |
| 7 | Dec | 12240 | 11290 |

The growth method needs the recent pace, and at the end of June the recent pace is the first half of
2025 against the first half of 2024. Add both halves from lesson 6's sheet, January to June: in I1
type `H1 2024` and in J1 `42190`; in I2 type `H1 2025` and in J2 `44660`. The first half grew 5.9%.

## The three forecasts and their errors

The size of a miss, as a share of what really happened, is the **absolute percentage error**. It
needs the error without its sign, and `MAX` of the error and its negative gives exactly that. In D1
type `Naive APE`. The naive forecast for every month is June 2025's 7,330:

```localised
=ROUND(MAX(7330-B2,B2-7330)/B2*100,1)      2.7
```

In E1 type `Seasonal APE`. The seasonal naive forecast is column C itself:

```localised
=ROUND(MAX(C2-B2,B2-C2)/B2*100,1)      3.8
```

In F1 type `Growth forecast` and in G1 `Growth APE`. The forecast is last year's month times the
first half's growth, and its error is computed the same way:

```localised
=ROUND(C2*$J$2/$J$1,0)      7272
=ROUND(MAX(F2-B2,B2-F2)/B2*100,1)      1.8
```

Copy D2:G2 down to row 7. Then, in row 8, average each error column; the average of the absolute
percentage errors has a name, **MAPE**, the mean absolute percentage error:

```localised
=ROUND(AVERAGE(D2:D7),1)      15.7
=ROUND(AVERAGE(E2:E7),1)      5.3
=ROUND(AVERAGE(G2:G7),1)      2.3
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" aria-label=\"A line chart of July to December 2025 in thousands of reais. The actual sales rise from 7,140 in July to 12,240 in December. The seasonal naive forecast, last year's same month, runs just below the actual line in every month but October. The forecast adjusted for growth sits almost on the actual line, except in October, where it is 6.7% too high. The naive forecast, June repeated, is a flat line at 7,330 that misses the November and December peak entirely.\" data-fig=\"l08-backtest\"><path d=\"M70.0 290.0 L560.0 290.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"62.0\" y=\"294.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">6,000</text><path d=\"M70.0 215.7 L560.0 215.7\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"62.0\" y=\"219.7\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">8,000</text><path d=\"M70.0 141.4 L560.0 141.4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"62.0\" y=\"145.4\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">10,000</text><path d=\"M70.0 67.1 L560.0 67.1\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"62.0\" y=\"71.1\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">12,000</text><text x=\"100.0\" y=\"310.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Jul</text><text x=\"186.0\" y=\"310.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Aug</text><text x=\"272.0\" y=\"310.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Sep</text><text x=\"358.0\" y=\"310.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Oct</text><text x=\"444.0\" y=\"310.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Nov</text><text x=\"530.0\" y=\"310.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Dec</text><path d=\"M100.0 240.6 L186.0 240.6 L272.0 240.6 L358.0 240.6 L444.0 240.6 L530.0 240.6\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"2 4\"></path><path d=\"M100.0 257.7 L186.0 238.7 L272.0 229.1 L358.0 215.0 L444.0 167.1 L530.0 93.5\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\" stroke-dasharray=\"6 4\"></path><path d=\"M100.0 242.8 L186.0 222.7 L272.0 212.5 L358.0 197.5 L444.0 146.8 L530.0 69.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></path><path d=\"M100.0 247.7 L186.0 222.8 L272.0 210.1 L358.0 217.2 L444.0 139.9 L530.0 58.2\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"2.5\"></path><path d=\"M580.0 60.0 L602.0 60.0\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"2.5\"></path><text x=\"608.0\" y=\"64.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">actual 2025</text><path d=\"M580.0 90.0 L602.0 90.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\"></path><text x=\"608.0\" y=\"94.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">last year × growth</text><path d=\"M580.0 120.0 L602.0 120.0\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2\" stroke-dasharray=\"6 4\"></path><text x=\"608.0\" y=\"124.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">last year's month</text><path d=\"M580.0 150.0 L602.0 150.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"2 4\"></path><text x=\"608.0\" y=\"154.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">June, repeated</text><text x=\"580.0\" y=\"190.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">average miss</text><text x=\"580.0\" y=\"210.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">× growth</text><text x=\"712.0\" y=\"210.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2.3%</text><text x=\"580.0\" y=\"230.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">last year</text><text x=\"712.0\" y=\"230.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">5.3%</text><text x=\"580.0\" y=\"250.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">June</text><text x=\"712.0\" y=\"250.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">15.7%</text><text x=\"352.0\" y=\"173.5\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Oct: +6.7%</text><text x=\"70.0\" y=\"340.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">thousands of reais; forecasts made with data up to June 2025</text></svg>", "caption": "The backtest. Each forecast is drawn against what happened. Last year's month adjusted for the first half's growth misses by 2.3% on average, and its one large miss is October, where the campaign moved."}
```

## What the backtest says

**The naive method misses by 15.7% on average, and by 40.1% in December.** It is the method that
ignores the season, and the season is most of what happens to Varanda between July and December.

**Last year's month misses by 5.3%,** and it misses in one direction: it is below the actual in
five months of six. Varanda grew, and this method assumes it did not. Its only month above the
actual is October, at 0.8%, and lesson 7 says why.

**Last year's month times the first half's growth misses by 2.3%.** Five of its six months are
within 2.4% of what happened, and its forecast for the half year as a whole, 53,467 against an actual
of 53,340, is off by 0.2%. Its one large miss is October, 6.7% too high. No method that only reads
history could have seen that one coming: the campaign that made October 2024 big moved to November
in 2025, and nothing in the sales history said it would.

That is the result Lívia took to Otávio: the simplest method that keeps the season and the pace was
right to within a few per cent for five months in six, and wrong by about 7% in the month a decision
changed the calendar. **The second half of that sentence is as useful as the first.** It says what
kind of event this method cannot see, and therefore what to ask about before trusting the next
forecast: is any campaign, price change or opening moving this year?
