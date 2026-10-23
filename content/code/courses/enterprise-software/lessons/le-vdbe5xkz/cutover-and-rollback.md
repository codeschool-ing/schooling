---
title: Cutover and rollback, and the point of no return
version: 1
---

Cutover is the moment the new system becomes the master and the old one stops being it. In a
system that is deployed several times a day, that moment is a release, and a release that goes
wrong is rolled back by deploying the previous version. **A data migration cannot be rolled back
by redeploying anything**, because from the moment the new system takes its first real reading,
the two systems hold different facts. Everything in this section follows from that.

## Joana's first plan

At the fintech Joana came from, a change to the data was a migration script that ran during the
deploy, and if it failed the deploy failed and nothing had changed. Her first cutover plan for
Coleta's data had the same shape: freeze Coleta, run the migration, switch the trucks over, all in
one job.

Sebastião asked one question at the review: if the job fails at three in the morning, on which
system are the farms paid on the 10th? The plan had no answer, because a job is not a plan. **A
cutover plan is a timed runbook, with an owner for every step, the criteria for going ahead
written before the night, and a way back that has been run.**

## The window

The cutover had to fit somewhere the business could give it, and Serra Alta's calendar left
little choice. The trucks collect every day of the year, so there is no quiet day, only a quieter
night. Finance closes the month in the first five working days and the SAP team freezes changes that
week (lesson 1), so the first week of the month was out. And the farms are paid on the 10th, so the
further the cutover sat from the next 10th, the longer the new system had to prove itself before
it paid anybody.

The window chosen was **Saturday 20:00 to Sunday 10:00, on the Saturday after the September payment**:
fourteen hours, just after one payment and as far from the next as the calendar allowed. During those
hours the trucks still collect. Their handhelds keep the readings and send them once a system is
ready to take them, the store-and-forward behaviour lesson 12 describes.

## The runbook

The runbook is a table that a tired person can follow without thinking: a time, a step, the person
who does it, and how they know it is done.

| time | step | who | done when |
|---|---|---|---|
| Sat 19:45 | Coleta writes its last nightly file for SAP | Sebastião | the file is in the transfer folder |
| 20:00 | freeze: Coleta becomes read-only, handhelds hold their readings | Sebastião, the Rota team | a test reading is refused by Coleta |
| 20:15 | final extract: the farm master and the current month's collections | Sebastião | extract counts written in the log |
| 20:45 | delta load into the new system | migration team | load finished, rejects counted |
| 23:30 | reconciliation at all three levels | Joana | every difference explained by a rule |
| 00:30 | sampling: 40 farms for quality, 40 vendor links | Cláudia's team, finance | both signed |
| 02:00 | integrations switched: handhelds, Rota, the file to SAP | Rui | each points at the new system |
| 03:00 | smoke test: one truck's handheld sends a test reading | the Rota team | the reading appears in the new system |
| **05:00** | **go/no-go** | Regina, with Marcos | the criteria below, read out one by one |
| 05:30 | Coleta's last file loads into SAP, after SAP's Sunday maintenance | Edson | goods receipts posted |
| 06:00 | handhelds release their held readings | the Rota team | held count drops to zero |
| 10:00 | the window closes | Joana | hypercare starts |

Two lines in it exist only because of the rest of the estate. The last Coleta file is written
before the freeze, because Coleta will not write another. And it loads into SAP at 05:30 rather
than at the usual 02:00, because SAP is down for maintenance from 01:00 to 05:00 every Sunday.
**A cutover is a change to every integration that touches the system**, and a runbook that lists
only the data steps forgets the ones that break first.

## Go/no-go, written before the night

The go/no-go meeting at 05:00 is short because the criteria were written and agreed weeks before,
when nobody was tired and nobody had spent the night on it:

1. the reconciliation is clean at every level, and every difference is an expected one: 1,951
   farms, the 7 merges, no rejects;
2. Cláudia and finance have signed their samples;
3. the smoke test reading arrived;
4. it is no later than 08:00.

**Criteria written on the night are criteria bent on the night.** At five in the morning, after
nine hours of work, every person in the room wants the answer to be yes, and "the reconciliation
is nearly clean" sounds like a reason. Written in advance, the question is only whether each line
is true. A no is not a failure of the night; it is the plan working.

The last criterion is arithmetic. The window closes at 10:00 and the rollback, measured in dress
rehearsal 2, takes about two hours. So **the latest moment to decide is 08:00**, and a decision
not taken by then is taken anyway, in favour of rolling back. The runbook aims for 05:00, which
leaves three hours in reserve. On the night, the last criterion was met at 03:10, and the answer at
05:00 was go.

## The point of no return

Rolling back does not cost the same at every moment after the freeze. It grows, and at one moment
it stops being possible in any useful sense.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" data-fig=\"l14-cutover\" aria-label=\"A timeline of the cutover with the cost of going back drawn above it. The left part of the axis is the night, from the freeze at Saturday 20:00 through the planned go/no-go at 05:00 and the latest decision at 08:00 to the end of the window at 10:00. After a break, the right part is the following weeks, to the 9th, when the bank file for the first payment from the new system is sent: the point of no return. Above the axis, the cost of going back rises in steps: before the go, a rehearsed two-hour rollback with nothing lost; after the go, carrying every day of readings back into Coleta, growing each day; after the bank file, reversing payments to about 1,900 farms, which nobody would do.\"><defs><marker id=\"l14-cutover-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M48.0 214.0 L334.0 214.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M342.0 207.0 L334.0 221.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M350.0 207.0 L342.0 221.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M348.0 214.0 L712.0 214.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l14-cutover-es-ah-paper-dim)\"></path><rect x=\"48.0\" y=\"180.0\" width=\"180.0\" height=\"34.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"138.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">rollback: 2 h, rehearsed</text><path d=\"M228.0 214.0 L228.0 154.0 L596.0 94.0 L596.0 214.0 Z\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"var(--panel)\"></path><text x=\"470.0\" y=\"155.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">carry the readings back to Coleta:</text><text x=\"470.0\" y=\"168.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">about 4 h per day of readings</text><rect x=\"596.0\" y=\"42.0\" width=\"116.0\" height=\"172.0\" rx=\"1\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"654.0\" y=\"64.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">reverse</text><text x=\"654.0\" y=\"77.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">payments</text><text x=\"654.0\" y=\"90.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">to ~1,900</text><text x=\"654.0\" y=\"103.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">farms</text><text x=\"24.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">cost of going back</text><path d=\"M48.0 210.0 L48.0 222.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"48.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Sat 20:00</text><text x=\"48.0\" y=\"248.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">freeze</text><path d=\"M228.0 210.0 L228.0 222.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"228.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">05:00</text><text x=\"228.0\" y=\"248.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">go/no-go</text><path d=\"M288.0 210.0 L288.0 256.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"288.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">08:00</text><text x=\"288.0\" y=\"282.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">latest decision</text><path d=\"M328.0 210.0 L328.0 290.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"328.0\" y=\"302.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10:00</text><text x=\"328.0\" y=\"316.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">window ends</text><path d=\"M596.0 210.0 L596.0 222.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"596.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the 9th</text><text x=\"596.0\" y=\"248.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">bank file sent</text><text x=\"596.0\" y=\"296.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">point of no return</text><text x=\"470.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">weeks of hypercare</text></svg>", "caption": "The cost of going back grows after every step of the cutover. The night’s rollback is cheap and rehearsed; once the first payment from the new system has left, there is no going back, only fixing forward."}
```

**Before the go decision**, a rollback is the rehearsed one: unfreeze Coleta, point the handhelds
back at it, release their readings there, and leave the new system's copy to be thrown away. Two
hours, and nothing is lost.

**After the go, until the payment**, the new system takes every reading the trucks send. Going back
now means carrying those readings back into Coleta, which is a migration in the other direction.
Serra Alta wrote that procedure and ran it once in dress rehearsal 2 with one day of readings;
it took four hours. Every day after the cutover adds a day of readings to carry back, so the cost
grows daily, but it is still possible.

**The first payment from the new system is the point of no return.** The farms are SAP vendors
(lesson 1): the new system calculates what each one has earned for September, the amounts are posted
in SAP, and SAP's payment run produces the bank file that finance sends on the 9th. Once that file has gone, going back to
Coleta would mean that the record of what was paid lives in a system that no longer calculates it,
and undoing it would mean asking about 1,900 farms to return their money. Nobody would do that, so
it is not a rollback; it is a fix forward.

**The point of no return exists whether anybody names it or not.** Naming it changes two things.
It sets the last date for the decision to go back, with the people and the criteria for taking it:
at Serra Alta, the 8th, after the payment run has been calculated and checked and before the file
is sent. And it tells everybody that from then on every problem is fixed forward, so the effort
that went into keeping the way back open goes into fixing.

## A rollback is rehearsed, not written

Every rollback in this section had been run before the night, with a measured time: the first in
both dress rehearsals, the second once, with a day of readings. **A rollback that has only been
written is a hope with headings**, and the night it is needed is the worst night to find that a
step was missing. Dress rehearsal 1's rollback found exactly that: nobody had written down how to
send the handhelds' held readings back to Coleta.
