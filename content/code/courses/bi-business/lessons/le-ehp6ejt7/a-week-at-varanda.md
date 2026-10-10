---
title: A week at Varanda, in hours
version: 1
---

The picture of a BI analyst on a job advert is somebody building a dashboard. Lívia kept a log of her
hours for the four working weeks of February 2026, by kind of work, because Helena had asked what a
BI analyst actually does all day. **Building dashboards and charts came sixth of seven.** The log is
short enough to type, and the shares are worth computing yourself.

## The table

Add a sheet to your file and type her four weeks, in hours:

| | A | B |
|---|---|---|
| 1 | Kind of work | Hours |
| 2 | Answering requests | 36 |
| 3 | Meetings with the business | 37 |
| 4 | Checking and fixing data | 31 |
| 5 | Running recurring reports | 24 |
| 6 | Writing definitions and notes | 21 |
| 7 | Building dashboards and charts | 16 |
| 8 | Learning | 11 |

In A9 type `Total` and in B9:

```localised
=SUM(B2:B8)      176
```

**176 hours in four weeks, 44 a week**, the usual full-time week in Brazil, so the log accounts for
her whole working time. In C1 type `Share`, and in C2 the share of the total, rounded to
one decimal, as in lesson 1:

```localised
=ROUND(B2/B$9*100,1)      20.5
```

Copy C2 down to C8. The column should read 20.5, 21, 17.6, 13.6, 11.9, 9.1 and 6.3. Calc shows the
meetings' share as `21` rather than `21.0`, because a rounded number with nothing after the point is
shown without it; the value is the same. Add the column as a check:

```localised
=SUM(C2:C8)      100
```

This time the roundings happened to cancel out. In lesson 1 they did not, and both are honest.

## Where the hours went

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Horizontal bars, one per kind of work, for Lívia's 176 hours in four weeks of February: meetings with the business 37 hours, answering requests 36, checking and fixing data 31, running recurring reports 24, writing definitions and notes 21, building dashboards and charts 16, learning 11.\" data-fig=\"l04-hours\"><text x=\"248.0\" y=\"48.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Meetings with the business</text><path d=\"M260.0 34.0 H593.0 V56.0 H260.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"601.0\" y=\"50.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">37 h</text><text x=\"248.0\" y=\"86.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Answering requests</text><path d=\"M260.0 72.0 H584.0 V94.0 H260.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"592.0\" y=\"88.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">36 h</text><text x=\"248.0\" y=\"124.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Checking and fixing data</text><path d=\"M260.0 110.0 H539.0 V132.0 H260.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"547.0\" y=\"126.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">31 h</text><text x=\"248.0\" y=\"162.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Running recurring reports</text><path d=\"M260.0 148.0 H476.0 V170.0 H260.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"484.0\" y=\"164.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">24 h</text><text x=\"248.0\" y=\"200.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Writing definitions and notes</text><path d=\"M260.0 186.0 H449.0 V208.0 H260.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"457.0\" y=\"202.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">21 h</text><text x=\"248.0\" y=\"238.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Building dashboards and charts</text><path d=\"M260.0 224.0 H404.0 V246.0 H260.0 Z\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"412.0\" y=\"240.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">16 h</text><text x=\"248.0\" y=\"276.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Learning</text><path d=\"M260.0 262.0 H359.0 V284.0 H260.0 Z\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></path><text x=\"367.0\" y=\"278.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">11 h</text><path d=\"M260.0 26.0 L260.0 296.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><text x=\"360.0\" y=\"316.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">hours in four weeks; the highlighted bar is the part people picture as the job</text></svg>", "caption": "Lívia's February in hours. Building dashboards and charts is 9.1% of her time; talking to the business and answering it is 41.5%."}
```

Two sums tell the story. Answering requests and meetings — talking to the business and answering
it — come to 73 hours:

```localised
=ROUND((B2+B3)/B9*100,1)      41.5
```

**41.5% of the month was spent with the people who ask the questions.** Checking and fixing data plus
writing definitions and notes came to 52 hours:

```localised
=ROUND((B4+B6)/B9*100,1)      29.5
```

**Another 29.5% went on making sure the numbers mean what they say.** Building dashboards and charts,
the part most people picture, was 16 hours, 9.1%.

## Why it looks like this

None of this is a sign that something was wrong in February. The requests and the meetings are where
the questions are found and made precise; the checks are why the Monday email can be trusted; the
definitions are what stops two directors bringing two totals. **A chart is the last step of work that
mostly happened before it**, and a dashboard built without the other 90% of the hours is the report
factory of lesson 1.

One honest caveat: this is a month in Lívia's first quarter, at a company with no BI before her.
Checking and fixing data takes more of a new analyst's time than it will once the definitions are
written and the pipelines are trusted, and building takes more once there is something worth
building. Her log for a month next year will look different. The next section is about the first
row of the table, the requests.
