---
title: The budget, and the argument it replaces
version: 1
---

Every team that runs software it also changes has the same argument, usually without naming it. The people who want new features want to release more often. The people who answer the pager want to release less often, because every release is a chance to break something. Both are right, and without a number between them the argument is settled by whoever is louder that week, or by whoever was paged last.

**An error budget is that number.** If the objective is 99.9%, the other 0.1% is not a failure to be ashamed of; it is an allowance, agreed in advance, for the things that will go wrong. The team may spend it on anything: risky releases, experiments, a migration, a provider's bad hour. While there is budget left, the team releases as fast as it likes. When the budget is gone, reliability comes first until it returns.

```localised
error budget = (1 − objective) × valid events in the window
```

The argument does not disappear, but it changes subject. Nobody has to decide, release by release, whether this one is too risky. The question becomes the one the budget answers: **how much unreliability have we got left this month, and what do we want to spend it on?**

## September's budget

**Save the program below as `budget.py`.** It writes the Billing team's card charges for September, one day at a time, and spends the budget day by day.

```schooling-example
{
  "language": "python",
  "file": "budget.py",
  "parts": [
    {
      "code": "\"\"\"budget.py: September's error budget for card charges, day by day.\"\"\"\nimport random\nfrom datetime import date, timedelta\n\nSLO = 0.999                                            # 99.9% of charge attempts are good\nrng = random.Random(16)\n\n# The charge attempts of each day: fewer at weekends, many more on the last day of the\n# month, and a small background of bad answers. Two days had trouble, written in by hand.\ndays = []\nfor n in range(30):\n    day = date(2026, 9, 1) + timedelta(days=n)\n    attempts = 140000 if day.day == 30 else 15000 if day.weekday() >= 5 else 40000\n    attempts = round(attempts * rng.uniform(0.9, 1.1))\n    bad = sum(1 for _ in range(attempts) if rng.random() < 0.0002)\n    if day == date(2026, 9, 16):\n        bad += 410                                     # the card provider slow for an hour\n    if day == date(2026, 9, 30):\n        bad += 1601                                    # 30 September, section 05\n    days.append((day, attempts, bad))\n\n",
      "note": "**A month of charges, written by the program.** Every attempt is good or bad by the definition in section 02. Weekdays carry about 40,000 attempts, weekends 15,000 and the last day of the month 140,000; a bad answer comes up about twice in 10,000 on an ordinary day. Two days had trouble, and the program adds their bad charges by hand: the hour on 16 September when the card provider was slow, and the afternoon of the incident, which section 05 takes apart."
    },
    {
      "code": "total = sum(a for _, a, _ in days)\nbudget = total * (1 - SLO)\nprint(f\"{total} attempts in September; a {SLO:.1%} objective allows {budget:.0f} to be bad\")\nspent = 0\nfor day, attempts, bad in days:\n    spent += bad\n    if bad > 2 * attempts * 0.0002 or day.day in (7, 14, 21, 28):\n        print(f\"  {day}  {bad:5} bad  budget left {1 - spent / budget:5.0%}\")\ngood = total - spent\nprint(f\"SLI for the month: {good / total:.3%}, budget spent {spent / budget:.0%}\")\n",
      "note": "**The budget, and what was left of it.** The budget is the objective's complement, one bad charge in a thousand, multiplied by the month's attempts. The loop spends it day by day and prints every Monday and every day with more than twice the usual bad charges; the last line is the month's SLI and the share of the budget it used."
    }
  ]
}
```

```
ana@laptop:~/delivery$ python3 budget.py
1102977 attempts in September; a 99.9% objective allows 1103 to be bad
  2026-09-07     10 bad  budget left   95%
  2026-09-14      1 bad  budget left   91%
  2026-09-16    415 bad  budget left   53%
  2026-09-21      8 bad  budget left   51%
  2026-09-28      6 bad  budget left   47%
  2026-09-30   1624 bad  budget left -101%
SLI for the month: 99.799%, budget spent 201%
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 290\" role=\"img\" data-fig=\"l16-burndown\" aria-label=\"A line showing how much of September's error budget was left at the end of each day. It falls slowly from 100% to about 90% in the first two weeks, drops to 53% on 16 September, when the card provider was slow for an hour, drifts down to 47% by the 29th, and falls through zero to minus 101% on 30 September, the day of the incident.\"><path d=\"M70.0 40.0 L70.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M70.0 230.9 L640.0 230.9\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"64.0\" y=\"230.9\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">-100%</text><path d=\"M70.0 183.2 L640.0 183.2\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"64.0\" y=\"183.2\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">-50%</text><path d=\"M70.0 135.5 L640.0 135.5\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"64.0\" y=\"135.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">0%</text><path d=\"M70.0 87.7 L640.0 87.7\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"64.0\" y=\"87.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">50%</text><path d=\"M70.0 40.0 L640.0 40.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"64.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">100%</text><path d=\"M70.0 250.0 L640.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M70.0 135.5 L640.0 135.5\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 3\"></path><path d=\"M70.0 40.0 L89.0 40.7 L108.0 41.6 L127.0 42.7 L146.0 43.5 L165.0 43.8 L184.0 44.0 L203.0 44.8 L222.0 45.5 L241.0 46.1 L260.0 47.0 L279.0 47.8 L298.0 48.0 L317.0 48.1 L336.0 48.2 L355.0 48.9 L374.0 84.8 L393.0 85.5 L412.0 86.0 L431.0 86.1 L450.0 86.4 L469.0 87.1 L488.0 87.8 L507.0 88.3 L526.0 89.1 L545.0 89.3 L564.0 89.4 L583.0 89.8 L602.0 90.3 L621.0 91.1 L640.0 231.6\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"79.5\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 Sep</text><text x=\"212.5\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8 Sep</text><text x=\"345.5\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">15 Sep</text><text x=\"478.5\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">22 Sep</text><text x=\"611.5\" y=\"266.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">29 Sep</text><text x=\"564.0\" y=\"125.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">budget spent</text><text x=\"380.0\" y=\"102.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">16 Sep: the provider slow for an hour</text><text x=\"632.0\" y=\"231.6\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">30 Sep: the incident</text><text x=\"70.0\" y=\"18.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">error budget left at the end of each day, card charges, September</text></svg>", "caption": "Two weeks of ordinary days spent less than a tenth of the budget. One slow hour spent more than a third, and one afternoon spent more than the whole month."}
```

Read the month in three parts.

- **The first fortnight spent almost nothing.** About 10 bad charges a weekday, the ordinary background, used 9% of the month's budget in two weeks. At that pace the month would have ended with four fifths of it unused.
- **One hour on 16 September spent 38%.** The card provider was slow, and 415 charges took longer than ten seconds. Nothing the team released caused it; the budget does not care, because the shops waited either way.
- **One day, 30 September, spent half as much again as the whole month's budget.** Its 1,624 bad charges are 147% of the 1,103 the month allowed, and nearly all of them came in the afternoon of the incident. The SLI for the month was 99.799%, below the objective, and the budget ended at 201% spent.

## What the budget says that the SLI does not

The SLI says **99.799%**, which sounds excellent to anybody who has not done this arithmetic. The budget says **201% spent**, which nobody misreads. The two are the same fact, and the second is the one to put in front of people who decide what the team works on next, because it is already in the unit of the decision.

It also says something about the good months. A team that ends month after month with most of its budget unused is being **too careful**: the shops would not notice a few more bad charges, and the team could have released faster, tried the risky migration, or moved people from firefighting to features. An error budget is meant to be spent, and lesson 12's argument about slack applies here as well: a budget that is never touched is a measure of value that was never delivered.
