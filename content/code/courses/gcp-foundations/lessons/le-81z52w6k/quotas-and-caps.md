---
title: Quotas, and the caps Google does not have
version: 1
---

**Google Cloud has no setting that says "stop spending at 300 dollars".** People look for it on the first
day and it is not there, because a hard cap would have to decide, on the customer's behalf, which of their
running systems to switch off and which data to delete. Google leaves that decision to the customer, and
offers three tools that each limit spending in one way. None of this section ran: quotas are Google's
counters and the lab has none.

| tool | what it limits | what it costs when it bites |
|---|---|---|
| **a budget with an automated unlink**, previous section | everything in the projects it covers | everything stops, and stored data may be deleted |
| **a lowered quota** | one API's requests, or one kind of resource | requests to that API are refused; nothing else changes |
| **a separate project with a small budget** | an experiment, kept away from production | only the experiment |

## A quota as a cap

Lesson 3 said a quota is a ceiling Google sets and one the customer can **lower**. That makes a quota the
precise cap: an API that charges per request, such as a translation or a maps API, can have its rate quota
set to what the application needs, and a bug that loops on it is refused at the quota instead of billed at
the price. **This is the cap to reach for first**, because it fails the one thing that went wrong and
leaves the rest of the system alone.

Quotas also cap what can **exist**. A project whose quota for virtual CPUs in `southamerica-east1` is 24
cannot run a hundred machines by mistake, whatever the Terraform says. New projects start with small
quotas for exactly this reason, and a request to raise one is a moment somebody is asked to think.

## What a budget does not see

Two gaps make budgets an imperfect alarm, and both are worth knowing before an incident teaches them:

- **The delay.** Costs reach the billing data hours after the usage, so a budget measures where the money
  was, not where it is. A runaway system can spend for most of a day before its budget crosses a threshold.
- **The scope.** A budget sees the costs its filter names. A project created next week and linked to the
  same billing account is outside a budget that lists projects by name, unless the budget is on the whole
  account or the new project is added. A budget on the billing account with no project filter, at a higher
  amount, is the backstop that catches what the narrower budgets miss.

## The order that works

For the planner, the arrangement is the one most teams arrive at: **quotas lowered on the APIs that charge
per call**, a **budget per environment** with forecasted and actual thresholds that reach a person, a
**budget on the whole billing account** as a backstop, and an **automated unlink only on the sandbox
projects**, where losing everything is an acceptable price for never being surprised.
