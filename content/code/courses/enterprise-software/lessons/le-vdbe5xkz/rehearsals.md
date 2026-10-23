---
title: Rehearsals: the night, run before the night
version: 1
---

A migration script that has run once, on a developer's machine, against a sample, has proved that
it can run. It has not proved that it finishes in the time the business can give it, that its
rejects are understood, or that the people running it at three in the morning know what to do
next. **A rehearsal is the whole cutover, run on a copy, by the people who will run it, against the
clock.** The number of them is not a matter of thoroughness: each one finds what the last one could
not, and the plan is ready when a rehearsal finds nothing new.

## Two kinds of run

Serra Alta's plan had four runs, of two different kinds.

**A mock load** tests the mapping. It runs the extraction, the transformation and the load against
some of the data, in working hours, and its output is a list of rejects and wrong rules. The first
used 200 farms and one month of history; the second used every farm and a year. A mock load is
cheap, so it can be repeated as often as the specification changes.

**A dress rehearsal** tests the night. It runs the cutover runbook from the first line to the last,
on a full copy of production, at the hours the real cutover will use, with the people named in the
runbook doing their own steps. Serra Alta ran two, on Saturday nights three weeks apart, starting
at 20:00 like the real one. **At least two, because the first one always finds something, and the
plan needs one run that finds nothing after the fix.**

The distinction matters because the two find different failures. A mock load finds that the
municipality table has a missing spelling. Only a dress rehearsal finds that the extract needs a password held by
somebody who is asleep, or that SAP is in its Sunday maintenance from 01:00 to 05:00 (lesson 1)
exactly when the runbook wanted it. It is also the only run that shows a step everyone thought took
twenty minutes taking three hours on the full volume.

## What a rehearsal measures

Every run produces the same measurements, so that each can be compared with the last:

- *duration*, step by step, from the freeze to the moment the go/no-go decision can be taken;
- *rejects*, by reason, at each step of the pipeline;
- *the reconciliation result* at each of its levels (the next section);
- *the rollback*, timed, in the dress rehearsals: after the decision, the team undoes everything
  and measures how long that takes.

Here are Serra Alta's four runs.

| | mock 1 | mock 2 | dress rehearsal 1 | dress rehearsal 2 |
|---|---|---|---|---|
| data | 200 farms, one month | all farms, one year | full copy | full copy |
| run by | the migration team, by day | the migration team, by day | the runbook, by night | the runbook, by night |
| freeze to decision | not timed | not timed | 11 h 20 min | 5 h 50 min |
| farms rejected | 23 of 200 | 64 of 1,958 | 41 of 1,958 | 3 of 1,958 |
| collection rows rejected | 180 | 610 | 2,412 | 0 |
| reconciliation | counts only | counts and totals | counts and totals agree; 214 rows changed | clean at every level |
| rollback | not tried | not tried | 3 h 05 min | 1 h 55 min |

The numbers do not fall in a straight line. Dress rehearsal 1 rejected more collection rows than
mock 2, because it was the first run with the whole history in it. But each change has a cause
somebody can name, and that is the point of keeping the table: **a reject count that falls because a rule was fixed is
progress; one that falls and nobody knows why is luck**, and it can rise again on the real night.

## What dress rehearsal 1 found

The first dress rehearsal failed in four ways, and every one of them was cheaper to find in July
than on the cutover night.

**It was too slow.** The window is fourteen hours, from Saturday 20:00 to Sunday 10:00. The
rollback needs about two hours, so the go/no-go decision must be taken by 08:00 at the latest, and
the runbook budgets nine hours from the freeze to the decision, leaving three in reserve. The run
took 11 hours 20 minutes. It would have reached the decision at 07:20, with forty minutes in
reserve, and its own rollback took over three hours: had the answer been no, the rollback would
have run until 10:25, past the end of the window.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l14-rehearsals\" aria-label=\"A time chart of the two dress rehearsals against the cutover window, which runs from Saturday 20:00 to Sunday 10:00, fourteen hours. Vertical lines mark the budget for the decision at 05:00, the latest decision at 08:00 and the end of the window at 10:00. Dress rehearsal 1: the run from freeze to decision took 11 hours 20 minutes, reaching 07:20, and its rollback took 3 hours 5 minutes more, ending at 10:25, past the window. Dress rehearsal 2: the run took 5 hours 50 minutes, reaching 01:50, and its rollback 1 hour 55 minutes, ending at 03:45.\"><path d=\"M160.0 196.0 L678.0 196.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M160.0 196.0 L160.0 201.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"160.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">20:00</text><path d=\"M234.0 196.0 L234.0 201.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"234.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">22:00</text><path d=\"M308.0 196.0 L308.0 201.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"308.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">00:00</text><path d=\"M382.0 196.0 L382.0 201.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"382.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">02:00</text><path d=\"M456.0 196.0 L456.0 201.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"456.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">04:00</text><path d=\"M530.0 196.0 L530.0 201.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"530.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">06:00</text><path d=\"M604.0 196.0 L604.0 201.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"604.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">08:00</text><path d=\"M678.0 196.0 L678.0 201.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"678.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10:00</text><text x=\"419.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">hours after the freeze, Saturday night into Sunday</text><path d=\"M493.0 44.0 L493.0 66.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M493.0 98.0 L493.0 134.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M493.0 166.0 L493.0 196.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M604.0 44.0 L604.0 66.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M604.0 98.0 L604.0 134.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M604.0 166.0 L604.0 196.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M678.0 44.0 L678.0 66.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M678.0 98.0 L678.0 134.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M678.0 166.0 L678.0 196.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\"></path><text x=\"489.0\" y=\"34.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">budget</text><text x=\"604.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">latest decision</text><text x=\"678.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">window ends</text><text x=\"150.0\" y=\"82.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">dress rehearsal 1</text><rect x=\"160.0\" y=\"69.0\" width=\"419.3\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><rect x=\"579.3\" y=\"69.0\" width=\"114.1\" height=\"26.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"150.0\" y=\"150.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">dress rehearsal 2</text><rect x=\"160.0\" y=\"137.0\" width=\"215.8\" height=\"26.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"375.8\" y=\"137.0\" width=\"70.9\" height=\"26.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"369.6\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">11 h 20</text><text x=\"641.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">3 h 05</text><text x=\"267.9\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">5 h 50</text><text x=\"411.2\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1 h 55</text><rect x=\"16.0\" y=\"14.0\" width=\"26.0\" height=\"14.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"48.0\" y=\"21.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">run, freeze to decision</text><rect x=\"16.0\" y=\"36.0\" width=\"26.0\" height=\"14.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"48.0\" y=\"43.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">rollback, timed</text></svg>", "caption": "The two dress rehearsals against the window. The first would have reached its decision with forty minutes in reserve and could not have rolled back before the window closed; the second fits with room for both."}
```

The fix that mattered most was not faster code. **A month that has been paid will not change**, so
the history up to the end of the previous month could move days earlier. In dress rehearsal 2 the
closed months were loaded on the Wednesday before and reconciled by Friday, which took 6 hours 40
minutes outside the window; the night itself carried only the farm master and the current month.
The load also committed in batches of 5,000 rows instead of one row at a time, and built the
history table's indexes after the load instead of during it. The window run fell to 5 hours 50
minutes.

**It rejected 41 farms.** Nineteen had a municipality spelling the table did not know,
because new spellings had been typed since the profile. Of the rest, 9 had the invalid CPFs, 4 the
blocked vendors and 2 a blank tax id, and 7 were the duplicates, because the merge table was not
finished. Every reason
went back to its owner, and by the second rehearsal only 3 CPFs were left, which finance corrected
in Coleta the week before the cutover.

**It rejected 2,412 collection rows, and the data was right.** The new system's model declared the
lab results mandatory. In those rows the sample had been lost or spoiled, and in that case Serra
Alta pays the farm the base price for the milk: a lost sample is a fact of the business, not a
fault in the data. Cláudia signed a new rule, lab
results optional with a reason code, and the rows loaded in the next run.

**Its reconciliation passed at two levels and failed at the third.** The counts agreed and so did
the total litres. The record-by-record comparison found 214 collection rows whose litres belonged
to another farm on the same truck route. The transformation had sorted the readings and the farms
separately and joined them by their position in each list; where two farms were collected in a
different order from the one the route file listed, their litres changed places. The next section
shows why only that third level could see it.

## Rehearse the rollback, not only the migration

A rollback plan that has never run is a paragraph. Dress rehearsal 1 ran it for the first time
and it took 3 hours 5 minutes, mostly because nobody had written down how to tell the trucks'
handhelds to send their held readings back to Coleta rather than to the new system. By dress
rehearsal 2 it was a script and a checklist, and it took 1 hour 55 minutes. The runbook uses two
hours.

**A rollback is part of the plan only if its duration is measured.** The latest moment to decide
is the end of the window minus the rollback, and without the measurement that moment is a guess.

## When to stop rehearsing

Serra Alta's rule, written before the first dress rehearsal, was simple: the cutover goes ahead
when a full dress rehearsal fits its time budget, rejects nothing that has no owner, reconciles at
every level, and rolls back inside the window. Dress rehearsal 2 met all four. Had it not, the plan
was a third rehearsal two weeks later and a cutover one month later, after the next payment,
rather than a cutover on hope.
