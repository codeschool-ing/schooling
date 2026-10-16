---
title: The policy, written before it is needed
version: 1
---

A budget nobody acts on is a chart. What turns it into a decision is a **budget policy**: a short document, written while the budget is healthy, that says what the team does when it is not. It has to be written in advance for the same reason a fire drill is held on a quiet day: on the evening the budget runs out, everybody in the room has a reason to want an exception.

## The Billing team's policy

Bia wrote it with the head of product in July, and both signed it, with the engineering director above them:

| budget left, rolling 30 days | what happens |
|---|---|
| more than 50% | releases as usual |
| 0% to 50% | every release to card charges goes to 5% of shops first and waits an hour |
| spent | **no feature releases to card charges** until the budget is positive again; fixes, security changes and the action items of the incident that spent it go first |
| spent twice in a quarter | reliability is the first item of the next quarter's plan, with people named against it |

Three things in that table matter more than the thresholds.

- **It names who decides.** The policy says what happens automatically. An exception, a feature that cannot wait, needs the head of product to ask for it in writing, and the request is recorded beside the release. That makes exceptions possible and visible, which is the point: a policy with no exceptions is broken at the first real emergency, and one with silent exceptions is not a policy.
- **It stops feature work, not work.** A freeze on features does not send anybody home. It moves the team's time to the things that spent the budget, and that is where the budget comes back from.
- **It is about the service, not the people.** Nobody is blamed for a spent budget, and the policy does not ask who spent it. The provider's slow hour on 16 September counts exactly as much as the team's own release; the budget measures what the shops lived through, and lesson 15's postmortem asks why.

## What it means in October

The rolling window keeps September in view for 30 more days. **The incident on 30 September spent more than a whole month's budget on its own**, so with October's charges at September's volume, the budget stays below zero until that day leaves the window, at the end of October. Under the team's policy, that is a month with no feature releases to card charges.

That is the policy working, not misfiring. October's work is already chosen by it: the idempotency key on every card retry, the alert on duplicate charges, the release to 5% of shops and the overdue action items from lesson 15. Lesson 15 found three overdue items that would have made September's afternoon smaller; the policy is what finally puts them ahead of the features they kept losing to.

## When the policy is ignored

The first time the budget runs out is the test of whether the team has one. If an urgent feature goes out anyway, without the written exception, the policy is gone, and with it the one argument that let the team say no without a fight. Teams that want a budget policy to survive keep it short, keep its thresholds few, and **keep the exception path cheap**, so that nobody has a reason to go around it.
