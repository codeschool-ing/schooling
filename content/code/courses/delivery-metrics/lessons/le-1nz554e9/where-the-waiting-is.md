---
title: Where the waiting actually happens
version: 1
---

A cycle time says how long; it does not say where. Most of an item's life on a board is spent **waiting**: for somebody to start it, for a reviewer, for the next deployment. The board already records when each item entered each column, so the waiting can be located rather than guessed. **Save the program below as `stages.py`**; it reads both files `billing.py` wrote.

```schooling-example
{
  "language": "python",
  "file": "stages.py",
  "parts": [
    {
      "code": "\"\"\"stages.py: where an item's lead time went, column by column.\"\"\"\nimport csv\nimport sys\nfrom datetime import date, datetime\n\nfirst, last = date.fromisoformat(sys.argv[1]), date.fromisoformat(sys.argv[2])\nshipped = {}\nfor d in csv.DictReader(open(\"deploys.csv\")):\n    for item in d[\"items\"].split():\n        shipped[item] = datetime.fromisoformat(d[\"at\"])\n",
      "note": "**When each item reached production**, read from `deploys.csv`: every deployment lists the items it carried, so each item gets the date and time of the one that took it out."
    },
    {
      "code": "\ncolumns = {\"backlog\": [], \"development\": [], \"review\": [], \"waiting to deploy\": []}\nfor i in csv.DictReader(open(\"items.csv\")):\n    if i[\"id\"] not in shipped or not first <= shipped[i[\"id\"]].date() <= last:\n        continue\n",
      "note": "**Only items deployed in the period**, because lead time ends in production, not at the merge."
    },
    {
      "code": "    created, started, review = (date.fromisoformat(i[k]) for k in (\"created\", \"started\", \"review\"))\n    merged = datetime.fromisoformat(i[\"merged\"])\n    columns[\"backlog\"].append((started - created).days)\n    columns[\"development\"].append((review - started).days)\n    columns[\"review\"].append((merged.date() - review).days)\n    columns[\"waiting to deploy\"].append((shipped[i[\"id\"]] - merged).total_seconds() / 86400)\n",
      "note": "**Four stretches that add up to the lead time**: waiting in the backlog, in development, in review, and between the merge and the deployment. The last one is measured in hours and turned into days, because a daily pipeline makes it a matter of hours."
    },
    {
      "code": "\nlead = sum(sum(v) for v in columns.values()) / len(columns[\"backlog\"])\nprint(f\"{len(columns['backlog'])} items deployed, average lead time {lead:.1f} days\")\nfor name, values in columns.items():\n    average = sum(values) / len(values)\n    print(f\"  {name:18} {average:5.1f} days  {average / lead:4.0%}\")\n",
      "note": "**Each column's average, and its share of the lead time.** The shares add up to 100%, give or take the rounding."
    }
  ]
}
```

## June and July

```
ana@laptop:~/delivery$ python3 stages.py 2026-06-01 2026-07-31
51 items deployed, average lead time 42.5 days
  backlog             20.8 days   49%
  development         11.9 days   28%
  review               7.1 days   17%
  waiting to deploy    2.7 days    6%
```

An item deployed in June or July waited, on average, **42.5 days** from request to production. Read the columns as a set of queues:

- **Development took 11.9 days** for items that needed, at the median, about two days of real work. Each developer kept up to three items open and switched between them, so each item spent most of its time in development waiting for its owner to come back to it.
- **Review took 7.1 days, and almost none of that was reviewing.** One person did every review between her other duties. A review takes an hour or two; the rest was the item sitting in a queue in front of Bia. This is the bottleneck the board was showing all along, and the reason work in progress kept climbing through July in lesson 1's chart.
- **Waiting to deploy was 2.7 days**, because the pipeline ran on Thursdays: an item merged on a Friday waited six days for a train.
- **The backlog was the biggest single wait, at 20.8 days.** The team could not start new requests any faster than it finished old ones.

## September

```
ana@laptop:~/delivery$ python3 stages.py 2026-09-01 2026-09-30
30 items deployed, average lead time 32.5 days
  backlog             27.3 days   84%
  development          3.6 days   11%
  review               1.3 days    4%
  waiting to deploy    0.3 days    1%
```

Every queue **inside** the team shrank. Development fell from 11.9 days to 3.6, review from 7.1 to 1.3, the wait for a deployment from 2.7 days to a few hours. The team's cycle time, development and review together, fell from 19 days to 5.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 220\" role=\"img\" data-fig=\"l02-stages\" aria-label=\"Two stacked bars of average lead time in days. June and July: 42.5 days, of which 20.8 in the backlog, 11.9 in development, 7.1 in review and 2.7 waiting to deploy. September: 32.5 days, of which 27.3 in the backlog, 3.6 in development, 1.3 in review and 0.3 waiting to deploy.\"><text x=\"120.0\" y=\"66.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">June and July</text><path d=\"M130.0 50.0 L369.2 50.0 L369.2 82.0 L130.0 82.0 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"var(--panel)\"></path><text x=\"249.6\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">20.8</text><path d=\"M369.2 50.0 L506.1 50.0 L506.1 82.0 L369.2 82.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"var(--scan)\"></path><text x=\"437.6\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">11.9</text><path d=\"M506.1 50.0 L587.7 50.0 L587.7 82.0 L506.1 82.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"var(--panel)\"></path><text x=\"546.9\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">7.1</text><path d=\"M587.7 50.0 L618.8 50.0 L618.8 82.0 L587.7 82.0 Z\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"var(--scan)\"></path><text x=\"626.8\" y=\"66.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">42.5 days</text><text x=\"120.0\" y=\"136.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">September</text><path d=\"M130.0 120.0 L443.9 120.0 L443.9 152.0 L130.0 152.0 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"var(--panel)\"></path><text x=\"287.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">27.3</text><path d=\"M443.9 120.0 L485.3 120.0 L485.3 152.0 L443.9 152.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"var(--scan)\"></path><path d=\"M485.3 120.0 L500.3 120.0 L500.3 152.0 L485.3 152.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"var(--panel)\"></path><path d=\"M500.3 120.0 L503.7 120.0 L503.7 152.0 L500.3 152.0 Z\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"var(--scan)\"></path><text x=\"511.7\" y=\"136.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">32.5 days</text><path d=\"M130.0 190.0 L144.0 190.0 L144.0 202.0 L130.0 202.0 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"var(--panel)\"></path><text x=\"150.0\" y=\"196.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">backlog</text><path d=\"M260.0 190.0 L274.0 190.0 L274.0 202.0 L260.0 202.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"var(--scan)\"></path><text x=\"280.0\" y=\"196.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">development</text><path d=\"M390.0 190.0 L404.0 190.0 L404.0 202.0 L390.0 202.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"var(--panel)\"></path><text x=\"410.0\" y=\"196.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">review</text><path d=\"M520.0 190.0 L534.0 190.0 L534.0 202.0 L520.0 202.0 Z\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"var(--scan)\"></path><text x=\"540.0\" y=\"196.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">to deploy</text><text x=\"130.0\" y=\"24.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">average lead time of items deployed in the period, by column</text></svg>", "caption": "Every queue inside the team shrank, and the requester waits only ten days less: the backlog grew to fill most of the gain."}
```

And the requester's lead time fell only from 42.5 days to **32.5**. The backlog wait went **up**, from 20.8 days to 27.3, and it is now 84% of everything a requester waits for. Nothing went wrong. Requests that arrived in July, while the team was clogged, are still queued; the team now finishes them faster than before, but it started September with about twenty of them waiting, and a queue of twenty in front of a team that finishes one a day is a wait of about twenty days. Little's law again, applied to the backlog instead of the board.

## What to do with that

This is the most common surprise when a team first measures its lead time, and the most useful. **Improving cycle time is necessary and is not enough**: once the work moves quickly, the biggest wait is the one before anybody starts. Three moves follow, and none of them is "work faster":

- **Say no sooner.** A request that will not be done for a month is better declined, or deferred explicitly, than left in a queue where it looks accepted.
- **Keep the backlog short and ordered.** A backlog of twenty items at a throughput of one a day is a promise of a three-week wait for anything new, unless it jumps the queue.
- **Quote both clocks.** A stakeholder told "our cycle time is four days" and then waiting a month has been misled, even though every word was true.
