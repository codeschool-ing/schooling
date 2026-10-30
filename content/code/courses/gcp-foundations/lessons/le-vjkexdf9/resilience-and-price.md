---
title: Resilience, and what it costs
version: 1
---

**Availability is bought in pairs.** Every design that Google offers 99.99% for is two of something where one
would work: two HA VPN tunnels where one would carry the traffic, two Interconnect connections in each of two
cities where one would. The question for the planner is not which design is best but which number its office
link has to meet, and the arithmetic that answers it fits in a dozen lines.

Google's documents give the designs, read on 30 October 2026:

| design | what it takes | availability offered |
|---|---|---|
| one VPN tunnel | Classic VPN | 99.9% |
| HA VPN | two tunnels, one from each of the gateway's interfaces | 99.99% |
| Interconnect, one city | two connections in one metropolitan area, in different edge availability domains | 99.9% |
| Interconnect, two cities | two such pairs, in two metropolitan areas | 99.99% |

And the prices, from the Cloud VPN and Cloud Interconnect pricing pages on the same day: **0.05 USD an hour
for each VPN tunnel**, for Iowa, the page's default region; **2.328 USD an hour for a 10 Gbps Dedicated
connection** and **0.10 USD an hour for each VLAN attachment** up to 10 Gbps. Data leaving through an
Interconnect from South America to South America is **0.11 USD per GiB**; data through a VPN is billed as
ordinary internet egress.

## Four designs, side by side

Save this as `~/gcp/sla.py`:

```schooling-example
{"language": "python", "file": "sla.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"What an availability figure allows, in minutes down and in dollars a month.\n\n    python3 sla.py PERCENT HOURLY_USD [PERCENT HOURLY_USD ...]\n\nEach pair is a design: the availability it is offered at, and what its\nparts cost an hour together.\n\"\"\"\nimport sys\n\n", "note": "How it is called: pairs of numbers, one pair per design, the availability and the hourly price of everything the design needs."}, {"code": "HOURS = 730            # the hours Google's pricing uses for a month\nMINUTES = 30 * 24 * 60 # a 30-day month, the way availability is usually counted\n\n", "note": "Two months, on purpose. Prices are per hour, and Google's price pages turn hours into a month with 730; availability is a share of the time, and a 30-day month is the round figure people quote it against."}, {"code": "args = sys.argv[1:]\nfor percent, hourly in zip(args[0::2], args[1::2]):\n    down = MINUTES * (1 - float(percent) / 100)\n    print(f'{percent:>6}%  up to {down:6.1f} min down a month  {float(hourly) * HOURS:9.2f} USD a month')\n", "note": "For each design, the minutes a month its availability still allows to be lost, and what its parts cost in a month. Nothing in it knows what VPN or Interconnect is: the two numbers are the whole design, as far as this question goes."}]}
```

The four designs: one tunnel; two; two 10 Gbps connections with an attachment each; four of them:

```
ana@laptop:~/gcp$ python3 sla.py 99.9 0.05 99.99 0.10 99.9 4.856 99.99 9.712
  99.9%  up to   43.2 min down a month      36.50 USD a month
 99.99%  up to    4.3 min down a month      73.00 USD a month
  99.9%  up to   43.2 min down a month    3544.88 USD a month
 99.99%  up to    4.3 min down a month    7089.76 USD a month
```

**The second tunnel costs 36.50 dollars a month and buys about 39 minutes a month back**, which is why the
planner has two and nobody argues about it. The jump to Interconnect is a different decision altogether: its
cost is dominated by the circuits, not by the availability, and it is justified by bandwidth and by the
transfer price, never by the extra nine, which HA VPN already gives. These are Google's hourly prices only;
the colocation facility, the cross-connect and the office's own internet line are bills of their own.

## What the planner chose

**HA VPN, two tunnels, to two addresses on the office's router**, with the BGP of the first section. It meets
the office's need, a few hundred megabits for its staff and its nightly backups, at 73 dollars a month plus
egress. The point at which that changes is written down in advance rather than discovered in an incident:
when the tunnels run above half their capacity for a month, or when the nightly transfer is large enough that
Interconnect's 0.11 a GiB, with its circuits, costs less than the VPN's internet egress.
