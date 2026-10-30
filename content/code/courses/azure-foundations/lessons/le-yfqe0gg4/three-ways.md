---
title: Pay as you go, reservations and savings plans
version: 1
---

**Azure sells the same running machine at three prices, and the difference between them is not the
machine but the promise you make about it.** Pay as you go promises nothing and pays the most per
hour. A reservation promises one kind of machine, in one region, for one or three years. A savings
plan promises an amount of money per hour, for one or three years, wherever it is spent. The more
you promise, the less each hour costs, and **a promise is paid whether or not you keep using what
you promised**.

## Three ways to pay

| | what you commit to | the hour is charged | the risk is |
|---|---|---|---|
| **pay as you go** | nothing | only while the resource runs | the highest price per hour, for as long as you leave it running |
| **reservation** | one product, size and region, for one or three years | every hour of the term, used or not | the machine changes, or stops, and the reservation keeps charging |
| **savings plan** | an amount per hour, for one or three years | every hour of the term, up to the amount | the amount is more than you end up spending; an hour's unused part is lost |

**A reservation is a discount on one thing.** Microsoft's documentation says reservations can reduce
costs *by up to 72%* against pay as you go, and that is a ceiling for the most favourable product and
term, not a figure to plan with. It applies automatically to whatever usage matches what was bought:
the size, the region, and the **scope**, which is a subscription, a resource group, a management
group, or every subscription of the billing account (*shared*). It can be paid up front or monthly,
and the total is the same either way. If the workload changes, a reservation can be exchanged for
another of the same type, and returned for a refund within a limit Microsoft sets, at the time of
writing USD 50,000 in a rolling twelve months.

**A savings plan is a discount on an hourly budget.** You commit to spending, say, a fixed amount
per hour on compute; every hour, Azure applies discounted prices to the eligible usage in the plan's
scope and deducts it from that amount, and anything beyond it is billed at pay-as-you-go prices.
Microsoft offers two kinds, one for compute and one for databases. The discount is smaller than a
reservation's for the same machine and it follows the usage across sizes, regions and services. Two
things about it are unforgiving: **the unused part of an hour expires and does not roll over**, and a
savings plan, unlike a reservation, **cannot be cancelled or refunded**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l14-savings-plan-hours\" aria-label=\"Six hours under a savings plan committed to an invented 10 an hour, drawn as bars. In hours one and two the eligible usage, at its discounted price, is 10 and uses the commitment exactly. In hour three it is 14: 10 comes out of the commitment and the extra 4 of usage is billed at pay-as-you-go prices. In hours four and five it is 6, and the remaining 4 of the commitment is lost. In hour six nothing runs and the whole 10 is lost.\"><path d=\"M60.0 110.0 L560.0 110.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"565.0\" y=\"110.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">commitment: 10 an hour</text><rect x=\"80.0\" y=\"110.0\" width=\"50.0\" height=\"100.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">hour 1</text><rect x=\"160.0\" y=\"110.0\" width=\"50.0\" height=\"100.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"185.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">hour 2</text><rect x=\"240.0\" y=\"110.0\" width=\"50.0\" height=\"100.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"240.0\" y=\"70.0\" width=\"50.0\" height=\"40.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><text x=\"265.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">hour 3</text><rect x=\"320.0\" y=\"150.0\" width=\"50.0\" height=\"60.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"320.0\" y=\"110.0\" width=\"50.0\" height=\"40.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"345.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">hour 4</text><rect x=\"400.0\" y=\"150.0\" width=\"50.0\" height=\"60.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"400.0\" y=\"110.0\" width=\"50.0\" height=\"40.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"425.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">hour 5</text><rect x=\"480.0\" y=\"110.0\" width=\"50.0\" height=\"100.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"505.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">hour 6</text><path d=\"M60.0 210.0 L560.0 210.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"80.0\" y=\"240.0\" width=\"14.0\" height=\"12.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"100.0\" y=\"246.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">covered by the plan</text><rect x=\"260.0\" y=\"240.0\" width=\"14.0\" height=\"12.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><text x=\"280.0\" y=\"246.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">billed at pay as you go</text><rect x=\"460.0\" y=\"240.0\" width=\"14.0\" height=\"12.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"480.0\" y=\"246.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">unused, and lost</text></svg>", "caption": "Each hour stands alone: an unused part does not carry over to the next."}
```

## Where a commitment stops paying

Whether a commitment saves money is arithmetic, and the arithmetic needs no account. The shop's
reporting machine is the example; **the prices here are round numbers invented for the arithmetic,
not Azure's**: 1.00 an hour pay as you go, and an effective 0.60 an hour under a one-year
reservation. Make the lesson's directory, and save this program in it as `breakeven.py`:

```sh
mkdir -p ~/azure/bill && cd ~/azure/bill
```

```schooling-example
{"language": "python", "file": "breakeven.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"breakeven.py PAYG COMMITTED: what a commitment saves, by how much of the month it is used.\"\"\"\nimport sys\n\nHOURS = 730\n\n", "note": "`HOURS` is the month Azure's own price calculator uses: 730 hours, a year's 8,760 divided by twelve. Every monthly figure below is an hourly price times this."}, {"code": "payg, committed = float(sys.argv[1]), float(sys.argv[2])\nprint(f'break-even at {committed / payg:.0%} of the month')\n", "note": "Two prices per hour: pay as you go, and the effective hourly price of a commitment. **The commitment is paid for every hour, used or not**, so it wins only when the machine runs for more than the ratio of the two prices."}, {"code": "for used in (1.0, 0.8, 0.6, 0.4):\n    on_demand = payg * HOURS * used\n    reserved = committed * HOURS\n    verdict = 'saves' if reserved < on_demand else 'loses'\n    print(f'used {used:4.0%}: pay as you go {on_demand:7.2f}  committed {reserved:7.2f}  '\n          f'{verdict} {abs(on_demand - reserved):6.2f}')\n", "note": "Four months: the machine on all the time, then for 80%, 60% and 40% of the hours. Pay as you go charges only the hours used; the commitment charges all 730."}]}
```

Then ask it about the one-year price, and about a deeper, three-year one of 0.40:

```
ana@laptop:~/azure/bill$ python3 breakeven.py 1.00 0.60
break-even at 60% of the month
used 100%: pay as you go  730.00  committed  438.00  saves 292.00
used  80%: pay as you go  584.00  committed  438.00  saves 146.00
used  60%: pay as you go  438.00  committed  438.00  loses   0.00
used  40%: pay as you go  292.00  committed  438.00  loses 146.00
ana@laptop:~/azure/bill$ python3 breakeven.py 1.00 0.40
break-even at 40% of the month
used 100%: pay as you go  730.00  committed  292.00  saves 438.00
used  80%: pay as you go  584.00  committed  292.00  saves 292.00
used  60%: pay as you go  438.00  committed  292.00  saves 146.00
used  40%: pay as you go  292.00  committed  292.00  loses   0.00
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" data-fig=\"l14-breakeven\" aria-label=\"The month's cost of one machine against the share of the month it runs, with the lesson's invented prices. Pay as you go rises in a straight line from 0 to 730 at 100%. A one-year reservation at 0.60 an hour is flat at 438, and crosses the pay-as-you-go line at 60%. A three-year one at 0.40 is flat at 292, and crosses at 40%. Left of a crossing the reservation loses money, right of it the reservation saves.\"><path d=\"M90.0 260.0 L640.0 260.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M90.0 260.0 L90.0 40.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"80.0\" y=\"260.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><text x=\"80.0\" y=\"179.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">292</text><text x=\"80.0\" y=\"139.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">438</text><text x=\"80.0\" y=\"59.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">730</text><text x=\"90.0\" y=\"276.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0%</text><text x=\"310.0\" y=\"276.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40%</text><text x=\"420.0\" y=\"276.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60%</text><text x=\"640.0\" y=\"276.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100%</text><text x=\"365.0\" y=\"298.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">share of the month the machine runs</text><path d=\"M90.0 260.0 L640.0 59.2\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"552.0\" y=\"55.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">pay as you go</text><path d=\"M90.0 139.6 L640.0 139.6\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"640.0\" y=\"129.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">one-year reservation</text><path d=\"M90.0 179.7 L640.0 179.7\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"640.0\" y=\"193.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">three-year reservation</text><circle cx=\"420.0\" cy=\"139.6\" r=\"4.5\" fill=\"var(--amber)\"></circle><circle cx=\"310.0\" cy=\"179.7\" r=\"4.5\" fill=\"var(--paper)\"></circle></svg>", "caption": "Invented prices: the reservation pays only to the right of where its line crosses."}
```

**The break-even is the ratio of the two prices.** At 0.60 against 1.00, the reservation is worth it
if the machine runs more than 60% of the hours, and it loses money below that. At exactly 60% the
two cost the same, which the program reports as losing nothing. The three-year price moves the line
to 40%: a deeper discount buys tolerance for idle hours, and charges for it in years of commitment.

That gives the rule Microsoft's own guidance follows, in its order:

1. **Remove what is unused and resize what is too large first.** A discount lowers the price of
   waste; it does not remove it.
2. **Reserve what runs all the time and will not change**: the database server that has been the
   same size for a year, in the region it will stay in.
3. **Cover the moving part with a savings plan**, sized to the spending that is there every hour, not
   to the average: an average includes the quiet hours, and those are exactly the hours the plan
   would waste.
4. **Leave the rest on pay as you go**, which is the right price for anything that might not exist
   next month.

## What this lab cannot show

**Nothing in this section was bought or priced.** A reservation and a savings plan are purchases
made through Azure's billing, and their real prices come from the Retail Prices API that lesson 1's
`price.py` reads, which this machine could not reach. That program asks for `priceType eq
'Consumption'`; change the word to `Reservation` and the same list answers with reservation prices,
each the total for its term, and the term itself in a field called `reservationTerm`. Divide that
total by the hours of the term, 8,760 for one year, and `breakeven.py` takes the real numbers.
