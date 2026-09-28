---
title: A function or a machine
version: 1
---

The bill in the previous section is small because the load is small. **A function's cost is
proportional to use; a machine's cost is proportional to time.** At low or spiky traffic that
favours the function, which costs nothing between bursts, while a machine costs the same at four in
the morning as at noon. At steady high traffic it favours the machine, which serves request after
request for the same hourly price. Somewhere between the two the lines cross, and the price sheet is
enough to find where.

## The two lines

Take the workload of the previous section, 512 MB and 120 ms per request, and leave the free tier
out: it is an allowance per account, not a property of either design. One million requests cost
0.20 USD in requests plus 1,000,000 × 0.5 × 0.120 × 0.0000166667 = 1.00 USD in duration, so
**1.20 USD per million requests.**

Against it, machines from the same sheet, `us-east-1`, on demand. A t3.medium is 0.04160 USD an hour,
and AWS counts a month as 730 hours: 0.04160 × 730 = 30.37 USD. **But one machine is not the same
service as a function.** It has no second copy when it fails and nothing in front of it to spread the
load; lesson 4 argued for at least two behind a load balancer. Two t3.medium and an Application Load
Balancer at 0.0225 USD an hour: (2 × 0.04160 + 0.0225) × 730 = 77.16 USD.

The crossing is each monthly cost divided by the function's cost per million:

```python
# us-east-1, from `python3 prices.py`: on demand, USD per hour.
T3_MEDIUM = 0.04160
ALB = 0.0225
HOURS = 730                   # a month, as AWS counts one

# One million requests at 512 MB and 120 ms, as in bill.py, no free tier.
per_million = 0.20 + 1_000_000 * (512 / 1024) * 0.120 * 0.0000166667

for label, month in [("one t3.medium", T3_MEDIUM * HOURS),
                     ("two t3.medium + ALB", (2 * T3_MEDIUM + ALB) * HOURS)]:
    crossover = month / per_million
    per_second = crossover * 1_000_000 / (HOURS * 3600)
    print(f"{label:<20} {month:7.2f} USD a month   "
          f"break-even {crossover:5.1f} million requests ({per_second:4.1f} a second)")
print(f"Lambda, per million  {per_million:7.2f} USD")
```

```
ana@laptop:~/cloud$ python3 crossover.py
one t3.medium          30.37 USD a month   break-even  25.3 million requests ( 9.6 a second)
two t3.medium + ALB    77.16 USD a month   break-even  64.3 million requests (24.5 a second)
Lambda, per million     1.20 USD
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"A chart of monthly cost in US dollars against requests per month, from zero to 80 million. The function's cost is a straight line from zero, 1.20 dollars per million requests. One t3.medium costs a flat 30.37 dollars a month and the lines cross at 25.3 million requests. Two t3.medium behind a load balancer cost a flat 77.16 dollars and the lines cross at 64.3 million.\"><defs><marker id=\"sl-cross-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M80 250.0 L680 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"72\" y=\"250.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M80 195.0 L680 195.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"72\" y=\"195.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">25</text><path d=\"M80 140.0 L680 140.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"72\" y=\"140.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">50</text><path d=\"M80 85.0 L680 85.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"72\" y=\"85.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">75</text><path d=\"M80 30.0 L680 30.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\"></path><text x=\"72\" y=\"30.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">100</text><path d=\"M80.0 250 L80.0 255\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"80.0\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M230.0 250 L230.0 255\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"230.0\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">20</text><path d=\"M380.0 250 L380.0 255\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"380.0\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">40</text><path d=\"M530.0 250 L530.0 255\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"530.0\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">60</text><path d=\"M680.0 250 L680.0 255\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"680.0\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">80</text><text x=\"380.0\" y=\"288\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">requests a month, in millions (512 MB, 120 ms each)</text><text x=\"20\" y=\"16\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">USD a month</text><path d=\"M80 183.2 L680 183.2\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"86\" y=\"173.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">one t3.medium, always on</text><path d=\"M80 80.2 L680 80.2\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"86\" y=\"70.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">two t3.medium and a load balancer</text><path d=\"M80 250.0 L680.0 38.8\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><text x=\"350.0\" y=\"135.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">Lambda: 1.20 per million</text><circle cx=\"269.8\" cy=\"183.2\" r=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></circle><path d=\"M269.8 188.2 L269.8 250\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"275.8\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">25.3</text><circle cx=\"562.2\" cy=\"80.2\" r=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></circle><path d=\"M562.2 85.2 L562.2 250\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"568.2\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">64.3</text></svg>", "caption": "Left of a crossing the function is cheaper; right of it the machine is. Every number is a line of the price sheet, us-east-1, on demand, no free tier."}
```

Read as traffic, 25.3 million requests a month is 9.6 a second on average, all day, every day.
**Below that, the function beats even one bare machine; above 64.3 million, a properly built pair
beats the function.** Most small APIs, internal tools and back offices sit far to the left of the
first crossing. A busy public API sits to the right of the second.

## What the chart leaves out

Every line on it is from the sheet, and each of these would move a line:

- Whether a t3.medium can serve this work at 24.5 requests a second is a measurement, not
  arithmetic. If it cannot, the machine line steps up to bigger machines.
- The function line leaves out the API gateway, which bills per request and so moves the crossings
  to the left.
- The machine line leaves out the disks, the load balancer's charge for the traffic it handles,
  which is billed apart from its hourly price and is not on the sheet, and the hours somebody spends
  patching and watching the machines: the operations cost serverless removes, which no price sheet
  lists.
- Reserved pricing, lesson 10's subject, lowers the machine line. The sheet's 1-year price for a
  t3.medium in `us-east-1` is 0.02610 USD an hour: 0.02610 × 730 = 19.05 USD a month, and
  19.05 / 1.20 moves the first crossing from 25.3 to 15.9 million.

**And an average hides the shape of the traffic.** A machine has to be sized for the busiest hour,
not the average one. Take two workloads with the same monthly total, one steady and one that arrives
in a two-hour rush every evening. They cost the function the same and cost the machine very
differently, because the rushed one needs a bigger machine that idles for the other twenty-two
hours. Spiky traffic moves
your real position to the left of the chart, towards the function.
