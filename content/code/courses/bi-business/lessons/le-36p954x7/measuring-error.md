---
title: Measuring error, and turning it into a range
version: 1
---

The backtest produced three columns of errors. This section names what is in them, says which
summary to trust, and turns the best method's error into the range Otávio needed. **An error is
measured so that the next forecast can say how wrong it is likely to be.**

## Four words for one miss

Take the growth method's October: it forecast 8,490 and Varanda sold 7,960.

| word | what it is | October |
|---|---|---|
| error | forecast minus actual | +530, too high |
| percentage error | the error as a share of the actual | +6.7% |
| absolute percentage error | the same, without the sign | 6.7 |
| MAPE | the average of the absolute percentage errors over the months tested | 2.3, over July to December |

**The sign matters for one question and the size for another.** The size says how far off a forecast
usually is. The sign says whether it leans one way, which the next part is about.

## Bias: a miss that always leans the same way

The seasonal naive method missed by 5.3% on average, but that average hides a pattern: it was below
the actual in five months out of six. A method that misses in one direction is **biased**, and bias is
worse than its size suggests, because it accumulates. Plan stock on a forecast that is always 5% low
and every month runs short. Over the half year, the seasonal naive forecast was 5.3% below the
actual in total: 50,510 against 53,340. The growth method's errors went both ways, +1.8, 0.0, −0.8,
+6.7, −1.8 and −2.4, so its monthly misses largely cancelled and the half year came out 0.2% off.

**Check the signs before the average.** A small MAPE with all its errors on one side is a method
with a missing ingredient, here the company's growth. A larger MAPE with errors on both sides is a
method that is right on average and noisy month to month.

## Always against the baseline

A MAPE of 2.3% means nothing on its own. Is it good? It depends on how hard the series is to
forecast, and the way to measure that is the baseline. Against the naive method's 15.7%, the growth
method removes 85% of the error. **A new method that someone proposes, however clever, has
to beat 2.3% on the same months to be worth anything**, and if it only beats the naive 15.7% it has
proved nothing a spreadsheet formula did not already do.

## From the backtest to a range

Now the first quarter of 2026. The method is the one that won: each month of 2025, times the growth
of 2025 over 2024, which was 5.7%. For January:

```localised
=ROUND(6890*98000/92700,0)      7284
```

February and March give 6,882 and 7,844, so the quarter adds up to 22,010, R$ 22.0 million. For the
range, take the typical miss from the backtest, 2.3%, either side:

```localised
=ROUND(7284*(1-2.3/100),0)      7116
=ROUND(7284*(1+2.3/100),0)      7452
```

The quarter's range is 21,504 to 22,516. **That is what Lívia sent Otávio: R$ 22.0 million, most
likely between 21.5 and 22.5**, and a note that the backtest's worst month missed by 6.7%, so a
campaign or a price change moving into or out of the quarter would push the result outside that
range.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Three months of 2026, January to March. For each, a diamond marks the forecast, 7,284, 6,882 and 7,844 thousand reais, with a short bar for the typical miss of 2.3% either side and a longer, fainter bar for the worst miss of the backtest, 6.7% either side.\" data-fig=\"l08-range\"><path d=\"M192.5 30.0 L192.5 230.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"192.5\" y=\"248.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">6,500</text><path d=\"M313.3 30.0 L313.3 230.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"313.3\" y=\"248.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">7,000</text><path d=\"M434.2 30.0 L434.2 230.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"434.2\" y=\"248.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">7,500</text><path d=\"M555.0 30.0 L555.0 230.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"555.0\" y=\"248.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">8,000</text><path d=\"M675.8 30.0 L675.8 230.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"675.8\" y=\"248.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">8,500</text><text x=\"106.0\" y=\"69.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">January</text><path d=\"M264.0 62.0 H499.9 V68.0 H264.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M341.5 59.0 H422.5 V71.0 H341.5 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M377.0 65.0 L382.0 56.0 L387.0 65.0 L382.0 74.0 Z\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></path><text x=\"382.0\" y=\"51.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">7,284</text><text x=\"106.0\" y=\"134.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">February</text><path d=\"M173.4 127.0 H396.2 V133.0 H173.4 Z\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M246.6 124.0 H323.1 V136.0 H246.6 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M279.8 130.0 L284.8 121.0 L289.8 130.0 L284.8 139.0 Z\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></path><text x=\"284.8\" y=\"116.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">6,882</text><text x=\"106.0\" y=\"199.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">March</text><path d=\"M390.3 192.0 H644.3 V198.0 H390.3 Z\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M473.7 189.0 H560.9 V201.0 H473.7 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M512.3 195.0 L517.3 186.0 L522.3 195.0 L517.3 204.0 Z\" fill=\"var(--paper)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></path><text x=\"517.3\" y=\"181.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">7,844</text><path d=\"M120.0 272.0 H142.0 V282.0 H120.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"150.0\" y=\"281.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">typical miss, ±2.3%</text><path d=\"M340.0 274.0 H362.0 V280.0 H340.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"370.0\" y=\"281.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">worst miss, ±6.7%</text><text x=\"700.0\" y=\"281.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">thousands of reais</text></svg>", "caption": "The first quarter of 2026 shown as a forecast should be: each month a number, with the range the backtest earned and, fainter, how far the backtest's worst month missed."}
```

The range is a rule of thumb, not a statistical interval: it says "this method usually missed by
about this much", from six months of evidence. A statistician would compute an interval with a
stated probability, which is `statistics` material. For deciding how much stock to order in
February, the rule of thumb carries most of the value, and it is honest about where it came from.
