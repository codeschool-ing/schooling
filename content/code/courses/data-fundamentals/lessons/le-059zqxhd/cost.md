---
title: What it costs, and what multiplies it
version: 1
---

**The bill for data is rarely the size of the data. It is the size, times how long it is kept, times
how often it is read and moved.** The first factor is the one people estimate, and the other two are
the ones that surprise them, because they are decided later, by other people, one reasonable
decision at a time.

A data platform pays for four things, and a fifth that is not on any invoice:

| what | paid by | what makes it grow |
|---|---|---|
| **storage** | the gigabyte, per month | volume, and every month it is kept |
| **compute** | the hour of a machine, or the terabyte a query engine reads | how much is read, how often |
| **transfer** | the gigabyte that leaves a provider's network | copies out: to a laptop, another cloud, a partner |
| **calls** | the thousand requests to a paid API | how often you poll |
| people | the hours spent keeping it running | every run that can fail, every rule that needs an owner |

## A year of sensor readings, priced

The prices in this program are **invented for this lesson**. They are of a plausible order, and they
are not any provider's: real prices differ by provider, region and year, and change without asking.
What carries over is the shape of the sum. The volume is the 22.2 MB a day that section 03 measured.
Save it as `collect/cost.py`:

```python
# collect/cost.py
# Unit prices INVENTED FOR THIS LESSON, in reais. Real ones differ by
# provider, by region and by year; the shape of the sum is what carries over.
KEEP_GB_MONTH = 0.15      # to keep 1 GB stored for a month
READ_TB = 30.00           # for a query engine to read 1 TB
OUT_GB = 0.50             # for 1 GB to leave the provider's network
CALLS_1000 = 0.02         # for 1,000 calls to a paid API

GB_A_DAY = 22.2 / 1000    # the dock sensors, as volume.py measured them
stored = GB_A_DAY * 365   # a year of them, all kept

refreshes = 24 * 60 // 5 * 30            # a dashboard refreshed every 5 minutes, for a month
costs = {
    "keeping a year of it": stored * KEEP_GB_MONTH,
    "polling an API every minute": 24 * 60 * 30 / 1000 * CALLS_1000,
    "copying the year out weekly": stored * 4 * OUT_GB,
    "a dashboard reading the year": stored * refreshes / 1000 * READ_TB,
    "the same, reading only today": GB_A_DAY * refreshes / 1000 * READ_TB,
}
print(f"stored after a year: {stored:.1f} GB; refreshes a month: {refreshes}")
for what, reais in costs.items():
    print(f"{what:30} R$ {reais:8.2f} a month")
```

```
ana@lab:~/roda/collect$ python cost.py
stored after a year: 8.1 GB; refreshes a month: 8640
keeping a year of it           R$     1.22 a month
polling an API every minute    R$     0.86 a month
copying the year out weekly    R$    16.21 a month
a dashboard reading the year   R$  2100.30 a month
the same, reading only today   R$     5.75 a month
```

Keeping the whole year costs R$ 1.22 a month, and the minute-by-minute polling R$ 0.86. Neither is
worth a meeting. Copying the year out to somebody's laptop every week costs more than keeping it,
R$ 16.21, because the data is stored once and transfer is paid again on every copy. **The dashboard
is the bill**: R$ 2100.30 a month, because it reads all 8.1 GB on every one of its 8640 refreshes. The same dashboard reading only today's data costs R$ 5.75, which is
the same number divided by the 365 days it stopped reading.

Nothing about the data changed between those two lines. What changed is whether a query can find
today without reading the rest. That depends on how the data was laid out when it was collected: in
one directory per day, as lesson 3 stored its raw rides, a query for today opens one
directory. Laid out as one growing file, the same query reads the year. **The cheapest moment to
decide the layout is before the first copy**, because changing it later means rewriting everything
already stored.

## Where to look first

- Find the multiplier. A cost that grows with refreshes, or users, or the number of copies, will
  outgrow a cost that grows with volume. Here it is the 8640.
- Ask about the frequency again. A dashboard refreshed every five minutes for a report Marta reads
  at nine is the freshness question of section 04, asked by the bill.
- Decide how long each thing is kept. Raw data is kept, and lesson 3 says why; that does not mean
  kept where it is most expensive to keep. Storage classes and the rest of a provider's price list
  are `cloud`.
- Put a price beside every estimate. A volume estimate with no cost next to it is half an answer
  to Caio, and the half that is easier to agree to.
