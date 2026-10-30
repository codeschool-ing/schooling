---
title: The break-even between bytes and slots
version: 1
---

**On demand and slots cost the same when a TiB of queries uses a particular number of slot-hours,
and the two prices fix that number.** On demand charges 11.25 USD for a TiB. An Enterprise slot-hour
costs 0.093 USD. So a workload that uses 11.25 ÷ 0.093, about 121 slot-hours for every TiB it reads,
costs the same either way. **A workload that needs more compute per byte than that** is cheaper on
demand, because on demand charges nothing for the compute. **A workload that needs less** is cheaper
on slots, because slots charge nothing for the bytes.

That ratio, slot-hours per TiB, is the number to know about a workload, and it is not the number
anybody thinks of first. People compare the monthly totals, and the totals do not say why one model
won.

## The program

Save this as `~/gcp/breakeven.py`:

```schooling-example
{"language": "python", "file": "breakeven.py", "parts": [{"code": "import sys\n\n# USD, southamerica-east1, cloud.google.com/bigquery/pricing, read 2026-10-30\nON_DEMAND_PER_TIB, FREE_TIB = 11.25, 1\nAUTOSCALED = {'Standard': 0.062, 'Enterprise': 0.093, 'Enterprise Plus': 0.155}\nCOMMITTED = {'Enterprise, 1 year': 0.0744, 'Enterprise, 3 years': 0.0558}\nHOURS, SMALLEST = 730, 50\n\n", "note": "**Every price is the page's, for São Paulo.** The three editions at their pay-as-you-go rate, the two Enterprise commitments, and the free TiB of on-demand queries. A month is 730 hours, the page's own convention: 0.093 × 730 is the 67.89 USD a month it prints for one Enterprise slot. 50 slots is the smallest commitment the page allows."}, {"code": "tib, slot_hours = float(sys.argv[1]), float(sys.argv[2])\nprint(f'a month of {tib:,g} TiB billed, using {slot_hours:,g} slot-hours')\nprint(f'  {\"on demand\":<31}{max(tib - FREE_TIB, 0) * ON_DEMAND_PER_TIB:>10,.2f} USD')\n", "note": "**A month of work is two numbers**: the TiB its queries would be billed on demand, and the slot-hours they would use on slots. Neither is measurable here. On a real project both are in the `INFORMATION_SCHEMA.JOBS` view, one row per query, as `total_bytes_billed` and `total_slot_ms`. On demand subtracts the free TiB and multiplies."}, {"code": "for name, price in AUTOSCALED.items():\n    tie = ON_DEMAND_PER_TIB / price\n    print(f'  {name + \", autoscaled\":<31}{slot_hours * price:>10,.2f} USD'\n          f'   same as on demand at {tie:,.0f} slot-hours a TiB')\n", "note": "**Autoscaled slots cost the slot-hours times the price**, with nothing reserved. `tie` is the number this whole section is about: how many slot-hours a TiB of queries can use before slots cost more than reading that TiB on demand. It depends only on the two prices."}, {"code": "for name, price in COMMITTED.items():\n    print(f'  {name + \", 50 slots\":<31}{SMALLEST * HOURS * price:>10,.2f} USD'\n          f'   {SMALLEST * HOURS:,} slot-hours, used or not')\n", "note": "**A commitment is paid for every hour of the month**, whatever the queries do, so it is printed as what the smallest one costs. It is only cheaper per slot-hour when its slots are busy."}]}
```

**The two numbers for a real month come from `INFORMATION_SCHEMA.JOBS`**, and in this lab they come
from nowhere: a DuckDB query has no slots and no bytes billed. So the two months below are stated,
not measured. The first is Quitanda's analysts: ad hoc questions with joins, window functions and
string work, 3 TiB billed and 600 slot-hours, 200 a TiB. The second is the nightly transformations:
wide scans that filter and add up, 40 TiB billed and 2,500 slot-hours, about 62 a TiB.

```
ana@laptop:~/gcp$ python3 breakeven.py 3 600
a month of 3 TiB billed, using 600 slot-hours
  on demand                           22.50 USD
  Standard, autoscaled                37.20 USD   same as on demand at 181 slot-hours a TiB
  Enterprise, autoscaled              55.80 USD   same as on demand at 121 slot-hours a TiB
  Enterprise Plus, autoscaled         93.00 USD   same as on demand at 73 slot-hours a TiB
  Enterprise, 1 year, 50 slots     2,715.60 USD   36,500 slot-hours, used or not
  Enterprise, 3 years, 50 slots    2,036.70 USD   36,500 slot-hours, used or not
ana@laptop:~/gcp$ python3 breakeven.py 40 2500
a month of 40 TiB billed, using 2,500 slot-hours
  on demand                          438.75 USD
  Standard, autoscaled               155.00 USD   same as on demand at 181 slot-hours a TiB
  Enterprise, autoscaled             232.50 USD   same as on demand at 121 slot-hours a TiB
  Enterprise Plus, autoscaled        387.50 USD   same as on demand at 73 slot-hours a TiB
  Enterprise, 1 year, 50 slots     2,715.60 USD   36,500 slot-hours, used or not
  Enterprise, 3 years, 50 slots    2,036.70 USD   36,500 slot-hours, used or not
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"A chart of cost per TiB read against slot-hours used per TiB, from 0 to 250. On demand is a flat line at 11.25 USD. Standard, Enterprise and Enterprise Plus are lines rising from zero at 0.062, 0.093 and 0.155 USD per slot-hour, crossing the flat line at 181, 121 and 73 slot-hours a TiB. Two marks: the nightly transformations at about 62, where every edition is under the line, and the analysts at 200, where every edition is above it.\" data-fig=\"l14-tie\"><polyline points=\"80,280 680,280\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></polyline><polyline points=\"80,280 80,40\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></polyline><text x=\"80.0\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"200.0\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">50</text><text x=\"320.0\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">100</text><text x=\"440.0\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">150</text><text x=\"560.0\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">200</text><text x=\"680.0\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">250</text><text x=\"72\" y=\"280.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"72\" y=\"184.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><text x=\"72\" y=\"88.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">20</text><text x=\"380.0\" y=\"314\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">slot-hours used per TiB read</text><text x=\"80\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">USD per TiB read</text><polyline points=\"80.0,172.0 680.0,172.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></polyline><text x=\"680.0\" y=\"186.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">on demand, 11.25</text><polyline points=\"80.0,280.0 467.09677419354836,40.0\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></polyline><text x=\"463.09677419354836\" y=\"32.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">Enterprise Plus</text><polyline points=\"255.2,172.0 255.2,280\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"3 3\"></polyline><text x=\"255.2\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">73</text><polyline points=\"80.0,280.0 680.0,56.79999999999998\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></polyline><text x=\"676.0\" y=\"48.79999999999998\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">Enterprise</text><polyline points=\"370.4,172.0 370.4,280\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"3 3\"></polyline><text x=\"370.4\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">121</text><polyline points=\"80.0,280.0 680.0,131.2\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></polyline><text x=\"676.0\" y=\"123.19999999999999\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">Standard</text><polyline points=\"514.4,172.0 514.4,280\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"3 3\"></polyline><text x=\"514.4\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">181</text><rect x=\"224.8\" y=\"261.6\" width=\"8\" height=\"8\" rx=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"228.8\" y=\"251.60000000000002\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">transformations, 62</text><rect x=\"556.0\" y=\"261.6\" width=\"8\" height=\"8\" rx=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"560.0\" y=\"251.60000000000002\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">analysts, 200</text></svg>", "caption": "Each edition crosses on demand at its own number of slot-hours a TiB. To the left of a crossing, slots are cheaper; to the right, on demand is."}
```

**The analysts are cheaper on demand, and the transformations are cheaper on slots.** At 200
slot-hours a TiB, the analysts are above every tie but Standard's: on demand is 22.50 USD, Enterprise
autoscaled is 55.80 and Enterprise Plus is 93. Standard, at 37.20, is still dearer than on demand,
since 200 is above its tie of 181. At about 62 slot-hours a TiB, the transformations are below every
tie: on demand is 438.75 USD, Enterprise is 232.50 and Standard is 155.

**The commitments lose both times.** Fifty slots for a year cost 2,715.60 USD a month, and for three
years 2,036.70, because a commitment is 36,500 slot-hours whether or not anybody uses them. The
analysts used 600 and the transformations 2,500. A commitment only wins for a workload that keeps its
slots busy for most of the month, and Quitanda has none: its warehouse is busy at night and in office
hours and idle the rest.

## Choosing, in the order the arithmetic suggests

**Start on demand.** It costs nothing until a query runs, the first TiB is free, and it is the only
model whose bill can be predicted before a query runs: lesson 16's dry run prints the bytes. For a
small company with a small warehouse it is the right model for a long time, and Quitanda's orders
table, in lesson 13, is a table on which almost every query costs the 10 MB minimum.

**Move a workload to slots when its slot-hours per TiB fall well below the tie**, which is the shape of
large scans with little computation per byte, or when the 2,000 shared slots of on demand stop being
enough for the queries that matter. Move it per project, with an assignment, and leave the rest on
demand: the analysts and the transformations do not have to share a model.

**Use the edition the features require, and no higher.** The ties fall as the edition rises, 181 for
Standard, 121 for Enterprise and 73 for Enterprise Plus, so every edition above what a workload needs
makes slots lose to on demand sooner.

**Commit last, and only to the floor.** A commitment for the baseline that is busy all month, with
autoscaling above it, is cheaper than autoscaling everything; a commitment sized to the peak is the
100 slots of the editions section, paid for at three in the afternoon of a Sunday.
