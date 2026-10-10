---
title: The law, measured
version: 1
---

Little's law is easy to believe on a whiteboard. This section checks it against four months of a real-looking board, and the interesting part is where it fails. **Save the program below as `littles.py`** beside `billing.py`; it reads `items.csv`, so run `billing.py` first if you have not.

```schooling-example
{
  "language": "python",
  "file": "littles.py",
  "parts": [
    {
      "code": "\"\"\"littles.py: Little's law, checked against the Billing team's board.\"\"\"\nimport csv\nimport sys\nfrom datetime import date, timedelta\n\nfirst = date.fromisoformat(sys.argv[1])\nlast = date.fromisoformat(sys.argv[2])\nitems = list(csv.DictReader(open(\"items.csv\")))\n",
      "note": "**The period comes from the command line**, as two dates: `python3 littles.py 2026-09-01 2026-09-30`. `csv.DictReader` turns each row of `items.csv` into a dictionary keyed by the column names."
    },
    {
      "code": "\n\ndef when(text):\n    return date.fromisoformat(text[:10]) if text else None\n",
      "note": "**A date, or nothing.** `merged` carries a time as well, and the first ten characters are the date; an empty column, an item not started or not merged, comes back as `None`."
    },
    {
      "code": "\n\ndays = [first + timedelta(n) for n in range((last - first).days + 1)]\nopen_at = [sum(1 for i in items\n               if i[\"started\"] and when(i[\"started\"]) <= d\n               and (not i[\"merged\"] or when(i[\"merged\"]) > d)) for d in days]\nwip = sum(open_at) / len(days)\n",
      "note": "**Work in progress, counted at the end of every calendar day**, weekends included: an item is open on a day if it started on or before it and had not merged by then. The average of those daily counts is **L**."
    },
    {
      "code": "\ndone = [i for i in items if i[\"merged\"] and first <= when(i[\"merged\"]) <= last]\nthroughput = len(done) / len(days)\ncycle = sum((when(i[\"merged\"]) - when(i[\"started\"])).days for i in done) / len(done)\n",
      "note": "**Throughput is what finished in the period, per day**, and the average cycle time is taken over those same items, in calendar days from start to merge. Those are **λ** and **W**, in the same units as **L**."
    },
    {
      "code": "\nprint(f\"{len(days)} days, {len(done)} items finished\")\nprint(f\"average work in progress   {wip:5.1f} items\")\nprint(f\"throughput                 {throughput:5.2f} items a day\")\nprint(f\"average cycle time         {cycle:5.1f} days\")\nprint(f\"WIP / throughput           {wip / throughput:5.1f} days\")\n",
      "note": "**The last line is the law's prediction**: the cycle time that work in progress and throughput imply. When the system was stable, it lands close to the line above it."
    }
  ]
}
```

## September: a stable month

```
ana@laptop:~/delivery$ python3 littles.py 2026-09-01 2026-09-30
30 days, 31 items finished
average work in progress     6.8 items
throughput                  1.03 items a day
average cycle time           5.6 days
WIP / throughput             6.6 days
```

The law predicts **6.6 days** and the items that finished in September took **5.6** on average. A day apart, out of six: close, and not equal. The gap has a name, and finding it is the first piece of real analysis in this course.

The law counts everything that is open, and the average cycle time counts only what finished. **One item was open on every day of September and finished on none of them**: `BIL-177`, a one-point bug started on 14 August and blocked ever since. It adds one to work in progress on all thirty days and nothing to any cycle time. Take it out and work in progress averages 5.8, and 5.8 ÷ 1.03 is 5.6, exactly the measured figure. The law was right; the board was carrying an item nobody was finishing. Lesson 3 is about how to see that item without doing arithmetic.

## August: the month the rules changed

```
ana@laptop:~/delivery$ python3 littles.py 2026-08-01 2026-08-31
31 days, 36 items finished
average work in progress     7.8 items
throughput                  1.16 items a day
average cycle time          12.6 days
WIP / throughput             6.7 days
```

Now the two numbers are nearly a factor of two apart: the law says **6.7 days** and the finished items took **12.6**. Nothing is wrong with the arithmetic. **August broke the law's conditions.** It began with 16 items open and ended with 7, so work in progress was not the same at both ends; and many of the items that finished in August had been started in June and July, under the old rules, so their long cycle times describe a team that no longer existed by the time they were counted. One of them had been open since 1 June, 74 days.

That is how to read a disagreement: **when the law and the measurement disagree, the system changed during the period**. Here you already knew it had, because the team announced the change. On a real team the disagreement is often how you find out.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 280\" role=\"img\" data-fig=\"l01-wip-days\" aria-label=\"A line chart of the Billing team's work in progress at the end of each day, from 1 June to 30 September 2026. It sits between 15 and 20 items through June and July, falls through August after the rules change on 3 August, and stays between 6 and 7 in September.\"><path d=\"M60.0 40.0 L60.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"54.0\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><path d=\"M60.0 182.5 L650.0 182.5\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"54.0\" y=\"182.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><path d=\"M60.0 135.0 L650.0 135.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"54.0\" y=\"135.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><path d=\"M60.0 87.5 L650.0 87.5\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"54.0\" y=\"87.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">15</text><path d=\"M60.0 40.0 L650.0 40.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"54.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">20</text><path d=\"M60.0 230.0 L650.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"60.0\" y=\"246.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 Jun</text><text x=\"206.3\" y=\"246.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 Jul</text><text x=\"357.4\" y=\"246.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 Aug</text><text x=\"508.6\" y=\"246.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 Sep</text><path d=\"M367.2 40.0 L367.2 230.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"373.2\" y=\"34.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">3 Aug: one item each, review first</text><path d=\"M60.0 87.5 L64.9 78.0 L69.8 87.5 L74.6 87.5 L79.5 87.5 L84.4 87.5 L89.3 87.5 L94.1 87.5 L99.0 87.5 L103.9 78.0 L108.8 78.0 L113.6 78.0 L118.5 78.0 L123.4 78.0 L128.3 78.0 L133.1 78.0 L138.0 78.0 L142.9 78.0 L147.8 78.0 L152.6 78.0 L157.5 78.0 L162.4 68.5 L167.3 68.5 L172.1 78.0 L177.0 49.5 L181.9 68.5 L186.8 68.5 L191.7 68.5 L196.5 68.5 L201.4 68.5 L206.3 78.0 L211.2 78.0 L216.0 78.0 L220.9 78.0 L225.8 78.0 L230.7 78.0 L235.5 78.0 L240.4 78.0 L245.3 40.0 L250.2 59.0 L255.0 59.0 L259.9 59.0 L264.8 68.5 L269.7 78.0 L274.5 68.5 L279.4 78.0 L284.3 78.0 L289.2 78.0 L294.0 78.0 L298.9 78.0 L303.8 68.5 L308.7 68.5 L313.6 68.5 L318.4 68.5 L323.3 68.5 L328.2 68.5 L333.1 68.5 L337.9 59.0 L342.8 49.5 L347.7 68.5 L352.6 78.0 L357.4 78.0 L362.3 78.0 L367.2 97.0 L372.1 125.5 L376.9 144.5 L381.8 154.0 L386.7 173.0 L391.6 173.0 L396.4 173.0 L401.3 173.0 L406.2 173.0 L411.1 173.0 L416.0 163.5 L420.8 163.5 L425.7 163.5 L430.6 163.5 L435.5 154.0 L440.3 163.5 L445.2 163.5 L450.1 163.5 L455.0 163.5 L459.8 163.5 L464.7 163.5 L469.6 163.5 L474.5 173.0 L479.3 173.0 L484.2 163.5 L489.1 163.5 L494.0 163.5 L498.8 163.5 L503.7 163.5 L508.6 163.5 L513.5 163.5 L518.3 163.5 L523.2 163.5 L528.1 163.5 L533.0 163.5 L537.9 163.5 L542.7 163.5 L547.6 163.5 L552.5 163.5 L557.4 173.0 L562.2 173.0 L567.1 173.0 L572.0 173.0 L576.9 173.0 L581.7 163.5 L586.6 163.5 L591.5 163.5 L596.4 163.5 L601.2 163.5 L606.1 163.5 L611.0 163.5 L615.9 163.5 L620.7 163.5 L625.6 163.5 L630.5 163.5 L635.4 163.5 L640.2 163.5 L645.1 163.5 L650.0 163.5\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" fill=\"none\"></path><text x=\"60.0\" y=\"16.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">items open at the end of each day</text></svg>", "caption": "Two policies and the transition between them. Little's law holds in September and fails across August, where the board was emptying."}
```

## The whole four months

```
ana@laptop:~/delivery$ python3 littles.py 2026-06-01 2026-09-30
122 days, 118 items finished
average work in progress    11.9 items
throughput                  0.97 items a day
average cycle time          11.6 days
WIP / throughput            12.3 days
```

Over the long period the two sides agree again, within a day, because the ramp at the start and the items still open at the end are small against 122 days. It is also a period that **describes no team that ever existed**: an average of 11.9 items in progress, when the team carried 16 for two months and 7 for two. A long window makes the law hold and makes the numbers meaningless at the same time. The rest of the course measures a period of one policy at a time, and says which.

## Using it the other way round

The point of the law is not to verify a number you already have. It is to get the one you do not. A team that knows its throughput, from the done column, and its work in progress, by counting the board today, knows roughly how long a new item will take before anybody has timed one. And a team that wants shorter cycle times knows the lever: **throughput is hard to change, and work in progress is a decision made every morning**.
