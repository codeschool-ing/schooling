---
title: The arithmetic of waiting against keeping
version: 1
---

The common belief is that serverless is the cheap option and an instance kept running the
expensive one. **Neither is cheaper in general.** One meter counts the seconds your code runs, the
other counts the hours an instance exists, and which bill is smaller depends on how many requests
arrive. Below some rate, paying per execution wins; above it, the instance does. This section
finds that rate for the shop's order API, and then asks the question the rate does not answer:
what the cold starts below it are worth.

## The two meters

The documentation describes the meters and keeps the prices on the pricing page. Flex Consumption,
on demand, bills two things: "the total amount of memory provisioned while each on demand instance
is actively executing functions (in GB-seconds), minus a free grant of GB-s per month", and "the
total number of executions, minus a free grant (number) of executions per month". **The memory is
the instance's size, not what your code uses**: a 2,048 MB instance is billed as 2,048 MB while it
works. The documentation also sets "the minimum billable execution period" at 1,000 ms, rounded up
to the nearest 100 ms after that. An order to `take_order` takes about a tenth of a second, so when
orders arrive one at a time, each is billed as a whole second of a 2 GB instance; this section uses
that reading.

Always ready instances on Flex are billed differently: a baseline for the memory of every always
ready instance, all the time, plus the execution while they work, plus the executions, and **in
always ready billing, there are no free grants**. Premium bills cores and memory of every allocated
instance, at least one, with no execution charge. Dedicated bills the plan. Those three are the
other meter: time an instance exists, whatever it does.

## The rates, and why they are not Azure's

The machine these lessons were recorded on could not reach Microsoft's pricing pages. So **every
rate in this section is illustrative, not Azure's price.** Two of them are the ones Microsoft's own
cost article assumes in its worked example, "an on-demand execution rate of $0.000026 GB-s" and "an
on-demand rate of $0.40 per million executions", with the instruction to always check the pricing
page. The third, 150 USD a month, is a round number standing for one instance that runs all month,
whether it is a Premium EP1, a Dedicated instance or a Flex always ready one. The size of the free
grants is on the pricing page only, so the program leaves them at zero and shows where they go.
Lesson 21 shows how to put the real prices in.

Save this as `~/azure/plans.py`:

```schooling-example
{"language": "python", "file": "plans.py", "parts": [{"code": "# plans.py\n# A month of the shop's order API on demand, against one instance kept\n# running. ILLUSTRATIVE RATES, NOT AZURE'S PRICES.\nGB_SECOND = 0.000026      # USD per GB-second of an instance executing\nPER_MILLION = 0.40        # USD per million executions\nALWAYS_ON = 150.00        # USD a month for one instance that never stops\n\n", "note": "**The rates are illustrative and not Azure's prices.** The first two are the ones Microsoft's own cost article assumes in its worked example, which it tells you to check against the pricing page; the third is a round number standing for one instance that runs all month, whatever the plan calls it."}, {"code": "MEMORY_GB = 2             # a 2,048 MB instance\nBILLED_S = 1.0            # each order billed as the 1,000 ms minimum\nGRANT_GBS = 0             # the monthly free grants: from the pricing page\nGRANT_EXECUTIONS = 0\nSECONDS = 730 * 3600      # a month of 730 hours\n\n", "note": "The shop's order API on a 2,048 MB Flex instance, which Microsoft's example counts as 2 GB. Each order is billed as one second, the documented minimum. The free grants are left at zero, because their size is only on the pricing page; a month is 730 hours."}, {"code": "def on_demand(per_second):\n    requests = per_second * SECONDS\n    gbs = max(requests * MEMORY_GB * BILLED_S - GRANT_GBS, 0)\n    executions = max(requests - GRANT_EXECUTIONS, 0)\n    return gbs * GB_SECOND + executions / 1e6 * PER_MILLION\n\n\nfor rate in (0.01, 0.1, 0.5, 1, 2, 5):\n    print(f'{rate:5} req/s {rate * SECONDS:>11,.0f} a month   '\n          f'on demand {on_demand(rate):7.2f}   always on {ALWAYS_ON:.2f} USD')\n\n", "note": "The on-demand bill for a steady rate of orders: GB-seconds less the grant, at the GB-second rate, plus executions less the grant, at the rate per million. Then a line for each of six rates, against the instance that costs the same at any rate."}, {"code": "per_request = MEMORY_GB * BILLED_S * GB_SECOND + PER_MILLION / 1e6\nbreak_even = ALWAYS_ON / per_request / SECONDS\nprint(f'one request: {per_request:.7f} USD')\nprint(f'break-even: {break_even:.2f} requests a second, '\n      f'{break_even * SECONDS:,.0f} a month')\n", "note": "The price of one order on demand, and the rate at which a month of orders costs as much as the instance: the always-on price divided by the price of one request, spread over the month's seconds."}]}
```

And run it:

```
ana@laptop:~/azure$ python3 plans.py
 0.01 req/s      26,280 a month   on demand    1.38   always on 150.00 USD
  0.1 req/s     262,800 a month   on demand   13.77   always on 150.00 USD
  0.5 req/s   1,314,000 a month   on demand   68.85   always on 150.00 USD
    1 req/s   2,628,000 a month   on demand  137.71   always on 150.00 USD
    2 req/s   5,256,000 a month   on demand  275.41   always on 150.00 USD
    5 req/s  13,140,000 a month   on demand  688.54   always on 150.00 USD
one request: 0.0000524 USD
break-even: 1.09 requests a second, 2,862,595 a month
```

**At these rates the two bills cross at about one request a second**, 1.09, which is 2,862,595 a
month. At a tenth of that, the on-demand bill is 13.77 USD against 150; at five a second it is
688.54. Each order costs 0.0000524 USD, and almost all of it is the GB-second: the execution charge
is 0.0000004 of it. That is why the size of the instance moves the answer far more than the number
of requests does. The same order on a 512 MB instance costs about a quarter as much, and its
break-even nearly four times higher; it also has a quarter of a core, which the previous section saw
stretch a start on the laptop.

The free grant moves the line by a fixed amount. A grant of G GB-seconds pays for G divided by 2
orders here, since each takes 2 GB-s, so it raises the break-even by that many orders a month and
changes nothing above it.

## Concurrency changes the count of seconds

The program assumes each order has an instance to itself. Microsoft's cost article works an example
that shows what happens when they do not: an app with only HTTP triggers, 40 requests a second, 10
of them in flight at any moment, on 2,048 MB instances with no always ready ones. If the work is
CPU-bound and each request gets its own instance, ten instances are active all the time, and the
documentation's total is `$1.9296 USD` an hour. **If the work is waiting on input and output, all
ten fit on one instance, and the same requests cost `$0.245 USD` an hour**, because the meter counts
the memory of active instances, not the number of requests inside them. The executions, 0.0576 USD
an hour, are the same in both. For the shop, whose `take_order` does little but hand an order to a queue,
the real per-order cost is somewhere below the one the program prints, and the break-even
correspondingly higher.

## What the break-even does not say

The shop's order API took about 400,000 orders last month, about 0.15 a second, almost all of them
between eight in the morning and eleven at night. At these rates that is about 21 USD on demand
against 150 for an instance. So by the money alone, on demand wins, by a factor of seven.

**Below the break-even, an instance kept ready is bought for latency, not for savings.** At night
the order API is idle for many minutes at a time, and the documentation says an idle app may be
scaled to zero after a few minutes. So the first customer of the morning meets a cold start, and so
does the first one after every quiet stretch. Keeping one instance ready removes those, and at these
rates it costs about 129 USD a month more than not doing it. Whether that is worth paying is a
question about customers, not about arithmetic: how many orders a month meet a cold start, and how
many of those people give up.

The same reasoning, run for `make_receipt` or the nightly finance export, comes out the other way
almost at once. Nobody waits behind a queue trigger, so a cold start costs a few seconds that
nobody sees, and the instance kept for it would buy nothing. **Readiness is worth paying for only
where somebody is waiting**, and the two meters let you pay for it exactly there: one always ready
instance for the `http` group, and none for the rest.
