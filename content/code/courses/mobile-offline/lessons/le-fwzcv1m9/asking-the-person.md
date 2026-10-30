---
title: Asking the person, and keeping both until they answer
version: 1
---

**When the same field changed on both sides, the app shows the person both values and lets them
choose, and until they do, neither value is thrown away.** That sentence has two halves and the
second matters more. A conflict screen that appears once and forgets both versions when it is
dismissed is last write wins with a dialog in front of it.

## When to ask

Ask only when a merge cannot decide, and only when the field is worth a person's attention.

| situation | what the app does |
|---|---|
| different fields changed | merges, says nothing |
| the same field changed to the same value | merges, says nothing |
| the same field changed, and the field is a setting | keeps the server's value, says nothing; lesson 13's rule is right there |
| the same field changed, and it is something the person made | keeps both, and asks |

Asking too often has a cost that does not show in a test. A person shown a conflict screen every
other day learns to tap whichever button ends it fastest, and from then on the screen is a
slower version of last write wins.

## What the screen shows

The person needs enough to recognise their own work. For the planner's case from the previous
section:

- **what is in conflict, in their words**: "Guitar, Wednesday 21 October: how long?";
- **each value with where and when it was made**: "30 minutes, on your phone, 10:05" and "25
  minutes, on your tablet, 10:20" — the times the edits were made, recorded by each device, which
  is the one honest use of a device clock in this whole subject;
- **a choice that includes neither**: picking 30, picking 25, or typing a third value.

Whatever they choose is an ordinary edit of the newest version: the device sends it with the
server's current version number, exactly like any other write.

## Where the second version waits

The losing value lives on the device that holds it, in a table of its own, until it is resolved:
one row per conflict, with the record's id, the field, both values, both times and the server
version they were compared against. It survives the app being closed, and the sync carries on for
every other row meanwhile. **A conflict must never block the outbox of lesson 8**: one session in
dispute is no reason for the next twenty to wait.

No platform draws this screen for you. Apple's `NSFileVersion` reports conflicting versions of a
document stored in iCloud Drive, and leaves the deciding to the app; Android and React Native offer
nothing of the kind, so the table and the screen are yours on all three.

Lesson 15 takes the other road: data types designed so that concurrent edits always merge, and the
question never needs asking.
