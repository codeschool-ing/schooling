---
title: Totals and comparisons
version: 1
---

A descriptive answer is a number with a comparison beside it. **The number alone says how much; the
comparison says whether that is good.** And which comparison you choose decides what the number
appears to say, so this section builds Varanda's two years in a sheet and puts the two common
comparisons side by side.

## The two years, by month

Add a sheet to the file from lesson 1 and type Varanda's sales for 2024 and 2025, in thousands of
reais, starting in A1:

| | A | B | C |
|---|---|---|---|
| 1 | Month | 2024 | 2025 |
| 2 | Jan | 6420 | 6890 |
| 3 | Feb | 6180 | 6510 |
| 4 | Mar | 7050 | 7420 |
| 5 | Apr | 7210 | 7700 |
| 6 | May | 8340 | 8810 |
| 7 | Jun | 6990 | 7330 |
| 8 | Jul | 6870 | 7140 |
| 9 | Aug | 7380 | 7810 |
| 10 | Sep | 7640 | 8150 |
| 11 | Oct | 8020 | 7960 |
| 12 | Nov | 9310 | 10040 |
| 13 | Dec | 11290 | 12240 |

In A14 type `Total`, and the two sums go in B14 and C14:

```localised
=SUM(B2:B13)      92700
=SUM(C2:C13)      98000
```

**R$ 92.7 million in 2024 and R$ 98.0 million in 2025**, R$ 5.3 million more. That is a description,
and already a useful one, but the year hides its months.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"A bar chart of Varanda's sales by month in thousands of reais, 2024 and 2025 side by side. Both years climb towards December, the highest month in each, at 11,290 and 12,240. Every month of 2025 is above the same month of 2024 except October: 7,960 against 8,020.\" data-fig=\"l06-months\"><path d=\"M64.0 270.0 L704.0 270.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"56.0\" y=\"274.0\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><path d=\"M64.0 199.2 L704.0 199.2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"56.0\" y=\"203.2\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">4,000</text><path d=\"M64.0 128.5 L704.0 128.5\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"56.0\" y=\"132.5\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">8,000</text><path d=\"M64.0 57.7 L704.0 57.7\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"56.0\" y=\"61.7\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">12,000</text><path d=\"M71.7 156.4 H89.7 V270.0 H71.7 Z\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M91.7 148.1 H109.7 V270.0 H91.7 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"90.7\" y=\"288.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Jan</text><path d=\"M125.0 160.7 H143.0 V270.0 H125.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M145.0 154.8 H163.0 V270.0 H145.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"144.0\" y=\"288.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Feb</text><path d=\"M178.3 145.3 H196.3 V270.0 H178.3 Z\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M198.3 138.7 H216.3 V270.0 H198.3 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"197.3\" y=\"288.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Mar</text><path d=\"M231.7 142.4 H249.7 V270.0 H231.7 Z\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M251.7 133.8 H269.7 V270.0 H251.7 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"250.7\" y=\"288.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Apr</text><path d=\"M285.0 122.4 H303.0 V270.0 H285.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M305.0 114.1 H323.0 V270.0 H305.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"304.0\" y=\"288.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">May</text><path d=\"M338.3 146.3 H356.3 V270.0 H338.3 Z\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M358.3 140.3 H376.3 V270.0 H358.3 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"357.3\" y=\"288.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Jun</text><path d=\"M391.7 148.5 H409.7 V270.0 H391.7 Z\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M411.7 143.7 H429.7 V270.0 H411.7 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"410.7\" y=\"288.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Jul</text><path d=\"M445.0 139.4 H463.0 V270.0 H445.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M465.0 131.8 H483.0 V270.0 H465.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"464.0\" y=\"288.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Aug</text><path d=\"M498.3 134.8 H516.3 V270.0 H498.3 Z\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M518.3 125.8 H536.3 V270.0 H518.3 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"517.3\" y=\"288.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Sep</text><path d=\"M551.7 128.1 H569.7 V270.0 H551.7 Z\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M571.7 129.2 H589.7 V270.0 H571.7 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"570.7\" y=\"288.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Oct</text><path d=\"M605.0 105.3 H623.0 V270.0 H605.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M625.0 92.4 H643.0 V270.0 H625.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"624.0\" y=\"288.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Nov</text><path d=\"M658.3 70.3 H676.3 V270.0 H658.3 Z\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></path><path d=\"M678.3 53.4 H696.3 V270.0 H678.3 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"677.3\" y=\"288.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Dec</text><text x=\"580.7\" y=\"95.2\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Oct: −0.7%</text><path d=\"M580.7 101.2 L580.7 125.2\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></path><path d=\"M64.0 12.0 H78.0 V26.0 H64.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"84.0\" y=\"24.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">2024</text><path d=\"M134.0 12.0 H148.0 V26.0 H134.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"154.0\" y=\"24.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">2025</text><text x=\"214.0\" y=\"24.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">thousands of reais</text><text x=\"704.0\" y=\"318.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">December is the highest month in both years</text></svg>", "caption": "Varanda's two years by month. The shape repeats, December on top in both, so a month is compared with the same month a year before. October 2025 is the one that fell."}
```

## Month over month

The comparison most people reach for first is with the month before. In E1 type `MoM %`, and in E3,
next to February 2025:

```localised
=ROUND((C3/C2-1)*100,1)      -5.5
```

Copy it down to E13. The column swings wildly: May is up 14.4% on April and June is down 16.8% on
May, November is up 26.1% on October and December up another 21.9% on November.

**None of those swings says anything about how Varanda did.** May has Mother's Day, and June has nothing
like it. November and December are the gift season in every year. A
garden-and-furniture retailer's months are not alike, and comparing a month with the one before mostly
measures the calendar. November 2025 was up 26.1% on October 2025, which sounds like a triumph, but
November 2024 was up 16.1% on October 2024. **The swing is the season, and the season repeats.**

## Year over year

The comparison that removes the season is with the same month a year before. In D1 type `YoY %`, and
in D2:

```localised
=ROUND((C2/B2-1)*100,1)      7.3
```

Copy it down to D13, and into D14 for the year. The year comes out at **5.7**, and the months sit
between 3.9 (July) and 8.4 (December). There is one exception. **October, at −0.7, is the only month
of 2025 below the same month of 2024.** Month over month, October showed −2.3% against September, which looked
like any other dip. Year over year, it is the one month that stands out.

That is the whole case for year over year in a seasonal business. It compares like with like, so what
is left in the column is the year's own story rather than the calendar's.

## Shares of the year

A second kind of comparison is with the whole. Two cells tell you how much of Varanda's year sits at
its end:

```localised
=ROUND(SUM(C11:C13)/C14*100,1)      30.9
=ROUND(C13/C14*100,1)      12.5
```

**The last quarter is 30.9% of the year**, and it was 30.9% in 2024 too: the shape held. December
alone is 12.5% of 2025. Two things follow, and both are decisions somebody makes with a descriptive
number. Stock and staff for the last quarter have to be planned months earlier. And a bad October is
worth explaining before November starts, which is exactly what lesson 7 does.
