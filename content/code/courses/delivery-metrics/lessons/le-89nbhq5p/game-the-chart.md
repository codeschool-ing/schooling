---
title: Gaming the Billing team's numbers, on purpose
version: 1
---

The fastest way to recognise a trick is to perform it once. **Save the program below as `game.py`.** It takes the Billing team's August and September, which already have good numbers, and reports them three ways: as the pipeline recorded them, with each change counted as its own deployment, and with a narrower definition of failure.

```schooling-example
{
  "language": "python",
  "file": "game.py",
  "parts": [
    {
      "code": "\"\"\"game.py: the same August and September, reported three ways.\"\"\"\nimport csv\nimport statistics\nfrom datetime import datetime\n\nmerged = {i[\"id\"]: datetime.fromisoformat(i[\"merged\"])\n          for i in csv.DictReader(open(\"items.csv\")) if i[\"merged\"]}\ndeploys = [d for d in csv.DictReader(open(\"deploys.csv\")) if d[\"at\"] >= \"2026-08\"]\nWEEKS = 61 / 7\n",
      "note": "**August and September only**, the period with the good numbers. The question is how much better they could be made to look without anything changing."
    },
    {
      "code": "\n\ndef report(name, rows):\n    \"\"\"rows: one (deployed at, changes carried, failed, minutes to restore) per deployment.\"\"\"\n    lead = [(at - merged[c]).total_seconds() / 3600 for at, changes, _, _ in rows for c in changes]\n    failed = [minutes for _, _, f, minutes in rows if f]\n    restore = f\"{statistics.median(failed):.0f} min\" if failed else \"-\"\n    print(f\"{name:20} {len(rows) / WEEKS:5.1f}/week  lead {statistics.median(lead):4.1f} h  \"\n          f\"failures {len(failed)}/{len(rows)} = {len(failed) / len(rows):3.0%}  restore {restore}\")\n",
      "note": "**One line of DORA numbers for a list of deployments**, computed the way `dora.py` computes them. Each version below is the same history passed through this function in a different shape."
    },
    {
      "code": "\n\nrows = []\nfor d in deploys:\n    at = datetime.fromisoformat(d[\"at\"])\n    minutes = (datetime.fromisoformat(d[\"restored\"]) - at).total_seconds() / 60 if d[\"failed\"] == \"1\" else 0\n    rows.append((at, d[\"items\"].split(), d[\"failed\"] == \"1\", minutes))\nreport(\"as recorded\", rows)\n",
      "note": "**The history as the pipeline recorded it.**"
    },
    {
      "code": "\nsplit = []\nfor at, changes, failed, minutes in rows:\n    for k, c in enumerate(changes):\n        split.append((at, [c], failed and k == 0, minutes))\nreport(\"one per change\", split)\n",
      "note": "**The first trick: count each change as its own deployment.** Same minute, same code, same failures, and one failed change still means one failure. Nothing reaches users any differently."
    },
    {
      "code": "\nreport(\"only long failures\", [(at, ch, f and m > 60, m) for at, ch, f, m in rows])\n",
      "note": "**The second trick: a narrower definition of failure.** A failure only counts if restoring it took more than an hour. The rule sounds reasonable, *a quick rollback isn't really an incident*, and it is written after looking at the numbers."
    }
  ]
}
```

```
ana@laptop:~/delivery$ python3 game.py
as recorded            4.4/week  lead  4.5 h  failures 2/38 =  5%  restore 52 min
one per change         8.3/week  lead  4.5 h  failures 2/72 =  3%  restore 52 min
only long failures     4.4/week  lead  4.5 h  failures 0/38 =  0%  restore -
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 230\" role=\"img\" data-fig=\"l07-split\" aria-label=\"Two rows showing the same pipeline run at 17:20 carrying three changes, the first of which failed. In the top row it is counted as one deployment; in the bottom row as three deployments at the same minute. The changes, the time they reached users and the one failure are identical in both rows; only the count differs.\"><text x=\"20.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">as recorded</text><path d=\"M160.0 70.0 L640.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><circle cx=\"400.0\" cy=\"70.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"400.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">17:20</text><rect x=\"264.0\" y=\"36.0\" width=\"32.0\" height=\"20.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"304.0\" y=\"36.0\" width=\"32.0\" height=\"20.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"344.0\" y=\"36.0\" width=\"32.0\" height=\"20.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M256 30 L384 30 L384 62 L256 62 Z\" stroke=\"var(--paper)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"560.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">1 deployment</text><text x=\"560.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">failure rate 100%</text><text x=\"20.0\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">one per change</text><path d=\"M160.0 160.0 L640.0 160.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><circle cx=\"400.0\" cy=\"160.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"400.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">17:20</text><rect x=\"264.0\" y=\"126.0\" width=\"32.0\" height=\"20.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"304.0\" y=\"126.0\" width=\"32.0\" height=\"20.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"344.0\" y=\"126.0\" width=\"32.0\" height=\"20.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M260 122 L300 122 L300 150 L260 150 Z\" stroke=\"var(--paper)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M300 122 L340 122 L340 150 L300 150 Z\" stroke=\"var(--paper)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M340 122 L380 122 L380 150 L340 150 Z\" stroke=\"var(--paper)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"560.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">3 deployments</text><text x=\"560.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">failure rate 33%</text><text x=\"340.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the first change failed; all three reached users at the same minute in both rows</text></svg>", "caption": "Splitting changes the count, not the event. Lead time and time to restore are measured on the changes and the failure, so they do not move."}
```

## One per change

Counting each change as a deployment **nearly doubles the deployment frequency**, from 4.4 a week to 8.3, and cuts the failure rate from 5% to 3%. Nothing happened to the code, the users or the two failed changes. The pipeline ran 38 times in either version.

Look at what did **not** move: the lead time for changes is 4.5 hours in both lines, and the time to restore is 52 minutes in both. That is the signature of the trick. Splitting changes how many deployments are counted; it cannot change how long a change waited or how long a failure took to fix, because those are measured on the changes and the failures themselves.

## Only long failures

Redefining a failure as one that took more than an hour to restore **removes both failures**, because both were restored in under an hour, 48 and 55 minutes. The failure rate becomes 0% and the time to restore has nothing left to measure, so it prints a dash.

A dash where a number used to be is worth noticing. A team that has made its change failure rate zero has also, as a side effect, made its time to restore unmeasurable, and a report that shows "0% failures" without a time to restore is showing the trace of a definition, not of a perfect team.

## What it would take to see through it

Both tricks were visible to anybody who looked at more than the improved number:

- **the metrics the trick could not reach stayed where they were**: lead time and restore time in the first case;
- **a number became undefined**: the dash in the second;
- **the raw count changed in a way that matches no event**: 72 deployments from 38 pipeline runs.

The point of performing the tricks yourself is to know these signatures on sight. The next section uses them on the hardest case: a change that really did make batches smaller.
