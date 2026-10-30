---
title: Sustained use: the discount nobody asks for
version: 1
---

**A sustained use discount is applied by Google on its own, to machines that run for a large part of the
month.** Nobody signs anything. The pricing page states the rule, read on 30 October 2026: resources *used
for more than 25% of a billing month* receive *a discount for every incremental hour*, up to *a 30% net
discount* for a machine that runs the whole month, and the discount arrives as a credit at the end of it.

The 30% is not one cut applied to the month. **Each quarter of the month is billed at a lower share of the
base price than the one before.** For the N1 machine types, the tiers Google documents are:

| part of the month the machine has run | billed at |
|---|---|
| the first 25% | 100% of the base price |
| from 25% to 50% | 80% |
| from 50% to 75% | 60% |
| from 75% to 100% | 40% |

A machine that runs all month pays 100, 80, 60 and 40 for its four quarters, an average of 70: the 30% net
discount. Other machine types have tiers of their own, smaller: N2 machines top out near 20%. **E2 machines
receive none**, because their on-demand price is already lower, and neither do Spot machines or anything
covered by a commitment: the pricing page says discounts *cannot be combined*.

## The tiers, as arithmetic

The program below works out what the tiers do to one month of one N1 machine. The price is an argument,
because the real one depends on the machine type and the region, and is on the pricing page; the lesson
uses **0.10 dollars an hour as an example**, not a price Google charges for anything in particular. Save it
as `~/gcp/sud.py`:

```schooling-example
{"language": "python", "file": "sud.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"What sustained use does to one N1 machine's month, tier by tier.\n\n    python3 sud.py PRICE SHARE\n\nPRICE is the machine's on-demand price per hour, in USD; SHARE the fraction\nof the month it ran, from 0 to 1.\n\"\"\"\nimport sys\n\n", "note": "Two arguments: the price an hour, and how much of the month the machine ran. A machine that ran half the month is `0.5`."}, {"code": "HOURS = 730  # the hours Google's pricing uses for a month\nTIERS = [(0.25, 1.00), (0.25, 0.80), (0.25, 0.60), (0.25, 0.40)]\n\n", "note": "The tiers of the table above, each a quarter of the month and the share of the base price it is billed at. 730 is the number of hours Google's price pages use for a month."}, {"code": "price, share = float(sys.argv[1]), float(sys.argv[2])\nleft, cost = share, 0.0\nfor width, rate in TIERS:\n    used = min(left, width)\n    cost += used * HOURS * price * rate\n    left -= used\n\n", "note": "Walk the tiers in order, filling each one before the next, until the machine's share of the month is used up. Each tier contributes its hours at its own rate."}, {"code": "full = share * HOURS * price\nprint(f'{share:.0%} of the month: {share * HOURS:.0f} hours')\nprint(f'  on demand {full:8.2f} USD')\nprint(f'  billed    {cost:8.2f} USD, a discount of {1 - cost / full:.1%}')\n", "note": "The comparison: what the hours would cost at the on-demand price, what the tiers make of them, and the difference as a share."}]}
```

Run it for a machine that ran a quarter, half, three quarters and all of the month:

```
ana@laptop:~/gcp$ python3 sud.py 0.10 0.25
25% of the month: 182 hours
  on demand    18.25 USD
  billed       18.25 USD, a discount of 0.0%
ana@laptop:~/gcp$ python3 sud.py 0.10 0.5
50% of the month: 365 hours
  on demand    36.50 USD
  billed       32.85 USD, a discount of 10.0%
ana@laptop:~/gcp$ python3 sud.py 0.10 0.75
75% of the month: 548 hours
  on demand    54.75 USD
  billed       43.80 USD, a discount of 20.0%
ana@laptop:~/gcp$ python3 sud.py 0.10 1
100% of the month: 730 hours
  on demand    73.00 USD
  billed       51.10 USD, a discount of 30.0%
```

**Nothing for the first quarter, then the discount grows**: 10% for half a month, 20% for three quarters,
30% for the whole month. Two practical consequences come out of those four numbers. A machine that runs
only office hours, about a third of the month, earns almost nothing from sustained use. And **two machines
that run half the month each, one after the other, are treated by Google as one machine running all month**,
when they are the same type in the same region: the discount follows the resources, not the instance names.
The arithmetic is the program's; the tiers and that last rule are Google's documentation.
