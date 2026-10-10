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
30 days, 30 items finished
average work in progress     6.0 items
throughput                  1.00 items a day
average cycle time           5.0 days
WIP / throughput             6.0 days
```

The law predicts **6.0 days** and the items that finished in September took **5.0** on average. A day apart, out of six: close, and not equal. The gap has a name, and finding it is the first piece of real analysis in this course.

The law counts everything that is open, and the average cycle time counts only what finished. **One item was open on every day of September and finished on none of them**: `BIL-189`, a one-point bug started on 21 August and blocked ever since. It adds one to work in progress on all thirty days and nothing to any cycle time. Take it out and work in progress averages 5.0, and 5.0 ÷ 1.00 is 5.0, exactly the measured figure. The law was right; the board was carrying an item nobody was finishing. Lesson 3 is about how to see that item without doing arithmetic.

## August: the month the rules changed

```
ana@laptop:~/delivery$ python3 littles.py 2026-08-01 2026-08-31
31 days, 41 items finished
average work in progress    10.5 items
throughput                  1.32 items a day
average cycle time          15.4 days
WIP / throughput             8.0 days
```

Now the two numbers are nearly a factor of two apart: the law says **8.0 days** and the finished items took **15.4**. Nothing is wrong with the arithmetic. **August broke the law's conditions.** It began with 26 items open and ended with 6, so work in progress was not the same at both ends; and many of the items that finished in August had been started in June and July, under the old rules, so their long cycle times describe a team that no longer existed by the time they were counted. The oldest had been open since 7 July, 55 days.

That is how to read a disagreement: **when the law and the measurement disagree, the system changed during the period**. Here you already knew it had, because the team announced the change. On a real team the disagreement is often how you find out.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 280\" role=\"img\" data-fig=\"l01-wip-days\" aria-label=\"A line chart of the Billing team's work in progress at the end of each day, from 1 June to 30 September 2026. It sits between 15 and 30 items through June and July, falls through August after the rules change on 3 August, and stays at 6 or fewer in September.\"><path d=\"M60.0 40.0 L60.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"54.0\" y=\"230.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><path d=\"M60.0 166.7 L650.0 166.7\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"54.0\" y=\"166.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><path d=\"M60.0 103.3 L650.0 103.3\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"54.0\" y=\"103.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">20</text><path d=\"M60.0 40.0 L650.0 40.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"54.0\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">30</text><path d=\"M60.0 230.0 L650.0 230.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"60.0\" y=\"246.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 Jun</text><text x=\"206.3\" y=\"246.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 Jul</text><text x=\"357.4\" y=\"246.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 Aug</text><text x=\"508.6\" y=\"246.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1 Sep</text><path d=\"M367.2 40.0 L367.2 230.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"373.2\" y=\"34.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">3 Aug: one item each, review first</text><path d=\"M60.0 135.0 L64.9 135.0 L69.8 135.0 L74.6 128.7 L79.5 128.7 L84.4 128.7 L89.3 128.7 L94.1 122.3 L99.0 122.3 L103.9 122.3 L108.8 116.0 L113.6 122.3 L118.5 122.3 L123.4 122.3 L128.3 122.3 L133.1 103.3 L138.0 103.3 L142.9 116.0 L147.8 122.3 L152.6 122.3 L157.5 122.3 L162.4 122.3 L167.3 128.7 L172.1 128.7 L177.0 122.3 L181.9 116.0 L186.8 116.0 L191.7 116.0 L196.5 103.3 L201.4 97.0 L206.3 90.7 L211.2 90.7 L216.0 84.3 L220.9 84.3 L225.8 84.3 L230.7 84.3 L235.5 71.7 L240.4 71.7 L245.3 71.7 L250.2 78.0 L255.0 78.0 L259.9 78.0 L264.8 84.3 L269.7 78.0 L274.5 71.7 L279.4 65.3 L284.3 52.7 L289.2 52.7 L294.0 52.7 L298.9 46.3 L303.8 40.0 L308.7 40.0 L313.6 52.7 L318.4 52.7 L323.3 52.7 L328.2 52.7 L333.1 46.3 L337.9 59.0 L342.8 65.3 L347.7 65.3 L352.6 65.3 L357.4 65.3 L362.3 65.3 L367.2 97.0 L372.1 128.7 L376.9 141.3 L381.8 147.7 L386.7 147.7 L391.6 147.7 L396.4 147.7 L401.3 147.7 L406.2 160.3 L411.1 160.3 L416.0 160.3 L420.8 173.0 L425.7 173.0 L430.6 173.0 L435.5 185.7 L440.3 185.7 L445.2 185.7 L450.1 185.7 L455.0 185.7 L459.8 185.7 L464.7 185.7 L469.6 185.7 L474.5 192.0 L479.3 185.7 L484.2 192.0 L489.1 192.0 L494.0 192.0 L498.8 192.0 L503.7 192.0 L508.6 192.0 L513.5 192.0 L518.3 192.0 L523.2 192.0 L528.1 192.0 L533.0 192.0 L537.9 192.0 L542.7 192.0 L547.6 192.0 L552.5 192.0 L557.4 192.0 L562.2 192.0 L567.1 192.0 L572.0 192.0 L576.9 192.0 L581.7 192.0 L586.6 192.0 L591.5 192.0 L596.4 192.0 L601.2 192.0 L606.1 192.0 L611.0 192.0 L615.9 192.0 L620.7 192.0 L625.6 192.0 L630.5 192.0 L635.4 192.0 L640.2 192.0 L645.1 192.0 L650.0 192.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.8\" fill=\"none\"></path><text x=\"60.0\" y=\"16.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">items open at the end of each day</text></svg>", "caption": "Two policies and the transition between them. Little's law holds in September and fails across August, where the board was emptying."}
```

## The whole four months

```
ana@laptop:~/delivery$ python3 littles.py 2026-06-01 2026-09-30
122 days, 123 items finished
average work in progress    14.9 items
throughput                  1.01 items a day
average cycle time          14.4 days
WIP / throughput            14.8 days
```

Over the long period the two sides agree again, within a day, because the ramp at the start and the items still open at the end are small against 122 days. It is also a period that **describes no team that ever existed**: an average of 14.9 items in progress, when the team carried about 22 through June and July and 6 in September. A long window makes the law hold and makes the numbers meaningless at the same time. The rest of the course measures a period of one policy at a time, and says which.

## Using it the other way round

The point of the law is not to verify a number you already have. It is to get the one you do not. A team that knows its throughput, from the done column, and its work in progress, by counting the board today, knows roughly how long a new item will take before anybody has timed one. And a team that wants shorter cycle times knows the lever: **throughput is hard to change, and work in progress is a decision made every morning**.
