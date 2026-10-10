---
title: The quarter on one screen
version: 1
---

Bia's first draft had fourteen charts because the team had fourteen ways of looking at its work. The review needs a handful of numbers per month, side by side, so that the direction of each one is visible at a glance. **Save the program below as `quarter.py`**, in the folder where `billing.py` wrote `items.csv` and `deploys.csv`.

```schooling-example
{
  "language": "python",
  "file": "quarter.py",
  "parts": [
    {
      "code": "\"\"\"quarter.py: the Billing team's third quarter on one screen, month by month.\"\"\"\nimport csv\nimport math\nfrom datetime import datetime\n\n\ndef percentile(values, p):\n    \"\"\"The smallest value with at least p% of the values at or below it.\"\"\"\n    ordered = sorted(values)\n    return ordered[math.ceil(p / 100 * len(ordered)) - 1]\n\n\n",
      "note": "**The same percentile as lesson 2's `cycle.py`**: the smallest value with at least that share of the items at or below it."
    },
    {
      "code": "months = {m: {\"cycle\": [], \"deploys\": 0, \"failed\": 0, \"restore\": 0} for m in (\"07\", \"08\", \"09\")}\nfor i in csv.DictReader(open(\"items.csv\")):\n    if i[\"merged\"] and i[\"merged\"][5:7] in months:\n        days = (datetime.fromisoformat(i[\"merged\"][:10]) - datetime.fromisoformat(i[\"started\"])).days\n        months[i[\"merged\"][5:7]][\"cycle\"].append(days)\nfor d in csv.DictReader(open(\"deploys.csv\")):\n    m = months.get(d[\"at\"][5:7])\n    if m:\n        m[\"deploys\"] += 1\n        if d[\"failed\"] == \"1\":\n            m[\"failed\"] += 1\n            m[\"restore\"] += (datetime.fromisoformat(d[\"restored\"]) -\n                             datetime.fromisoformat(d[\"at\"])).seconds // 60\n\n",
      "note": "**Three months, gathered in one pass over each file.** An item belongs to the month it was merged in, with its cycle time from start to merge; a deployment belongs to the month it went out, and a failed one adds the minutes until it was restored."
    },
    {
      "code": "print(\"month  finished  cycle median  85th  deploys  failed  minutes broken\")\nfor name, m in zip((\"Jul\", \"Aug\", \"Sep\"), months.values()):\n    c = m[\"cycle\"]\n    print(f\"{name:5}  {len(c):8}  {percentile(c, 50):10} d  {percentile(c, 85):2} d\"\n          f\"  {m['deploys']:7}  {m['failed']:6}  {m['restore']:14}\")\n",
      "note": "**One line a month**: how many items finished, the median and 85th percentile of their cycle times, how many deployments went out, how many failed, and for how many minutes the service was broken."
    }
  ]
}
```

```
ana@laptop:~/delivery$ python3 quarter.py
month  finished  cycle median  85th  deploys  failed  minutes broken
Jul          32          23 d  33 d        5       1             195
Aug          41          13 d  27 d       18       1              48
Sep          30           4 d   8 d       20       1              55
```

Six numbers a month, and each one has to pass the test of the last section before it reaches the page.

## What survives

- **Cycle time fell from a median of 23 days to 4, and the 85th percentile from 33 to 8.** That is what the 3 August rules did. The "so what" is the one the head of product cares about: of the items started now, about six in seven are finished within 8 days, where in July the same share took 33. It answers "can I believe your dates?" better than any promise.
- **Deployments went from 5 a month to 20, and failures stayed at one a month.** The team releases four times as often with the same number of failures, which means the share of releases that fail fell from one in five to one in twenty. The "so what": fixes reach the shops in a day, and releasing often has not made the service less reliable.
- **The September failure is the one that mattered.** Fifty-five minutes broken is close to August's 48, and the column cannot tell them apart; nothing in it says that the September one charged 212 cards twice. A table hides what a number means to a customer, which is why the incident gets its own line on the page, from lesson 14's timeline and lesson 16's budget, rather than a cell in this one.

## What does not survive, and why it still matters

- **Items finished per month did not go up.** 32, 41, 30. August's bump is the board draining after the rules changed, lesson 4's before-and-after; September is back where July was. This number goes on the page anyway, because it is the honest answer to the question somebody will ask: **the team did not finish more. It finished sooner.** Saying that first prevents the most common misreading of a cycle-time chart, which is that the team got faster at typing.
- **Minutes broken, as a total**, does not survive on its own. Three months is three failures, and a total of three numbers mostly says how bad the worst one was. The page quotes each incident's own time to restore instead.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 290\" role=\"img\" data-fig=\"l19-quarter\" aria-label=\"Cycle time of the items merged each month, from July to September, as a filled bar for the median and a taller outlined bar for the 85th percentile: July, median 23 days and 85th percentile 33; August, median 13 days and 85th percentile 27; September, median 4 days and 85th percentile 8. A dashed line between July and August marks 3 August, when the team changed its rules.\"><path d=\"M70.0 50.0 L70.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"64.0\" y=\"240.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">0 d</text><path d=\"M70.0 192.5 L640.0 192.5\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"64.0\" y=\"192.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">10 d</text><path d=\"M70.0 145.0 L640.0 145.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"64.0\" y=\"145.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">20 d</text><path d=\"M70.0 97.5 L640.0 97.5\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"64.0\" y=\"97.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">30 d</text><path d=\"M70.0 50.0 L640.0 50.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"64.0\" y=\"50.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">40 d</text><path d=\"M70.0 240.0 L640.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M125.0 83.2 L205.0 83.2 L205.0 240.0 L125.0 240.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--panel)\"></path><path d=\"M125.0 130.8 L205.0 130.8 L205.0 240.0 L125.0 240.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"165.0\" y=\"73.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">85th: 33</text><text x=\"165.0\" y=\"120.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">median 23</text><text x=\"165.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">July</text><path d=\"M315.0 111.8 L395.0 111.8 L395.0 240.0 L315.0 240.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--panel)\"></path><path d=\"M315.0 178.2 L395.0 178.2 L395.0 240.0 L315.0 240.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"355.0\" y=\"101.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">85th: 27</text><text x=\"355.0\" y=\"168.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">median 13</text><text x=\"355.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">August</text><path d=\"M505.0 202.0 L585.0 202.0 L585.0 240.0 L505.0 240.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--panel)\"></path><path d=\"M505.0 221.0 L585.0 221.0 L585.0 240.0 L505.0 240.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"545.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">85th: 8</text><text x=\"545.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">median 4</text><text x=\"545.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">September</text><path d=\"M260.0 44.0 L260.0 240.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 3\"></path><text x=\"266.0\" y=\"44.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">3 Aug: one item each, reviews first</text><text x=\"70.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cycle time of the items merged each month, in days</text></svg>", "caption": "The chart that carries the review: the change, its size and its timing, in one picture."}
```

## One chart, not fourteen

Of everything the team could show, **one chart carries most of the review**: cycle time per month, median and 85th percentile, with the date the rules changed marked on it. It shows the change, the size of the change and its timing, and it answers the director's first question, whether the 3 August rules should spread to other teams, better than a paragraph could. The DORA numbers and the incident go beside it as text, because each is two or three numbers and a sentence, and a chart for two numbers is decoration.
