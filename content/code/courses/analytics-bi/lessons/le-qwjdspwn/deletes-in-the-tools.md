---
title: Deletes, and what a resync forgets
version: 1
---

Lesson 7 deleted a contact when it left the model and said the right answer depends on why it left. The
products make that a setting, and Hightouch's is the most detailed, so it is the example here. Its
**delete behaviour** is chosen per sync, separately from the sync mode, and has three values where the
destination supports them:

| delete behaviour | what happens to a record whose row left the model | lesson 7's case |
|---|---|---|
| Do nothing | it stays as it was, with the old values | — |
| Clear fields | the synced fields are emptied; the record stays | a filter changed |
| Delete destination record | the record is deleted | an erasure |

Census's Mirror behaviour and Segment's *deleted records* option do the same as the last row. Which ones a
given destination offers is on that destination's page in each product's documentation, and it varies:
not every API allows a delete.

Two properties of how they detect a removed row matter more than the setting.

**A removed row is a row that was in the previous run and is not in this one.** That is lesson 7's second
loop exactly: `last_sent` against the model. It follows that a row which left the model before the sync
existed is never seen leaving, and Hightouch's documentation says so plainly: rows removed before the
sync began cannot be cleaned up.

**A full resync forgets the previous run.** Hightouch's documentation is explicit that a full resync does
no diffing, so the clear and delete settings are ignored and removed rows are not acted on. A customer
erased the day somebody pressed *resync* is never deleted from the CRM.

Put together: **the sync's delete is not the company's erasure process.** It is one part of it. An
erasure request needs its own record of which systems hold the person, and a check that each one no
longer does — the CRM included, whatever the sync did or did not do that night.
