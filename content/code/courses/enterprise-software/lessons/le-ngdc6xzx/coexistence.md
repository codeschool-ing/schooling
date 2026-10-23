---
title: Coexistence, the long middle
version: 1
---

Plans for a strangler spend their pages on the beginning, where the facade goes in, and on the
end, where the old system goes off. **Most of the migration's life is spent in neither: it is the
middle, where both systems run, each owns part of the work, and data has to be in both.** At Serra
Alta the middle starts in March 2027, when the quality service takes over the laboratory results,
and lasts until Coleta is read-only, which the plan puts in July 2028. That is sixteen months in
the plan, and every migration Joana has read about took longer in its middle than its plan said.

So the middle is not a transition to get through. It is a state the company lives in, and it is
designed with the same care as anything else that runs for a year and a half.

## One owner for every piece of data, at every moment

The first design decision is about ownership. For each kind of data, at each phase, exactly one
system is the master: the one where it is created and changed. **The other system may hold a copy,
but it never accepts a change to it.** Joana's plan states this as a table, and the table is
published where the clerks, the SAP team and the bus team can all read it.

| data | today | phase 1, March 2027 | phase 2, September 2027 | phase 3, April 2028 |
|---|---|---|---|---|
| laboratory results | Coleta | **new**, copied to Coleta | new, copied to Coleta | new |
| daily collections | Coleta | Coleta, copied to new | **new**, copied to Coleta | new |
| farm register: tanks, routes, collection days, status | Coleta | Coleta, copied to new | Coleta, copied to new | **new** |
| monthly payment amounts | Coleta | Coleta | Coleta | **new** |
| nightly file to SAP | Coleta | Coleta | Coleta | **new** |
| vendor record and bank account | SAP | SAP | SAP | SAP |

Each column is a phase with a date, and each bold cell is a change of master on that date. The dates
are the plan's first draft, made before anybody had chosen what replaces the payment, and they
assume it is built in house; lesson 15 compares the options, and its decision moves phase 3, the
read-only date and the switch-off with it. With the dates lesson 15 settles, phases 2 and 3
collapse into the single cutover lesson 14 describes. Reading along a row shows the life of one kind of data. Laboratory results move first, as asset capture
said they should. Collections follow in phase 2, which is when the handheld intake stops passing
files to Coleta raw and starts sending it the collections the new service has accepted. The farm
register and the payment move together in phase 3, because the payment needs the register's
quality status and collection days and splitting them would mean synchronising both ways.

The last row is there on purpose. The farms are vendors in SAP, and SAP holds their tax numbers and
bank accounts (lesson 1). That does not move at all. A table that only listed what changes would
let somebody assume that bank details were part of Coleta's migration, and somebody would.

## Copies flow one way, from the master

Where a cell says "copied to", the copy flows from the master to the other system and never back.
**Synchronisation in both directions is two systems that both think they own the data, and
sooner or later they disagree with nobody able to say which one is right.** When the direction has
to change, it changes on a phase's date, for a whole kind of data at once, and the screens that
used to accept changes stop accepting them that day.

Each copy has a defined path. Copies out of Coleta come from its journals through change data
capture, translated by the anti-corruption layer. Copies into Coleta go through the layer's
outbound side, written in Coleta's own formats into the files and tables it already reads. Both
paths are monitored for lag, and both have an alarm when nothing has moved for longer than it
should have.

## No dual writes

The shortcut that breaks this is predictable, and Joana's plan names it in advance. In phase 2 the
clerks will correct collections in the new system, and somebody will propose that the correction
screen should also call a Coleta program directly, so Coleta has the change at once rather than
through the outbound copy a few minutes later.

That is a dual write: one action that writes to two systems that share no transaction. **When the
second write fails after the first succeeded, the two systems disagree and nothing records that
they do.** The clerk sees a saved correction; Coleta never got it; the farm is paid on the old
figure. It fails rarely, which is the worst way to fail, because it fails in the one case nobody
tested and is found weeks later by a farmer.

The alternative is the one the table already implies. Write once, to the master, and let the copy
follow from the master's own record of what changed, retried until it arrives. Lesson 10 shows the
transactional outbox, which does that for a system you write, and lesson 9 introduced change data
capture, which does it for one you cannot change. The
price is a few minutes in which Coleta is behind, and the plan makes that visible instead of
pretending it away: Coleta's screens for collections show the time of the last copy received.

## Reconciliation, every morning

Copies drift even when every part works, because a message is held up, a file arrives late or a
journal entry is not translated. So every morning at 06:00 a job compares the two sides. For each
plant and each day it counts the collections and adds up the litres in the new service and in
Coleta, and every difference goes to the clerks' queue with the farms involved. **A difference
found the next morning costs a correction; the same difference found on payment day costs a farm's
trust.** Lesson 14 is about reconciliation as a technique, with counts, control totals and
per-record comparison; here it is the daily routine that makes coexistence safe to live in.

## The parallel run, before moving money

Phase 3 moves the payment, which is the capability where a mistake reaches 1,900 bank accounts.
The standard protection is to run the new calculation beside the old one on the same inputs, for
several months, and compare the results farm by farm while the old system's figures are the ones
paid. Sam Newman describes this as a parallel run in *Monolith to Microservices* (2019).

Joana did not wait for phase 3 to start one. Whatever replaces Coleta's payment, bought, built or
added to SAP, will have to reproduce its rules, and nobody could yet say what all the rules were.
So in mid-2026 the team wrote the payment as a shadow calculation: a small program fed with Coleta's
own data through the anti-corruption layer, computing what every farm should be paid. It ran beside
Coleta for three months, on the milk of July, August and September 2026. Coleta's figures were the
ones paid throughout; the shadow's went nowhere except into the comparison.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l13-parallel\" aria-label=\"The three months of the shadow calculation, one bar each, counting only the farms whose payment differed from Coleta's; the rest were identical to the centavo. July 2026: 1,871 identical and 29 different, made of 17 rounding, 9 from an unwritten rule and 3 from a defect on the new side. August: 1,897 identical and 3 different, all an accepted change of rule. September: 1,898 identical and 2 different, both the same accepted change.\"><text x=\"186.0\" y=\"33.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">July 2026</text><text x=\"186.0\" y=\"49.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1,871 identical</text><rect x=\"200.0\" y=\"28.0\" width=\"204.0\" height=\"24.0\" rx=\"1\" fill=\"var(--wire)\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\"></rect><rect x=\"404.0\" y=\"28.0\" width=\"108.0\" height=\"24.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\"></rect><rect x=\"512.0\" y=\"28.0\" width=\"36.0\" height=\"24.0\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\"></rect><text x=\"558.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">29 different</text><text x=\"186.0\" y=\"85.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">August 2026</text><text x=\"186.0\" y=\"101.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1,897 identical</text><rect x=\"200.0\" y=\"80.0\" width=\"36.0\" height=\"24.0\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\"></rect><text x=\"246.0\" y=\"92.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">3 different</text><text x=\"186.0\" y=\"137.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">September 2026</text><text x=\"186.0\" y=\"153.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1,898 identical</text><rect x=\"200.0\" y=\"132.0\" width=\"24.0\" height=\"24.0\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\"></rect><text x=\"234.0\" y=\"144.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">2 different</text><rect x=\"40.0\" y=\"198.0\" width=\"14.0\" height=\"14.0\" rx=\"1\" fill=\"var(--wire)\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\"></rect><text x=\"62.0\" y=\"205.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">17 rounding: a decision, not a defect</text><rect x=\"380.0\" y=\"198.0\" width=\"14.0\" height=\"14.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\"></rect><text x=\"402.0\" y=\"205.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">9 a rule written nowhere</text><rect x=\"40.0\" y=\"222.0\" width=\"14.0\" height=\"14.0\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\"></rect><text x=\"62.0\" y=\"229.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3 a defect on the new side</text><rect x=\"380.0\" y=\"222.0\" width=\"14.0\" height=\"14.0\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\"></rect><text x=\"402.0\" y=\"229.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">an accepted change of rule</text></svg>", "caption": "Only the differences are drawn, because they are the point: each one was explained before the next month, and none was hidden behind a tolerance."}
```

The first month compared 1,900 farms. **1,871 were identical to the centavo and 29 differed**,
which is 1,871 ÷ 1,900, or 98.5% identical. Every one of the 29 was explained before the next
month's run:

- 17 were rounding. Coleta rounds the value of each collection to the centavo and adds the
  rounded values up; the shadow added the month first and rounded once. None of the 17 differed
  by more than six centavos.
- 9 were a rule that was written nowhere. A cooperative of nine farms north of Barbacena has had
  a winter bonus since 2009, agreed by a director who has since retired, and it exists only as an
  RPG subroutine. Sebastião remembered it when he saw the list of names.
- 3 were a defect on the new side. The anti-corruption layer did not recognise a collection the
  clerks had cancelled in Coleta, so the shadow paid for milk that had been poured away.

The defect was fixed and the bonus written down and implemented. The rounding was not a defect on
either side, and that is the instructive case. **A difference is not resolved by setting a
tolerance that hides it; it is resolved by somebody deciding which answer is right.** Marcos
decided: the replacement rounds per collection, like Coleta, because farmers compare their
statement with last month's and a change of method is announced to them, not slipped in. A
tolerance of ten centavos would have passed the 17 and hidden the fact that the two calculations
worked differently.

The second month had 3 differences, all one new case: a farm released from a quality suspension in
the middle of the month. Coleta paid the base price from the day after the release, the shadow from
the day itself. Here Marcos and Cláudia decided the old system had been wrong for years, and that
the rule will change, with notice to the farms, on the day the payment moves. The third month had
2 differences, both of that same accepted kind.

What the three months produced is worth more than the percentage. **The shadow calculation is now
the acceptance test for whatever replaces Coleta's payment**: whichever option lesson 15 chooses
has to match it, farm by farm, for three more months before phase 3 moves a single payment.

## Designed to be lived in

The middle lasts longer than planned because each phase finds something, and because the company
does not stop asking for changes while it lasts. The plan therefore treats coexistence as a
system with its own operations:

- the master table, published and dated;
- the copy paths, monitored, with alarms someone answers;
- the morning reconciliation, with a named owner;
- a runbook for "the copy to Coleta has stopped", tested before it is needed;
- a change process that knows, for every request from the business, which side it has to be made
  on this month.

None of that is waste. It is what the company is paying for when it chooses not to bet everything
on one weekend.
