---
title: State that lives for a month
version: 1
---

An engineer who has built web services thinks of work as a request: it arrives, it is handled, a
response goes back, and nothing about it is left in memory. Joana arrived at Serra Alta thinking of
processes that way, as a request that happens to be slow. **A process instance is not a slow request.
It is a record that outlives deployments, restarts, reorganisations and the model it was started
from.** Almost everything that goes wrong with a process engine comes from that difference.

## A farm takes a month to join

Farm onboarding at Serra Alta starts when a field technician visits a producer who wants to sell
milk. Then the instance waits for things that happen at the speed of a farm, not of a computer:

1. the producer sends documents: tax registration, bank details, the herd's health certificates;
2. the quality team visits the farm to inspect the milking and the cooling tank;
3. the lab analyses a first sample of the milk;
4. the producer signs the supply contract;
5. the farm is created as a vendor in SAP, since Serra Alta pays it (lesson 1), and typed into
   Coleta so that trucks collect from it.

The median instance takes about 30 days. Some take three months, because the producer's
certificates had expired or the contract went back and forth. During those days the engine is
redeployed, its servers are patched and restarted, people go on holiday, and the process itself may
be changed. The instance has to come through all of it with its position and its variables intact,
which is why it lives in the engine's database and not in any program's memory.

## How many should be open

There is a simple check on whether an engine is healthy, and it is worth doing on the first day you
are responsible for one. **The number of instances open at any moment is the number started per day
multiplied by how long each one lasts.** This is Little's law, published by John Little in 1961, and
it holds for any system where things arrive, stay a while and leave.

For Serra Alta's three processes:

| process | started per year | lasts | expected open |
| --- | --- | --- | --- |
| farm onboarding | 220 | 30 days | 220 × 30 / 365 = 18 |
| credit approval | 1,400 | 4 days | 1,400 × 4 / 365 = 15 |
| supplier registration | 600 | 12 days | 600 × 12 / 365 = 20 |
| all three | | | about 53 |

Joana opened the admin console in her second month and asked how many instances were active. The
answer was **1,986**. Either the arithmetic was wrong by a factor of more than thirty, or most of those
instances were not alive in any sense that mattered. It was the second. Vinícius spent two days
sorting them:

- 61 were real work in progress, close enough to the 53 the table predicts;
- 1,610 were farm onboarding instances whose farms had been supplying milk for years;
- 315 were supplier registrations that had stopped at an error in their last step.

The next two parts of this section explain the 1,610 and the 315. The arithmetic is what found them.
Nothing in the product had complained.

## The task nobody picks up

The 1,610 came from a parallel branch. When a farm is created, the 2014 model also sends a task to a
group called *Fomento leiteiro*, the field development team, to book a follow-up visit at 90 days.
The instance only ends when both branches are done. In 2019 that team was folded into the quality
team, its members were moved to other groups, and the follow-up visit started being scheduled from
Rota instead. Nobody changed the process. **Since 2019 every farm onboarding has finished its real
work and then waited, forever, for a task in the list of a group with no members.**

Nobody noticed because nothing was missing. The farms were collected and paid. The visits happened,
booked elsewhere. The only symptom was a count that nobody looked at.

This is the commonest failure of a process engine, and it has the same root every time. Tasks go to
roles and groups so that work survives a person leaving. That means the process depends on the
organisation chart, and the organisation chart changes without anybody opening the process designer.
The defences are cheap:

- watch the age of the oldest open task in each group, and alert when it passes what the process
  allows;
- treat a group with tasks and no members as an error, not as a quiet state;
- give every human task a deadline, so that waiting too long is an event the model handles. Lesson 7
  draws these timers; in Serra Alta's 2014 model the quality visit has none at all, so a visit nobody
  schedules waits indefinitely.

## The call that failed on a Sunday

The 315 supplier registrations had failed at their last step, the call that creates the vendor
record in SAP. Most of the failures had a timestamp between 01:00 and 05:00 on a Sunday, which is SAP's weekly maintenance window (lesson 1). A buyer had finished the registration on
Saturday night, the engine called SAP while it was down, and the call failed. The instance went into a failed state
and waited for somebody to retry it from the admin console. Nobody did. On Monday the buyer, seeing
no vendor in SAP, created it by hand.

So for 315 suppliers the BPM history says "not registered" and SAP says the opposite, and the
approval trail the process was built to keep points at a vendor record it never created. The failure
was silent in the engine and invisible in SAP. **An integration step inside a process needs a retry
policy that knows the other system's calendar**, and somebody whose job it is to look at the
instances that ran out of retries. Lesson 12 comes back to maintenance windows as part of a contract
between systems.

## Changing the process while instances are running

In 2023 Serra Alta decided that a new farm must show its registration in the CAR, Brazil's rural
environmental registry, before its first collection. Denise's office asked for a new step in farm
onboarding. The change itself was small. The question it raised was not: what happens to the 18
farms already halfway through?

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l06-versions\" aria-label=\"Farm onboarding instances drawn as bars across six months, January to June. Version 1 of the process, the 2014 model, runs every instance started before 1 March. On 1 March version 2 is deployed, and every instance started after that runs on it. Three version 1 instances started in January and February simply finish on version 1, side by side with version 2 instances. A fourth is migrated to version 2 on 1 March, and the question at the migration is where its current step is in the new model; if version 2 deleted the step it was waiting on, the instance has nowhere to stand.\"><defs><marker id=\"l06-versions-es-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><path d=\"M150.0 268.0 L702.0 268.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M150.0 264.0 L150.0 272.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"196.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Jan</text><path d=\"M242.0 264.0 L242.0 272.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"288.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Feb</text><path d=\"M334.0 264.0 L334.0 272.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"380.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Mar</text><path d=\"M426.0 264.0 L426.0 272.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"472.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Apr</text><path d=\"M518.0 264.0 L518.0 272.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"564.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">May</text><path d=\"M610.0 264.0 L610.0 272.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"656.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Jun</text><text x=\"70.0\" y=\"97.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">version 1</text><text x=\"70.0\" y=\"112.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">(2014 model)</text><text x=\"70.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">version 2</text><path d=\"M334.0 30.0 L334.0 74.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M334.0 96.0 L334.0 99.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M334.0 121.0 L334.0 189.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M334.0 211.0 L334.0 264.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"334.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">1 March: version 2 deployed</text><rect x=\"177.6\" y=\"52.0\" width=\"101.2\" height=\"16.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><rect x=\"251.2\" y=\"77.0\" width=\"105.8\" height=\"16.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><rect x=\"301.8\" y=\"102.0\" width=\"105.8\" height=\"16.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><rect x=\"320.2\" y=\"132.0\" width=\"13.8\" height=\"16.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"415.6\" y=\"85.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">started on version 1,</text><text x=\"415.6\" y=\"99.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">finish on version 1</text><rect x=\"334.0\" y=\"192.0\" width=\"87.4\" height=\"16.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><path d=\"M336.0 148.0 L336.0 190.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l06-versions-es-ah-amber)\"></path><text x=\"344.0\" y=\"165.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">migrated: which step of version 2 is it on now?</text><rect x=\"347.8\" y=\"217.0\" width=\"96.6\" height=\"16.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><rect x=\"462.8\" y=\"217.0\" width=\"101.2\" height=\"16.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><rect x=\"554.8\" y=\"237.0\" width=\"110.4\" height=\"16.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"360.0\" y=\"312.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--amber)\">both versions run at once for as long as the oldest instance lives</text></svg>", "caption": "Deploying a new version does not move the instances already running. They finish on the model they started on, unless somebody migrates them and answers the question on the arrow."}
```

Process engines answer it the same way in principle. A new version of the model is deployed beside
the old one, and **each instance keeps running on the version it started on** unless somebody
deliberately moves it. Version 1 and version 2 run side by side until the last version 1 instance
ends. For farm onboarding that is about a month. For a process whose instances last a year, two or
three versions are always alive at once.

There are two ways to deal with the instances in flight.

**Let them drain.** The 18 farms finish on version 1, without the CAR step, and somebody collects the
18 registrations by hand. This is the safe default when the old version is still correct enough and
the instances are few.

**Migrate them.** The engine moves each instance to version 2. That means answering, for every step
an instance could be waiting on, where it stands in the new model. If version 2 still has the step,
the answer is easy. If version 2 deleted or merged it, the instance has nowhere to stand. IBM's
documentation calls the marker of an instance's position a *token*, and a token left on a step that
no longer exists an *orphaned token*. Its migration tooling lets you move such tokens to another step
or delete them, and somebody has to decide which, step by step. The variables raise the same
question: version 2 expects a CAR number, and a migrated instance does not have one.

**Every change to a running process has two populations, the instances to come and the instances in
flight, and the change is not designed until both have an answer.** Serra Alta drained, and that was
the right call. It also missed something the count above makes obvious now. Version 2 kept the branch
that sends a task to *Fomento leiteiro*, four years after the group was emptied. The people changing the process looked at the step they were adding and not at the ones already there.

## The second database nobody reports from

The engine's database holds more than positions. Each instance carries its variables, and each
completed step leaves a history: who claimed it, when, what the form said when they pressed the
button. For credit approval that is the only record of who decided each limit, which the auditors ask
for. For farm onboarding it is the date each farm's health certificate was checked and by whom.

That makes the engine **a second database of business facts, and nobody treats it as one**. SAP's
data is copied every night into the warehouse, and finance reports on it. The engine's data is
copied nowhere. Its tables are the product's internals rather than an interface the vendor promises
to keep, so nobody built reports on them, and the only way to answer an auditor's question is to ask
Vinícius to look it up.

Three consequences follow. Reports about the processes themselves (how long credit approvals take,
which step of onboarding is slowest) need an export the company builds deliberately, and Serra Alta
has none. The history is evidence, so it falls under the retention rules lesson 5 described for
records. And whenever the suite is retired, the history has to be carried somewhere a person can
still read it, which is a migration in its own right (lesson 14).
