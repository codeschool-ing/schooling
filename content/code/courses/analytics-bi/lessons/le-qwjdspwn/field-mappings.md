---
title: Field mappings, and the picklist again
version: 1
---

In `sync.sh` the payload was the model's row, turned into JSON by `row_to_json`: every column went, under
its own name. A product puts a screen between the two, the **field mapping**: on the left the model's
columns, on the right the destination's fields, and a line from each column to the field it fills.

That screen does three jobs that lesson 7 did by accident or not at all:

- **It chooses what is sent.** A column that is not mapped is not sent, so the model can carry a column
  for its own checks — a count, a date it was computed — without it reaching the CRM. Lesson 7 sent
  every column, which was fine only because the model had six.
- **It renames.** The CRM's field might be called `Lifetime_Value__c` and the model's `net_revenue`. The
  mapping joins them, and the model keeps the name that means something in the warehouse.
- **It knows the destination's types.** The product asks the destination's API what its fields are, so a
  mapping from a text column to a number field, or to a picklist, can be flagged before anything is sent.

The third job is the one that would have caught lesson 7's failure early. The new health value *new*
was refused 284 times because the CRM's picklist did not have it. A product reading the picklist can
show the mismatch in the mapping screen, but only if somebody opens it: a view changed in the warehouse
does not open anybody's mapping screen. **The refusal still arrives as a failed row in a run**, and the
habit that finds it is the same as with `sync.sh` — somebody reads the run's failures, or an alert does.

Hightouch's alerts, for example, distinguish a **fatal error**, where the run failed, from **row errors**,
where the run worked and some rows did not, and can send either to e-mail, Slack, SMS or PagerDuty. Set
one for each sync on the day it is created. A sync with no alert is lesson 7's sync with no last line.
