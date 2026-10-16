---
title: Deciding on purpose, and writing it down
version: 1
---

Lock-in that hurts is almost never the lock-in somebody chose. It is the one nobody noticed: the
Lambda event read in forty files because it was convenient, the three-year commitment signed for a
service that was rewritten in its second year. **The difference between a decision and an accident
is a record**, made when the choice is made, that says what was accepted and what would undo it.

## An architecture decision record

The usual form is an *architecture decision record*, a short file kept in the repository beside the
code it decides, numbered, and never edited after it is accepted: a decision that changes gets a
new record that supersedes the old one. Most teams write them in Markdown. This one is YAML, so
its fields can be read by a script as well as by a person, and it records the shop's choice from
lesson 23:

```schooling-example
{"language": "yaml", "file": "decisions/0004-order-api-on-fargate.yaml", "parts": [{"code": "id: 4\ntitle: The order API runs on Fargate, in sa-east-1\nstatus: accepted\ndate: 2026-10-16\ndeciders: [ana, the three developers of the shop]\n", "note": "The record's identity. A number, a title that states the decision rather than the topic, the date and who decided. **Status** is what makes it a record rather than a wish: `proposed`, `accepted`, and one day `superseded by 9`."}, {"code": "context: >\n  The order API leaves a single EC2 instance. Its busiest week peaks at\n  80 requests a second and averages 26.5 (lesson 23's profile). The team\n  knows containers and has never run a function in production.\n", "note": "Why a decision was needed at all, in the numbers that made it: the profile and the team. Somebody reading this in two years needs to know what was true then, because it will not be true then."}, {"code": "decision: >\n  Two Fargate tasks of 0.5 vCPU and 1 GB behind a load balancer, built\n  from the image the team already has. The nightly report runs as a\n  scheduled task from the same image. Reports move to S3.\n", "note": "What was decided, in a paragraph. Not the comparison, which lives in lesson 23's program, but its outcome."}, {"code": "lock-in accepted:\n  - kind: API\n    what: the ECS task definition, the load balancer and IAM roles for tasks\n    exit cost: rewrite the deployment, not the code; the image is OCI\n  - kind: data\n    what: reports and photos in S3, about 2 TB\n    exit cost: 511.75 USD at the list price, or AWS's waiver if granted\n  - kind: skills\n    what: ECS, CloudWatch and IAM, learnt by three people\n    exit cost: three people for three days on the next platform\n  - kind: contract\n    what: none; no Savings Plan before six months of steady traffic\n", "note": "**The line most decisions leave out.** Each kind of lock-in from section 02, what exactly was accepted, and what leaving would cost, from section 04's estimate. A lock-in written here is a choice; one discovered later is an accident."}, {"code": "lock-in refused:\n  - shop rules that import boto3 or read a Lambda event\n  - S3 calls outside the one module that saves reports\n", "note": "What the team decided not to accept, which is where the seams of section 03 are written down so that a reviewer can point at a pull request that crosses one."}, {"code": "exit triggers:\n  - average traffic below 21.8 requests a second for a quarter\n  - traffic above 400 requests a second for a month\n  - a price change that moves lesson 23's comparison by more than 20%\nreview: 2027-04-16\n", "note": "The conditions that reopen the decision, each one something a dashboard can show, and a date on which somebody reads the record again even if none of them has fired."}]}
```

**This file was not run**; it is a document. Its numbers are the ones lessons 23 and 24 computed,
which is the point: every claim in it can be traced to an arithmetic somebody can repeat.

## What makes one useful two years later

A record nobody reads is a diary. Four habits keep this one alive:

- **it lives with the code**, in `decisions/`, so a pull request that crosses a refused seam can
  link to the line it crosses;
- **its exit triggers are measurable**. "If it gets expensive" is not a trigger; "average traffic
  below 21.8 requests a second for a quarter" is, and a CloudWatch alarm from `aws-operations`
  lesson 10 can watch it;
- **it has a review date**, because a trigger nobody watches does not fire. Six months is a
  reasonable default for a service that is still finding its traffic;
- **it is superseded, not rewritten.** When the shop moves the report to Lambda one day, record 9
  says so and points at record 4. The history of why is worth more than a tidy current state.

## When one is worth writing

Not every choice needs a record. **Write one when the decision would be expensive to reverse**,
which is exactly when it carries lock-in: a compute platform, a database, a commitment of a year or
more, a seam the team agrees not to cross. A choice of library inside one adapter does not need
one, because the adapter can be replaced in an afternoon. A useful test is the question a new
colleague asks in their first month: why is it like this? If the answer lives only in somebody's
head, it leaves when they do, and the next person decides again, with less information, what was
already decided once.

## Lock-in accepted on purpose

Read the record's lock-in lines again and notice what they do not say. They do not say the shop
avoided lock-in: it accepted four kinds, with a price beside each. **Accepting lock-in is the normal
result of using a cloud well**, because every managed service is bought partly with the cost of
leaving it. What the record adds is that the price was looked at, compared with what it bought, and
written where the next person will find it.

That is also the answer to the question in this course's title: which compute? Not
one service for everything, and not the cheapest line of a sheet, but the one whose request
profile, running cost, migration effort and lock-in a team can state in a file like this one, and
still defend when the file is two years old.
