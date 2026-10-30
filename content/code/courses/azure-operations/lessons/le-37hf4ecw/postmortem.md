---
title: The blameless postmortem
version: 1
---

**A postmortem is written to make the next incident less likely, and blaming a person does the
opposite.** The activity log says Bruno scaled the database down. A postmortem that stops there, *Bruno
made a mistake*, produces one action, *Bruno should be more careful*, which fixes nothing and teaches
everybody else to hide their next change. The questions that produce actions are about the system: **why
was it possible, why was it reasonable, and why did it take 23 minutes after the page to find?**

Bruno was cutting cost, which lesson 23 asks people to do, on a database that had looked oversized all
month. He was refused once at 13:58 by a missing role and then had it granted, which made the change look
sanctioned. Nothing tied the database's size to Thursday afternoon's load. Every one of those is a
condition anybody else could have met, and each becomes an action.

The shop's postmortem is one page:

```
Checkout failures, 15 October 2026                               SEV2, blameless

Summary      42 minutes in which about two in three checkouts failed.
Impact       103 failed checkouts; 87% of the week's error budget.
Detection    burn-rate page at 14:15, 10 minutes after the first failure.
Trigger      sql-shop/shop scaled from S3 to S1 at 14:02, by hand, to cut cost.
Resolution   scaled back to S3 at 14:44.

Contributing factors
  - a production database could be resized from the portal with no review
  - nothing tied a database's size to the load it was carrying
  - the runbook did not start with "what changed?"

Actions                                                      owner     due
  - database size in Bicep; changes through the pipeline     platform  22 Oct
  - DTU-percentage alert on sql-shop, severity 2             carla     20 Oct
  - runbook step 1: the activity-log timeline query          carla     16 Oct
  - rightsizing reviewed in lesson 23's way, not by hand     bruno     30 Oct
```

Four rules make it work:

- **it names the trigger and not a culprit**: the change, its time and its purpose, in the passive if
  need be;
- **contributing factors are plural**: there is rarely one root cause, and a template with one box for it
  produces one answer;
- **every action has an owner and a date**, or it is a wish;
- **it is read**, at a short meeting, by the people who were involved and the people who own the actions.

The timings in it come from this lesson's queries, which is the other reason the timeline is built from
records: a postmortem whose numbers came from memory starts an argument about the numbers.
