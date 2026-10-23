---
title: Total cost of ownership, three years out
version: 1
---

A price is what somebody asks you to pay. **A total cost of ownership is everything you will pay, to
anybody, to get a system running, keep it running, change it and leave it, over a stated period.**
The two differ by a factor of two in the example below, and the gap is not fraud or carelessness on
anybody's part. The vendor quoted what the vendor sells. The rest is Serra Alta's to count, and
nobody else will count it.

This section builds the sheet for option A, the SaaS product, line by line. Section 06 of this lesson
puts B and C beside it with the same lines. Every figure is Serra Alta's own estimate, invented for
this course, and none of them is any real vendor's price.

## The lines

A sheet that leaves a line out compares options on a different basis without saying so. These are
the twelve lines Serra Alta's sheet uses, and **every option gets every line, with a zero typed where
a line costs nothing** — an empty cell says nobody looked, a zero says somebody decided.

| line | what it holds |
|---|---|
| licence or subscription | what is paid for the right to use the software: a subscription, a licence, a platform fee |
| implementation | the one-off work to get to the first farm payment: configuring or building, testing, going live |
| data migration | moving the farm master and history out of Coleta, lesson 14's whole subject |
| integration | the interfaces to SAP, the lab results and Rota, lessons 8 to 11 |
| customisation | what is written because the product does not do something out of the box |
| infrastructure | servers, cloud accounts, environments, the runtime the interfaces need |
| operation and support | keeping it running: support contracts, first-line help, monitoring, on-call, patching |
| internal team | Serra Alta's own people assigned to the system: owners, analysts, developers |
| training | teaching the 300 truck drivers and the 30 office staff who use it |
| upgrades | the cost of each new version: testing, fixing what it breaks |
| Coleta kept running | the old system, paid for until the new one has replaced it |
| exit | what leaving would cost at the end of the period; section 05 of this lesson |

Two lines on that list are missing from most sheets. **Coleta kept running** is easy to forget
because nobody is proposing to spend money on Coleta, and yet every month the new system is not
ready, Serra Alta pays R$ 15,000 to keep the IBM i under maintenance. It belongs on the sheet because
the options finish at different times, so they keep Coleta for different lengths of time. **Exit**
is the price of the door, and section 05 of this lesson explains why it is counted whole.

## Four rules for the sheet

**The same horizon for every option.** Serra Alta's is 36 calendar months, January 2027 to December
2029. Three years is long enough for running costs to show and short enough that the numbers are
estimates rather than hopes. A finance team will often add a column called year 0 for the money paid
before anything runs. That works when every option starts running on the same day; here they do not,
because the build spends a whole year before it pays anybody, so this sheet puts each payment in
the calendar year it is made.

**The same unit.** Reais, as paid, without inflation. Marcos Teles's team also discounts the three
years to present value. At the rates they use, between 10% and 15% a year, the order of the three
options does not change, so the sheet in this lesson stays in plain reais that you can add up.

**Every number has a derivation.** "R$ 360,000" is an assertion; "R$ 40,000 a month for nine months"
is a claim somebody can check and argue with.

**Every assumption is written down.** The sheet below rests on four, and section 06 of this lesson
tests them:

- Serra Alta adds 100 farms a year, from 1,900 in 2027 to 2,100 in 2029;
- the contract caps the price rise at renewal at 4%;
- a person on the internal team costs R$ 25,000 a month, salary and charges together;
- the first farm payment from the new system is in October 2027, month 10.

## Option A, line by line

The SaaS vendor charges per active farm per month: R$ 25 for the first two years, the contract's
term, and at most 4% more at the first renewal, so R$ 26 in year 3. Implementation runs from month 1
to month 9, with three months of parallel running (lesson 13) at the end of it. The first payment
from the product is on 10 October 2027, and Coleta is switched off after the third, in December.

| line | worked out as | year 1 | year 2 | year 3 | 36 months |
|---|---|---|---|---|---|
| subscription | R$ 25 × 1,900 farms × 12; R$ 25 × 2,000 × 12; R$ 26 × 2,100 × 12 | 570,000 | 600,000 | 655,200 | 1,825,200 |
| implementation | the vendor's partner, R$ 40,000 a month, months 1–9 | 360,000 | 0 | 0 | 360,000 |
| data migration | R$ 25,000 a month, months 4–9 | 150,000 | 0 | 0 | 150,000 |
| integration | SAP, lab results and Rota, R$ 30,000 a month, months 2–9 | 240,000 | 0 | 0 | 240,000 |
| customisation | the five rules extended beside, R$ 25,000 a month, months 3–8 | 150,000 | 0 | 0 | 150,000 |
| infrastructure | the interfaces' runtime and monitoring, R$ 2,500 a month | 30,000 | 30,000 | 30,000 | 90,000 |
| operation and support | first-line help and watching the interfaces, R$ 4,000 a month from month 10 | 12,000 | 48,000 | 48,000 | 108,000 |
| internal team | a product owner full time to month 9 (R$ 25,000 a month), half time after | 262,500 | 150,000 | 150,000 | 562,500 |
| training | drivers and office staff, months 7–9 | 80,000 | 0 | 0 | 80,000 |
| upgrades | R$ 10,000 to test each quarterly release, from month 12 | 10,000 | 40,000 | 40,000 | 90,000 |
| Coleta kept running | R$ 15,000 a month, months 1–12 | 180,000 | 0 | 0 | 180,000 |
| **spending** | | **2,044,500** | **868,000** | **923,200** | **3,835,700** |
| exit | if Serra Alta left at the end of month 36; section 05 of this lesson | | | | 397,800 |
| **TCO** | | | | | **4,233,500** |

Check two cells by hand before trusting the rest. The year-1 internal team is nine months at
R$ 25,000 and three at R$ 12,500: R$ 225,000 + R$ 37,500 = R$ 262,500. The year-3 subscription is
R$ 26 × 2,100 × 12 = R$ 655,200. If those two agree with the table, the arithmetic of the sheet can be
trusted, and the argument moves to the assumptions, which is where it belongs.

## Reading it by year

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l15-a-by-year\" aria-label=\"Option A, the SaaS product, as four bars. Year 1 is the tallest, R$ 2,044,500: R$ 1,160,000 of it paid once (implementation, migration, integration, customisation, training and Coleta's last twelve months) and R$ 884,500 that recurs. Year 2 is R$ 868,000 and year 3 is R$ 923,200, all recurring. A fourth, dashed bar is the exit, R$ 397,800, paid only if Serra Alta leaves.\"><rect x=\"120.0\" y=\"165.8\" width=\"90.0\" height=\"84.2\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><rect x=\"120.0\" y=\"55.3\" width=\"90.0\" height=\"110.5\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"165.0\" y=\"110.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">1,160,000</text><text x=\"165.0\" y=\"207.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">884,500</text><text x=\"165.0\" y=\"43.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">2,044,500</text><text x=\"165.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">year 1</text><rect x=\"260.0\" y=\"167.3\" width=\"90.0\" height=\"82.7\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"305.0\" y=\"208.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">868,000</text><text x=\"305.0\" y=\"155.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">868,000</text><text x=\"305.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">year 2</text><rect x=\"400.0\" y=\"162.1\" width=\"90.0\" height=\"87.9\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"445.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--ink)\">923,200</text><text x=\"445.0\" y=\"150.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">923,200</text><text x=\"445.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">year 3</text><rect x=\"540.0\" y=\"212.1\" width=\"90.0\" height=\"37.9\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"585.0\" y=\"200.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">397,800</text><text x=\"585.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">exit</text><path d=\"M100.0 250.0 L680.0 250.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"120.0\" y=\"278.0\" width=\"12.0\" height=\"12.0\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"138.0\" y=\"284.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">paid once</text><rect x=\"270.0\" y=\"278.0\" width=\"12.0\" height=\"12.0\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"288.0\" y=\"284.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">paid every year</text><rect x=\"430.0\" y=\"278.0\" width=\"12.0\" height=\"12.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><text x=\"448.0\" y=\"284.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">paid only on leaving</text></svg>", "caption": "Option A, in reais, by the year the money is paid. Year 1 carries everything that is paid once; years 2 and 3 show what owning it costs."}
```

**Year 1 carries 53% of the three years' spending**: R$ 2,044,500 of R$ 3,835,700. Of that,
R$ 1,160,000 is paid once and never again — implementation, migration, integration, customisation,
training and Coleta's last twelve months. Years 2 and 3 are the system as it will normally cost:
R$ 868,000 and R$ 923,200. That second number is the one to remember, because it is the bill Serra
Alta receives every year for as long as it keeps the product, and it grows by itself as the farms
and the price grow.

Three more readings that the totals hide:

- **the subscription is 43% of the TCO**, R$ 1,825,200 of R$ 4,233,500. It is the largest line and
  still less than half of the cost; a decision made on the price alone is made on less than half the
  facts;
- **nine months of subscription are paid before a single farm is paid by the product**: months 1 to
  9 at R$ 25 × 1,900 farms = R$ 47,500 a month, R$ 427,500 in all. Vendors start the clock at
  signature, and an implementation that slips by a month costs a month of subscription on top of
  the month of everything else;
- **the internal team is the second-largest line**, R$ 562,500, larger than implementation. Buying a
  product does not buy the absence of people: somebody has to own the configuration, decide what the
  next release changes, and answer Cláudia when the tables move.

## What the sheet does not decide

A complete sheet for one option says what A costs. It does not say whether A is a good idea, and it
says nothing about B and C. It has also been built from the inside out — from what Serra Alta knows
it will do — and the most expensive errors in a TCO are lines that nobody on the team thought to add.
Section 04 of this lesson is about those, on both sides of the argument.
