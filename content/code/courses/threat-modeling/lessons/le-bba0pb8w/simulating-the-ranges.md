---
title: Simulating the ranges
version: 1
---

Multiplying two ranges does not give a range anybody can use, because the extremes rarely happen
together. What does work is **simulation**: imagine many years, and in each one draw a frequency and
a set of losses from the ranges, add them up, and look at what the years look like together. It is
called a **Monte Carlo** simulation, and it is how FAIR analyses are computed in practice.

`fair.py` does it for the nine risks of lesson 9, in about fifty lines and the standard library:

```schooling-example
{"language": "python", "file": "fair.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Simulate ten thousand years of the risks in risks.csv, from their 90% ranges.\"\"\"\nimport csv\nimport math\nimport random\n\nYEARS = 10_000\nrng = random.Random(2026)   # a fixed seed: the same years on every run\n\n", "note": "Ten thousand simulated years, and a random generator with a fixed seed: a simulation that gives different numbers on every run cannot be quoted in a lesson, or in a report."}, {"code": "def lognormal(low, high):\n    \"\"\"A lognormal whose 5th and 95th percentiles are low and high.\"\"\"\n    mu = (math.log(low) + math.log(high)) / 2\n    sigma = (math.log(high) - math.log(low)) / (2 * 1.645)\n    return rng.lognormvariate(mu, sigma)\n\n", "note": "A 90% range becomes a lognormal distribution: 1.645 standard deviations either side of the middle cover 90%, measured on the logarithm of the value."}, {"code": "def events(rate):\n    \"\"\"How many events happen in one year, at an average of rate per year.\"\"\"\n    n, p, limit = 0, rng.random(), math.exp(-rate)\n    while p > limit:\n        n, p = n + 1, p * rng.random()\n    return n\n", "note": "How many events happen in one year at a given average rate: a Poisson count, drawn by multiplying random numbers until they fall below e to the minus rate."}, {"code": "\nrisks = list(csv.DictReader(open(\"risks.csv\")))\nyears = []\nfor _ in range(YEARS):\n    year = {}\n    for r in risks:\n        n = events(lognormal(float(r[\"per_year_low\"]), float(r[\"per_year_high\"])))\n        year[r[\"id\"]] = sum(lognormal(float(r[\"loss_low\"]), float(r[\"loss_high\"])) for _ in range(n))\n    years.append(year)", "note": "Each year, for each risk: draw a rate from the frequency range, draw how many events happen at that rate, and draw a loss for each event from the loss range."}, {"code": "\n\ndef percentile(values, p):\n    return sorted(values)[int(p * len(values))]\n\n\nprint(f\"{'':4} {'mean R$':>10} {'any loss':>9} {'1 year in 10':>13} {'1 in 100':>11}\")\nfor r in risks:\n    v = [y[r[\"id\"]] for y in years]\n    print(f\"{r['id']:4} {sum(v) / YEARS:10,.0f} {sum(x > 0 for x in v) / YEARS:9.1%} \"\n          f\"{percentile(v, 0.9):13,.0f} {percentile(v, 0.99):11,.0f}\")\ntotal = [sum(y.values()) for y in years]\nprint(f\"{'all':4} {sum(total) / YEARS:10,.0f} {sum(x > 0 for x in total) / YEARS:9.1%} \"", "note": "Per risk and for all of them together: the mean, the share of years with any loss, and the loss in the worst year in ten and in a hundred."}, {"code": "      f\"{percentile(total, 0.9):13,.0f} {percentile(total, 0.99):11,.0f}\")\n\nprint(\"\\nchance that one year's total loss is more than\")\nfor limit in (100_000, 250_000, 500_000, 1_000_000):\n    print(f\"  R$ {limit:>9,}  {sum(x > limit for x in total) / YEARS:6.1%}\")", "note": "Four points of the loss exceedance curve: the chance that a year's total is larger than each amount."}]}
```

Ten thousand simulated years, with a fixed seed so that every run gives the same years:

```
(.venv) ana@vm:~/tm/portal-model$ python3 fair.py
        mean R$  any loss  1 year in 10    1 in 100
T01      10,969     40.4%        34,314      98,263
T02      11,375     97.4%        23,292      43,928
T03     119,050     25.1%       403,311   1,548,742
T07      31,347     22.6%       107,558     413,584
T08       6,623     77.9%        16,893      38,557
T10       4,959     61.7%        13,652      30,517
T11       3,419     77.9%         8,634      18,542
T13      33,871      7.1%             0     790,053
T14      19,765      9.9%             0     411,848
all     241,376    100.0%       645,467   1,899,724
```

### Reading the table

**The mean is higher than lesson 9's product, for every risk.** T03's best guess gave R$ 75,000 a
year; the simulation gives R$ 119,050. Nothing is wrong. The ranges are skewed, with long tails to
the right: the worst case for T03 is a million reais, the best is sixty thousand, and the best guess
of a quarter of a million sits nearer the bottom. An average over the whole range includes the tail,
and the tail is expensive. **The total moves from R$ 139,400 to R$ 241,376**, and the difference is
the uncertainty the best guesses were hiding.

**"Any loss" is the chance of at least one event in a year.** T02 happens in 97.4% of years; T13 in
7.1%. That is lesson 9's last section, now for every risk.

**"1 year in 10" is the loss a bad year reaches**: in 10% of years, T03 costs R$ 403,311 or more.
For T13 and T14 that column is zero, because they happen in fewer than one year in ten; their bad
year is in the last column, at R$ 790,053 and R$ 411,848 one year in a hundred. The column the
average hid is the one this table adds.

**The last line is all nine together**, and it is the one daniel cares about: in a year one in
ten, Vereda loses R$ 645,467 or more to these nine risks.

### What the simulation assumes

Three things, each worth knowing because each can be wrong:

- **Lognormal shapes.** Each range is turned into a lognormal distribution whose 5th and 95th
  percentiles are the range's ends. It suits quantities that cannot be negative and have long right
  tails, which describes most losses. It is a modelling choice, not a fact.
- **Independence.** The risks are drawn separately each year. In reality some move together: a
  phished staff account (T03) and a crafted PDF (T14) both arrive through the clinics' e-mail, and a
  bad year for one is more likely a bad year for the other. Ignoring that makes the tail of the
  total thinner than it should be.
- **The ranges are right.** The simulation is exactly as good as the 90% intervals it starts from.
  It does not create knowledge; it shows what the estimates imply when taken together.
