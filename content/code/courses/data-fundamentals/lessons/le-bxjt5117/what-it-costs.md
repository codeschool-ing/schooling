---
title: What it costs, all of it
version: 1
---

**The total cost of a technology is its bill plus the hours of the people who run it plus the price
of leaving it.** The common picture stops at the first term, usually at a single unit price: so much
per gigabyte stored, so much per hour of server. Two things make that picture wrong. Most bills are
shaped far more by how a tool is *used* than by its unit prices. And at a company the size of Roda
Livre, the largest line is rarely on any bill at all.

A short program makes both visible. **Every price in it is invented for this lesson**, in reais a
month, chosen to be round rather than to match any provider; real prices vary by provider, region and
year, and the method is what carries over. Save it as `cost.py`:

```python
# choose/cost.py
# EVERY PRICE HERE IS INVENTED FOR THIS LESSON, in reais a month.
STORE_GB = 0.15       # keeping one gigabyte for a month
SCAN_TB = 30.00       # a query engine reading one terabyte
SERVER_H = 0.60       # one hour of a small server we run ourselves
PERSON_H = 120.00     # one hour of an engineer's time

# 120 docks, one reading a minute, about 60 bytes a reading, kept a year
year_gb = 120 * 24 * 60 * 365 * 60 / 1e9


def month(scans, gb_per_scan, server_hours, person_hours):
    return {
        "storage": year_gb * STORE_GB,
        "queries": scans * gb_per_scan / 1000 * SCAN_TB,
        "server": server_hours * SERVER_H,
        "people": person_hours * PERSON_H,
    }


PLANS = {
    "managed, every 5 min": month(12 * 24 * 30, year_gb, 0, 2),
    "managed, once a day": month(30, year_gb / 365, 0, 2),
    "our own server": month(0, 0, 24 * 30, 10),
}

print(f"a year of dock readings: {year_gb:.2f} GB")
print(f"{'':21}{'storage':>9}{'queries':>9}{'server':>9}{'people':>9}{'total':>10}")
for name, lines in PLANS.items():
    cells = "".join(f"{v:9.2f}" for v in lines.values())
    print(f"{name:21}{cells}{sum(lines.values()):10.2f}")
```

Three plans for the same year of dock readings. The first two use a managed engine that charges for
every terabyte a query reads: one refreshes a dashboard every five minutes and reads the whole year
each time, the other runs once a day and reads only the day before. The third is a server the team
runs, which charges nothing per query and needs ten hours of somebody's month.

```
ana@lab:~/roda/choose$ python cost.py
a year of dock readings: 3.78 GB
                       storage  queries   server   people     total
managed, every 5 min      0.57   980.90     0.00   240.00   1221.46
managed, once a day       0.57     0.01     0.00   240.00    240.58
our own server            0.57     0.00   432.00  1200.00   1632.57
```

## Reading the bill

**Storage costs next to nothing in every plan.** A year of readings from 120 docks is 3.78 GB, and
keeping it costs 0.57 a month. Deleting old data to save on storage, the one-way door from earlier
in this lesson, would save less than a real a month.

**How the engine is used moves the bill by a factor of about a hundred thousand.** The same managed engine,
at the same unit price, costs 980.90 a month in queries when a dashboard re-reads a year of data
every five minutes, and 0.01 when a job reads one day, once. Nothing about the tool differs. The
first plan answers a question nobody asked every five minutes; the skills section's question, *when
do you need it?*, is worth nearly a thousand reais a month here.

**People are the largest line of the two sensible plans.** In "managed, once a day" the bill is under
one real and the two hours of an engineer are 240.00. In "our own server" there is no charge per
query at all, and the plan is the most expensive of the three, at 1632.57, because ten hours of
upkeep cost 1200.00. "Self-hosted is cheaper" usually compares one plan's bill with the other plan's
total.

## The third term: leaving

The program has no line for the exit, and every real choice has one. Leaving a technology costs the
hours to rewrite what depends on it, the risk of the move itself, and often a charge from the
provider for moving data out of its network, which many bill per gigabyte. That cost is paid once and
much later, which is why it is easy to leave out of a comparison and expensive to discover. Lock-in,
among the criteria earlier in this lesson, is this line seen in advance.

Lesson 7 does the same arithmetic for collecting data: volume, frequency and the price of each. The
numbers in a real comparison come from the provider's own price list and from your own measurement of
how the tool will be used, and `tech-strategy` and `cloud` go further into both.
