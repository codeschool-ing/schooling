---
title: What you built, in their words
version: 1
---

Every part of `sync.sh` has a name in the products. The words differ between vendors, and some differ
between destinations of the same vendor, so the table gives the documented term where there is one:

| in lesson 7 | Hightouch | Census (Fivetran Activations) | Segment Reverse ETL |
|---|---|---|---|
| `activation.crm_contacts` | a model | a model | a model |
| the CRM | a destination | a destination | a destination |
| `external_id`, matched by `PUT` | a record matching field | the identifier you match on | the destination's identifier, in the mapping |
| what the sync does with a row | a sync mode: upsert, update, insert | a sync behaviour: Update or Create, Update Only, Create Only, Mirror | records to send: added, updated, added or updated, deleted |
| a contact that left the model | delete behaviour: Do nothing, Clear fields, Delete destination record | Mirror deletes it | the *deleted* records option |
| `last_sent` and the diff | kept by the product; with its Lightning engine, in a schema of your warehouse | kept by the product: syncs are incremental | a Unique Identifier column, used to detect new, updated and deleted rows |
| `sync_log` | each run's page, with its added, changed and removed rows | the sync history | each sync's page: extracted, added, updated, deleted |

Three things in that table are worth reading twice.

- **The diff is the product's, not yours.** `last_sent` was a table you could query; in a product it is
  state the product keeps. Hightouch's Lightning engine keeps it in your warehouse, in a schema called
  `hightouch_planner` that it needs write access to, and its documentation warns that deleting those
  tables forces a full resync. Each one offers a way to throw it away — Segment calls it a reset, Hightouch a
  full resync — which makes the next run send everything, exactly like running `activation.sql` again.
- **Segment's Unique Identifier is the diff's key, not the match key.** It tells Segment which row of the
  model is which between runs. Which record in the destination a row lands on is a separate choice, in
  the mapping. Lesson 7 used one id for both, which is the arrangement to aim for.
- **Upsert is a mode you choose.** An *insert* or *Create Only* sync is lesson 7's `POST`: correct for a
  destination that only takes new records, such as a list of events, and three records for `lantern-10`
  anywhere else.

The schedule is the last piece. `sync.sh` ran when you typed it. Hightouch's documentation lists five
kinds of schedule: manual, an interval, a cron expression, and after a dbt Cloud or a Fivetran job has
finished. The last two are the ones to prefer when the model is built by such a job, for lesson 6's
reason: a sync that runs before its model is fresh sends yesterday's numbers on time.
