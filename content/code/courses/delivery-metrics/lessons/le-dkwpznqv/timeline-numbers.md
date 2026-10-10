---
title: The intervals inside an incident
version: 1
---

A timeline is not only a story. Tagged as the previous section suggests, it is data, and the intervals between its moments say where the time went, the way lesson 2's columns said where an item's time went. **Save the program below as `timeline.py`**; the scribe's timeline of 30 September is written inside it.

```schooling-example
{
  "language": "python",
  "file": "timeline.py",
  "parts": [
    {
      "code": "\"\"\"timeline.py: the scribe's timeline of 30 September, and the intervals inside it.\"\"\"\n\n# Written by the scribe during the incident, one line per event, in local time.\nTIMELINE = \"\"\"\n17:20 change   D047 deployed: BIL-218, BIL-223, BIL-224, BIL-225\n17:21 impact   first duplicate charge, found later in the payment logs\n17:38 detect   a shop owner calls support: charged twice for her subscription\n17:41 report   Lia (support) posts in the team channel with the shop and both charge ids\n17:44 ack      Rafa (on call) acknowledges; finds 11 more duplicates\n17:46 declare  incident declared, SEV2, channel #inc-0930-double-charge\n17:49 roles    Bia IC, Rafa technical lead, Duda scribe, Caio communications\n17:53 severity raised to SEV1: 140 duplicate charges and rising\n17:55 comms    status page notice; support given a sentence for callers\n18:02 decide   roll back D047 now; find the faulty change afterwards\n18:04 action   rollback started\n18:15 restore  rollback complete; no duplicate charge after 18:15\n18:20 action   query: 212 duplicate charges across 167 shops\n18:40 action   refunds of the duplicates start, in batches of 50\n21:10 resolve  all 212 duplicates refunded; incident closed\n21:15 comms    final update; postmortem booked for Friday 2 October\n\"\"\"\n\n",
      "note": "**The timeline is the data**, typed into the program as the scribe wrote it: a time, a kind of event, and what happened. The kinds are a small fixed vocabulary, so a program can find the moments that matter."
    },
    {
      "code": "events = {}\nfor line in TIMELINE.strip().splitlines():\n    clock, kind, _ = line.split(maxsplit=2)\n    hours, minutes = clock.split(\":\")\n    events.setdefault(kind, int(hours) * 60 + int(minutes))\n\n",
      "note": "**Each kind of event, and the first time it appears.** The clock times become minutes since midnight so they can be subtracted."
    },
    {
      "code": "phases = [(\"impact\", \"detect\", \"until anybody noticed\"),\n          (\"detect\", \"declare\", \"until an incident was declared\"),\n          (\"declare\", \"decide\", \"until the decision to roll back\"),\n          (\"decide\", \"restore\", \"until service was restored\"),\n          (\"restore\", \"resolve\", \"until every shop was refunded\")]\nstart = events[\"impact\"]\nfor a, b, label in phases:\n    print(f\"{events[b] - events[a]:4} min  {label}\")\nprint(f\"{events['restore'] - start:4} min  from the first duplicate charge to restored\")\nprint(f\"{events['resolve'] - start:4} min  from the first duplicate charge to resolved\")\n",
      "note": "**The intervals between the moments**: how long each phase of the incident took, and the two totals a report would quote."
    }
  ]
}
```

```
ana@laptop:~/delivery$ python3 timeline.py
  17 min  until anybody noticed
   8 min  until an incident was declared
  16 min  until the decision to roll back
  13 min  until service was restored
 175 min  until every shop was refunded
  54 min  from the first duplicate charge to restored
 229 min  from the first duplicate charge to resolved
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 220\" role=\"img\" data-fig=\"l14-phases\" aria-label=\"A timeline of the incident of 30 September from 17:21 to 21:10, in phases: 17 minutes before anybody knew, 8 to declare, 16 to decide, 13 to restore by rolling back, and 175 to refund every shop. The shops were being harmed for the first 54 minutes.\"><path d=\"M30.0 80.0 L76.0 80.0 L76.0 114.0 L30.0 114.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"var(--scan)\"></path><path d=\"M53.0 78.0 L53.0 36.0\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"50.0\" y=\"30.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">nobody knew: 17 min</text><path d=\"M76.0 80.0 L97.7 80.0 L97.7 114.0 L76.0 114.0 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"var(--scan)\"></path><path d=\"M86.9 78.0 L86.9 52.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"83.9\" y=\"46.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">to declare: 8 min</text><path d=\"M97.7 80.0 L141.0 80.0 L141.0 114.0 L97.7 114.0 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"var(--scan)\"></path><path d=\"M119.3 78.0 L119.3 68.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"116.3\" y=\"62.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">to decide: 16 min</text><path d=\"M141.0 80.0 L176.2 80.0 L176.2 114.0 L141.0 114.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"var(--scan)\"></path><path d=\"M158.6 116.0 L158.6 134.0\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"155.6\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">rollback: 13 min</text><path d=\"M176.2 80.0 L650.0 80.0 L650.0 114.0 L176.2 114.0 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"var(--scan)\"></path><text x=\"413.1\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">refunding every shop: 175 min</text><path d=\"M30.0 118.0 L30.0 160.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"30.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">17:21</text><path d=\"M176.2 118.0 L176.2 160.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"176.2\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">18:15</text><path d=\"M650.0 118.0 L650.0 160.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"650.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">21:10</text><text x=\"34.0\" y=\"196.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">shops being double-charged</text><path d=\"M30.0 188.0 L176.2 188.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"650.0\" y=\"20.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the incident of 30 September, phase by phase</text></svg>", "caption": "Restoring took under an hour and resolving took four. DORA counts the first; the shops lived through both."}
```

## Reading the phases

**Seventeen minutes until anybody noticed**, and the noticing was a customer's phone call. Of the 54 minutes the shops were being double-charged, almost a third passed before the team knew. No amount of speed in the response could recover those minutes; only detection can, and lesson 18 asks what alert would have caught this.

**Eight minutes to declare** is fast. Lia asked within three minutes of the call, and Rafa declared two minutes after acknowledging. A team that waits to be sure, lesson 13's warning, typically loses more here than anywhere else.

**Sixteen minutes to decide** is where the response could have been quicker. Most of it was spent confirming which change was at fault, which a rollback does not need to know. **Mitigation first** would have saved perhaps ten minutes; on a payments product, ten minutes is a lot of duplicate charges.

**Thirteen minutes to restore** is what a small release buys: the rollback itself took eleven of them.

**175 minutes to resolve** is the cleanup, and it is the longest phase by far. It is invisible in DORA's time to restore and it is the part the shops felt most, because a refund took hours to reach each of them.

## Names, and a warning about averages

These intervals have common names, usually with *mean time to* in front: **time to detect**, **time to acknowledge**, **time to mitigate**, **time to resolve**. They are useful as long as each incident's phases are kept. Averaged across incidents into "MTTR", they behave like lesson 2's average cycle time: one long incident dominates, the shape disappears, and the number describes no incident that happened. **Look at the phases of each serious incident, and at the distribution across incidents, before quoting a mean.**
