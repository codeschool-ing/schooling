---
title: Shared fate, and defaults that move the line in practice
version: 1
---

**The contract still splits the work in two. What has changed in the last few years is how much the
providers help with your half, mostly by deciding things for you unless you decide otherwise.**
Google Cloud gave the idea a name, **shared fate**: the provider's outcome depends on its customers'
configurations, so it ships safer defaults, tested blueprints and guardrails instead of only a list
of what is yours.

The wrong reading of it is that the line has moved up, and some of your rows are the provider's now.
It has not, in any contract. A default is still a setting in your account; you can change it, and if
you do, the consequences are yours exactly as before.

## Three ways a provider helps with your half

| | what it is | an example |
|---|---|---|
| a **safer default** | the setting a new resource starts with | AWS switching Block Public Access on for every new bucket in 2023, section 03 of this lesson |
| a **guardrail** | a rule set once, above the accounts, that a later setting cannot break | an organisation policy denying any region outside Brazil, lesson 17 |
| a **blueprint** | a whole tested arrangement of accounts, networks and logging to start from | AWS Control Tower's landing zone, Azure's landing zones, Google Cloud's enterprise foundations blueprint |

Each one moves the line **in practice**: the row is still yours, and the provider has done the first
version of the work in it. That is a real gain for the buckets, keys and networks nobody on your team
would have thought about. It is no gain at all for the ones somebody has already changed.

## What it asks of you

Three habits, and each lesson after this one practises at least one:

- **Keep the defaults**, and treat switching one off as a decision that needs a written reason. Every
  public bucket in lesson 9 began as somebody turning a guardrail off to make something work.
- **Know which resources predate a default.** A default applies from the day it shipped. The clinic's
  account is older than 2023, and its oldest buckets are exactly the ones the change did not reach.
- **Read the default back, never assume it.** It is a setting like any other, so the evidence for it
  is the same: a request, and the answer it got. Section 03 of this lesson did it for one bucket, and
  lesson 16 does it for all of them.

So the model you work with for the rest of the course has three parts. **The line says whose work a
row is. The defaults say how much of that work has been started for you. Your own evidence says what
is true today.** Only the third one is ever specific to your account.
