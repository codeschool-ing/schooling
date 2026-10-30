---
title: Guardrails, before the query that costs a fortune
version: 1
---

**Neither pricing model stops a bad query by itself.** On demand bills whatever a query reads, and a
query written against the wrong table, or without its filter, reads all of it. An autoscaled
reservation grows to its maximum to run whatever it is given. The guardrails are settings somebody
has to make before the query arrives, and this section is the three of them that matter for compute.
None of them can be set in this lab, and every command here is shown as you would type it and was
not run.

## Custom quotas, for on demand

**A custom quota caps the bytes a project, or each user in it, may have billed in a day.** Google's
documentation, "Create custom cost controls", describes two: **query usage per day**, for the whole
project, and **query usage per day per user**. They are set on the project's quotas page in the
console, or with the Service Usage API, in TiB. When a query would take the day's total over the
quota, BigQuery refuses it with an error instead of running it, and the quota resets at midnight
Pacific time.

The pricing page names them first among its cost controls: "User-level and project-level custom
cost controls" and "The maximum bytes billed by a query". **The quota is the one that protects the
month.** A per-user quota of 1 TiB a day, in São Paulo, caps what one person can spend on demand at
11.25 USD a day, whatever they type, and a project quota caps the total. The arithmetic of the
dashboard in the on-demand section, 16,200 USD for a month of hourly 2 TiB scans, needs 48 TiB a day;
a project quota of 5 TiB would have stopped it on its first afternoon.

**Its weakness is that it stops the right queries too.** A quota does not know which query matters.
When the day's TiB are gone, the analysts' last query fails exactly as the runaway one would have,
and a quota set too low becomes the outage it was meant to prevent. So it is set from what the project
actually reads in a heavy day, from `INFORMATION_SCHEMA.JOBS`, with room above it.

## Maximum bytes billed, for one query

**`maximumBytesBilled` is a limit set on a single query**: if the query would bill more, it fails
before it reads anything and costs nothing. It is the guardrail a program puts on every query it
sends, and the `bq` command line spells it as a flag. Lesson 16 teaches it beside the dry run, which
is how a query finds out what it would cost before anybody decides whether to run it.

## The maximum of a reservation

**On slots, the guardrail is `--autoscale_max_slots`.** A reservation can never scale above its
maximum, so the most an autoscaled reservation can cost in an hour is that many slot-hours. For the
reservation of the editions section, 200 slots of Enterprise:

```sh
bq update --reservation --location=southamerica-east1 \
  --autoscale_max_slots=200 quitanda-etl
```

200 × 0.093 is 18.60 USD an hour, and 200 × 0.093 × 730 is 13,578 USD for a month in which it never
stops. **The maximum caps speed as well as cost**: a query that needed 400 slots runs on 200 and takes
longer, rather than failing. That is the difference from a quota. A reservation at its maximum makes
queries slower; a project at its quota makes them fail.

## Budgets, which only warn

**A Cloud Billing budget sends an alert; it does not stop anything.** It watches the bill of a project
or a billing account and e-mails when the spending passes a share of the amount set. It is worth
having, and it arrives after the money is spent, which is why it is the last line here rather than
the first. For BigQuery, the quota and the maximum are the settings that act before the bill does.
