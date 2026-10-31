---
title: The error budget, and how fast it burns
version: 1
---

**An SLO is a target for the SLI over a window: 99.5% of requests good, over 28 days.** The remainder,
0.5%, is the **error budget**: the failures the service is allowed before it has missed its objective. It is
a number of requests, and it can be spent. A release that breaks checkout for an hour spends some of it; a
quiet week spends almost none. Thinking of failures as a budget is what lets a team decide, with a number,
whether to ship the next feature or spend the week on reliability. **This section runs on your computer**:
the arithmetic is the SLO's, on counts a program generates. Cloud Monitoring does the same arithmetic on the
real metrics, and the next section declares it there.

Write the program into `~/gcp/slo.py`:

```schooling-example
{"language": "python", "file": "slo.py", "parts": [{"code": "\"\"\"slo.py: an SLO's arithmetic over 28 days of the shop's requests.\n\nThe counts are generated, seeded: about 400,000 requests a day, a normal\nbackground of failures, and one bad afternoon on day 19.\n\"\"\"\n", "note": "The docstring says where the numbers come from: generated, with a fixed seed, so every run prints the same ones."}, {"code": "import random\n\n", "note": "Two numbers decide the SLO: the target, 99.5% of requests good, and the window it is measured over, 28 days."}, {"code": "rng = random.Random(3)\nTARGET = 0.995          # 99.5% of requests good\nWINDOW_DAYS = 28\n\ndays = []\nfor day in range(1, WINDOW_DAYS + 1):\n    total = 400_000 + rng.randint(-20_000, 20_000)\n    bad = int(total * rng.uniform(0.001, 0.003))\n    if day == 19:\n        bad += 9_000            # the bad afternoon\n    days.append((day, total, bad))\n\n", "note": "Twenty-eight days of counts. Each day has its total and its failures, between 0.1% and 0.3% of the traffic; day 19 adds 9,000 failures on top."}, {"code": "total = sum(t for _, t, _ in days)\nbad = sum(b for _, _, b in days)\nbudget = total * (1 - TARGET)   # requests allowed to fail in the window\n\n", "note": "The window's totals, and the **error budget**: the number of requests allowed to fail in 28 days, which is 0.5% of all of them."}, {"code": "print(f'requests       {total:>12,}')\nprint(f'failed         {bad:>12,}')\nprint(f'SLI            {1 - bad / total:>12.4%}')\nprint(f'error budget   {budget:>12,.0f}  ({1 - TARGET:.1%} of requests)')\nprint(f'budget left    {budget - bad:>12,.0f}  ({1 - bad / budget:.1%})')\n", "note": "The SLI, which is the share of good requests; the budget; and how much of the budget is left after the failures."}, {"code": "print()\nprint('day   failed  burn rate')\nfor day, t, b in days[14:22]:\n    print(f'{day:>3}  {b:>7,}  {(b / t) / (1 - TARGET):>9.2f}')\n", "note": "The **burn rate** of each day from 15 to 22: the day's failure rate divided by the failure rate the target allows. 1 means the budget would last exactly the window."}]}
```

```
ana@laptop:~/gcp$ python3 slo.py
requests         11,258,992
failed               30,490
SLI                99.7292%
error budget         56,295  (0.5% of requests)
budget left          25,805  (45.8%)

day   failed  burn rate
 15      454       0.22
 16    1,011       0.53
 17      773       0.39
 18      984       0.49
 19    9,730       4.77
 20      789       0.38
 21    1,072       0.55
 22      414       0.21
```

Read the first block as a report on the window:

- **11,258,992 requests, 30,490 failed**, so the SLI is 99.7292%, above the 99.5% target.
- **The budget is 56,295 failures**, 0.5% of the requests. The month used 30,490 of them and has 25,805
  left, 45.8% of the budget. The shop is meeting its objective, with room to spare.

Then the second block, the **burn rate**: how fast the budget is being spent compared with the pace that
would spend it exactly over the window. On most days it is between 0.2 and 0.6, which spends less than the
day's share. **Day 19 burned at 4.77**: at that pace the whole 28-day budget would be gone in under six days.
And that is a daily average: the bad afternoon itself burned much faster for a few hours, and a daily number
spreads it over twenty-four.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"A bar chart of the daily burn rate from day 15 to day 22. Every day sits between 0.21 and 0.55, under a dashed line at 1, the pace that spends the budget exactly in the window, except day 19, whose bar reaches 4.77.\"><defs><marker id=\"ah6\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><line x1=\"60\" y1=\"210\" x2=\"700\" y2=\"210\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><rect x=\"80\" y=\"202.08\" width=\"44\" height=\"7.92\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"102\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">15</text><text x=\"102\" y=\"192.08\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.22</text><rect x=\"158\" y=\"190.92\" width=\"44\" height=\"19.080000000000002\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"180\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">16</text><text x=\"180\" y=\"180.92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.53</text><rect x=\"236\" y=\"195.96\" width=\"44\" height=\"14.040000000000001\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"258\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">17</text><text x=\"258\" y=\"185.96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.39</text><rect x=\"314\" y=\"192.36\" width=\"44\" height=\"17.64\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"336\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">18</text><text x=\"336\" y=\"182.36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.49</text><rect x=\"392\" y=\"38.28000000000003\" width=\"44\" height=\"171.71999999999997\" rx=\"3\" fill=\"var(--amber)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"414\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">19</text><text x=\"414\" y=\"28.28000000000003\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4.77</text><rect x=\"470\" y=\"196.32\" width=\"44\" height=\"13.68\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"492\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">20</text><text x=\"492\" y=\"186.32\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.38</text><rect x=\"548\" y=\"190.2\" width=\"44\" height=\"19.8\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"570\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">21</text><text x=\"570\" y=\"180.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.55</text><rect x=\"626\" y=\"202.44\" width=\"44\" height=\"7.56\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"648\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">22</text><text x=\"648\" y=\"192.44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.21</text><line x1=\"60\" y1=\"174.0\" x2=\"700\" y2=\"174.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></line><text x=\"64\" y=\"164.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1: the budget lasts the window</text><text x=\"60\" y=\"242\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">day</text></svg>", "caption": "One afternoon burned almost five days of budget at once."}
```

## What the budget is for

A budget turns arguments into arithmetic. With 45.8% of the budget left, the shop can
release on Friday. With 5% left, it freezes risky releases until the window rolls past the bad days, and spends
the time on what caused them. **Neither decision needs anybody's opinion of how reliable the shop feels**, and
that is the point of writing the objective down before the incident rather than after.

The window is **rolling**: each day, the oldest day drops out and today comes in. Day 19's failures stop
counting against the budget on day 47, not at the end of a calendar month, so there is no first-of-the-month
reset that makes a bad day on the 30th cheap and the same day on the 1st expensive.
