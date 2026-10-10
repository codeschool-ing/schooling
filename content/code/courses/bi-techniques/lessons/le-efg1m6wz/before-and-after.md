---
title: Why before and after cannot answer it
version: 1
---

The most natural way to judge a change is to compare the weeks after it with the weeks before.
**It is also the least reliable**, and the first six lessons of this course are the reason: a
series moves with its trend, its seasons and its holidays whether or not anybody changed anything.

```schooling-example
{"language": "python", "file": "before_after.py", "parts": [{"code": "import pandas as pd\n\norders = pd.read_csv(\"daily_orders.csv\", parse_dates=[\"date\"], index_col=\"date\")[\"orders\"]\nlaunch = pd.Timestamp(\"2024-02-26\")", "note": "Suppose a new checkout page went live on Monday 26 February 2024. Nothing in Panela's data changed that day; that is the point."}, {"code": "before = orders[launch - pd.Timedelta(days=28):launch - pd.Timedelta(days=1)]\nafter = orders[launch:launch + pd.Timedelta(days=27)]\nprint(f\"28 days before {launch.date()}: {before.mean():7.1f} orders a day\")\nprint(f\"28 days from   {launch.date()}: {after.mean():7.1f} orders a day\")\nprint(f\"change: {after.mean() / before.mean() - 1:+.1%}\")", "note": "Four weeks before and four weeks from the launch: the comparison a launch report makes."}, {"code": "before_2023 = orders[launch - pd.Timedelta(days=392):launch - pd.Timedelta(days=365)]\nafter_2023 = orders[launch - pd.Timedelta(days=364):launch - pd.Timedelta(days=337)]\nprint(f\"\\nthe same two stretches of 2023, with no new page: {after_2023.mean() / before_2023.mean() - 1:+.1%}\")", "note": "The same 56 days one year earlier, 364 days back so the weekdays line up. No page was launched in 2023."}], "output": "28 days before 2024-02-26:   957.0 orders a day\n28 days from   2024-02-26:  1063.0 orders a day\nchange: +11.1%\n\nthe same two stretches of 2023, with no new page: +10.2%"}
```

The launch "raised orders by 11.1%". The same two stretches of the year before, with nothing
launched, rose by 10.2%. Almost all of the apparent effect is the calendar: the weeks before the
launch held Carnival in both years, the weeks after it were the start of the busier season, and the
business was growing throughout. Whatever the page did is somewhere in the gap between the two
numbers, and two numbers from two different years cannot say where.

**Before-and-after compares two different times, so everything else that differs between those
times is mixed into the answer.** Statistics calls those other things **confounders**, and
`statistics` lesson 18 is about them. Some can be adjusted for, as lesson 6 adjusted for Carnival,
but only the ones somebody thought of.

## What an experiment does instead

An **A/B test** shows two versions at the same time, and decides at random which visitor sees
which. Version A is the **control**, usually what exists now; version B is the **treatment**, the
change. Because the split is random and simultaneous:

- the season, the trend and the holidays fall on both groups alike, so they cancel in the
  comparison;
- the kinds of visitor, keen or idle, on a phone or a laptop, are spread evenly between the groups,
  on average, without anybody having to list them;
- what remains as a difference is the change itself, plus chance, and chance is exactly what the
  tests of `statistics` lessons 13 to 15 measure.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 250\" role=\"img\" data-fig=\"l07-split\" aria-label=\"A diagram of an A/B test. Visitors arrive on the left and a coin decides, for each one, whether they see the old checkout, A, or the new one, B. Both groups sit inside one band labelled the same weeks, holidays and trend. On the right, the difference between the two groups is the change plus chance.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"170.0\" y=\"30.0\" width=\"280.0\" height=\"180.0\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"310.0\" y=\"196.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the same weeks, the same holidays, the same trend</text><rect x=\"20.0\" y=\"95.0\" width=\"100.0\" height=\"40.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"70.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">visitors</text><text x=\"70.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a random split</text><path d=\"M120 108 C150 108 160 70 196 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M120 122 C150 122 160 150 196 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"200.0\" y=\"50.0\" width=\"220.0\" height=\"40.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"310.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">A: the old checkout</text><rect x=\"200.0\" y=\"130.0\" width=\"220.0\" height=\"40.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"310.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">B: the new checkout</text><path d=\"M420 70 C450 70 460 108 486 108\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M420 150 C450 150 460 122 486 122\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"490.0\" y=\"92.0\" width=\"136.0\" height=\"46.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"558.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the difference</text><text x=\"558.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">= the change + chance</text></svg>", "caption": "Before-and-after compares two times. An experiment compares two groups at one time, so everything the time carries falls on both and cancels."}
```

That is why randomised experiments are the standard of evidence for a decision like this one, and
why the next five lessons are worth their length. They are also not free: an experiment needs
traffic, time and the discipline to decide before looking, which is what the rest of this lesson
writes down.
