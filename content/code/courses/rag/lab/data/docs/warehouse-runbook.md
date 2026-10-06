---
id: warehouse-runbook
title: Warehouse on-call runbook
audience: staff
owner: operations
updated: 2026-02-20
version: 8
status: current
---

# Warehouse on-call runbook

For whoever is on call for the warehouse and for dispatch. It says how to rate an incident, who to
call and what to do for the incidents we have had before.

## Severity

| severity | meaning | first response |
| --- | --- | --- |
| SEV-1 | no orders can be dispatched | within 15 minutes, any time |
| SEV-2 | dispatch is slowed or one carrier is down | within 1 hour in working hours |
| SEV-3 | a problem with a workaround | next working day |

When in doubt, rate it higher. Downgrading an incident costs nothing; discovering at 6 pm that a
SEV-3 was a SEV-1 costs a day of orders.

## Who to call

Post every incident in the operations channel first. For SEV-1, also phone the operations manager
on call; the number is on the rota pinned in the channel. The carrier account managers' numbers are
on the same rota.

## A carrier is down

1. Check the carrier's status page and confirm with their account manager.
2. Switch new standard orders to the second carrier in the dispatch settings. Express orders cannot
   be switched, because only the first carrier delivers next day.
3. Ask support to add the banner Delays with deliveries to the help centre.
4. When the carrier is back, switch the setting back and remove the banner.

## The label printer has stopped

Restart the print server from the dispatch console before touching the printer. If labels still do
not print after ten minutes, print them from the backup laptop at packing station 3, which has its
own printer. Rate it SEV-2 if it lasts more than an hour.

## Stock does not match

When a picker finds fewer copies than the system shows, mark the shelf location for a count and
pick the order from the overflow area if the title is there. If not, the order goes to Awaiting
stock and support is told automatically. Never edit the stock level by hand during a shift; the
count at the end of the day corrects it.

## After an incident

Every SEV-1 and SEV-2 gets a short review within five working days: what happened, when it was
noticed, what was done and what will change. The review blames no person.
