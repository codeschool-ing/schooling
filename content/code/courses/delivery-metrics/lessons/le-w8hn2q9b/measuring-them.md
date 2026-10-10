---
title: The Billing team's four numbers
version: 1
---

The pipeline's record, `deploys.csv`, holds three of the four metrics directly, and with the merge times from `items.csv` it holds the fourth. **Save the program below as `dora.py`.**

```schooling-example
{
  "language": "python",
  "file": "dora.py",
  "parts": [
    {
      "code": "\"\"\"dora.py: the four DORA metrics, month by month, from the pipeline's record.\"\"\"\nimport calendar\nimport csv\nimport statistics\nfrom datetime import datetime\n\nmerged = {i[\"id\"]: datetime.fromisoformat(i[\"merged\"])\n          for i in csv.DictReader(open(\"items.csv\")) if i[\"merged\"]}\n",
      "note": "**When each change merged.** The Billing team's history has no separate commit times, so the merge stands in for the commit; the next section says what that leaves out."
    },
    {
      "code": "months = {}\nfor d in csv.DictReader(open(\"deploys.csv\")):\n    at = datetime.fromisoformat(d[\"at\"])\n    m = months.setdefault(at.strftime(\"%Y-%m\"), {\"deploys\": 0, \"failed\": 0, \"lead\": [], \"restore\": []})\n    m[\"deploys\"] += 1\n",
      "note": "**One pass over the deployments**, filed by month. Counting them is the first metric."
    },
    {
      "code": "    m[\"lead\"] += [(at - merged[i]).total_seconds() / 3600 for i in d[\"items\"].split()]\n",
      "note": "**Lead time for changes, in hours**: for every change the deployment carried, the time from its merge to this deployment."
    },
    {
      "code": "    if d[\"failed\"] == \"1\":\n        m[\"failed\"] += 1\n        m[\"restore\"].append((datetime.fromisoformat(d[\"restored\"]) - at).total_seconds() / 60)\n",
      "note": "**A failed deployment counts towards the failure rate**, and the minutes until service was restored are its time to restore."
    },
    {
      "code": "\nprint(\"month    deploys  per week  lead time (h)  failure rate  time to restore (min)\")\nfor month, m in sorted(months.items()):\n    weeks = calendar.monthrange(int(month[:4]), int(month[5:]))[1] / 7\n    restore = f\"{statistics.median(m['restore']):.0f}\" if m[\"restore\"] else \"-\"\n    print(f\"{month}  {m['deploys']:7}  {m['deploys'] / weeks:8.1f}  \"\n          f\"{statistics.median(m['lead']):13.1f}  {m['failed'] / m['deploys']:12.0%}  {restore:>21}\")\n",
      "note": "**One row per month.** Lead time and time to restore are medians, because both have long tails; the failure rate is failed deployments over all deployments."
    }
  ]
}
```

```
ana@laptop:~/delivery$ python3 dora.py
month    deploys  per week  lead time (h)  failure rate  time to restore (min)
2026-06        4       0.9           52.8           25%                    136
2026-07        5       1.1           48.8           20%                    195
2026-08       18       4.1            4.1            6%                     48
2026-09       20       4.7            6.1            5%                     55
```

## Before 3 August

**About one deployment a week**: the Thursday train. A change that merged on a Friday waited six days for it, and the median change waited a little over two days, **52.8 hours** in June. One deployment in four or five failed: one of the four in June and one of the five in July. Each failure took more than two hours to undo, 136 minutes and then 195, because each carried six to eight changes and somebody had to work out which of them was wrong before rolling anything back.

## After it

**Between four and five deployments a week**, one on most working days. The median change reached production within **four to six hours** of merging. One deployment in twenty failed, and service came back in **under an hour**: the failed deployments carried three or four changes rather than eight.

## The research's claim, in miniature

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 250\" role=\"img\" data-fig=\"l05-four\" aria-label=\"Four small bar charts, each comparing June and July with August and September. Deployments per week: 1.0 then 4.4. Median lead time for changes in hours: 50.8 then 4.5. Change failure rate: 22% then 5%. Median time to restore in minutes: 166 then 52.\"><text x=\"90.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">deploys per week</text><text x=\"90.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">higher is better</text><path d=\"M42.0 166.8 L86.0 166.8 L86.0 200.0 L42.0 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"var(--scan)\"></path><text x=\"64.0\" y=\"158.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">1.0</text><text x=\"64.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Jun–Jul</text><path d=\"M106.0 60.0 L150.0 60.0 L150.0 200.0 L106.0 200.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"var(--scan)\"></path><text x=\"128.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">4.4</text><text x=\"128.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Aug–Sep</text><path d=\"M30.0 200.0 L160.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"256.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">lead time (hours)</text><text x=\"256.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">lower is better</text><path d=\"M208.0 60.0 L252.0 60.0 L252.0 200.0 L208.0 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"var(--scan)\"></path><text x=\"230.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">50.8</text><text x=\"230.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Jun–Jul</text><path d=\"M272.0 187.6 L316.0 187.6 L316.0 200.0 L272.0 200.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"var(--scan)\"></path><text x=\"294.0\" y=\"179.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">4.5</text><text x=\"294.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Aug–Sep</text><path d=\"M196.0 200.0 L326.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"422.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">change failure rate</text><text x=\"422.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">lower is better</text><path d=\"M374.0 60.0 L418.0 60.0 L418.0 200.0 L374.0 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"var(--scan)\"></path><text x=\"396.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">22%</text><text x=\"396.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Jun–Jul</text><path d=\"M438.0 166.8 L482.0 166.8 L482.0 200.0 L438.0 200.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"var(--scan)\"></path><text x=\"460.0\" y=\"158.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">5%</text><text x=\"460.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Aug–Sep</text><path d=\"M362.0 200.0 L492.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"588.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">time to restore (min)</text><text x=\"588.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">lower is better</text><path d=\"M540.0 60.0 L584.0 60.0 L584.0 200.0 L540.0 200.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"var(--scan)\"></path><text x=\"562.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">166</text><text x=\"562.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Jun–Jul</text><path d=\"M604.0 156.4 L648.0 156.4 L648.0 200.0 L604.0 200.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"var(--scan)\"></path><text x=\"626.0\" y=\"148.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">52</text><text x=\"626.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Aug–Sep</text><path d=\"M528.0 200.0 L658.0 200.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"340.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">9 deployments (2 failed) before, 38 (2 failed) after</text></svg>", "caption": "All four moved the right way at once: more deployments, faster, failing less and recovering sooner."}
```

Every one of the four improved at once. The team deployed four times as often **and** failed a quarter as often **and** recovered in a third of the time. That is the finding of the State of DevOps reports, reproduced on one small invented team: **speed and stability moved together, because both depend on the size of the batch**. Nobody on the Billing team set out to improve the change failure rate. They changed how much work was open, the batches got smaller as a side effect, and smaller batches are easier to get right and quicker to undo.

The simulation builds that relationship in, which is worth saying plainly: `billing.py` makes a deployment's chance of failing and its time to undo grow with the number of changes in it. The research's claim is that real systems behave the same way, and its evidence is the survey, not this program.

## How much to trust nine deployments

June and July hold nine deployments between them, and two failed. A rate computed from nine events is fragile: one more failure would have made July 40%, one fewer would have made it zero. **Below twenty or thirty deployments, quote the count rather than the rate**: "two of nine failed" says honestly what "22%" says with false precision. The same goes for time to restore, where June and July each have a single failure and the "median" is one number.

From August the counts are large enough for rates to mean something, and they are the numbers the team should track. A practical rule: **pick a window long enough to hold at least twenty deployments**, and keep the same window from report to report.
