---
title: Why there is never just one
version: 1
---

**A company on AWS runs several accounts, and the reason is the walls.** The picture people arrive
with is one account, divided by tags and by careful IAM policies: production resources tagged
`env=prod`, a policy that keeps developers off them, one bill read by tag. It works on the first day.
It fails in three ways that each look like somebody's mistake, and each of them is the same mistake:
**two things that should not share a wall were put inside one**.

## Three ways one account goes wrong

**A developer's experiment sits beside production.** To try something, `bia` needs to create and
delete machines. In a shared account, the permission to delete her own machines has to be written
so that it does not reach production's, usually as a condition on a tag. One resource created
without the tag, or one policy that forgot the condition, and the experiment can delete what
customers use. Lesson 8 shows how such a condition is evaluated. Here, **the
safety depends on every policy and every tag being right, every time**. In a separate account the
same mistake deletes the sandbox.

**A test spends production's quota.** The quota from the first section, five VPCs per region, is
counted for the whole account. Suppose the build makes a VPC for each pull request it tests, and
three are open. With the default VPC and production's own, that is five, and the next deployment
that needs a network is refused. Nothing was wrong with the deployment and nothing was wrong with
the tests. They were counted against one number that production needed too. In separate accounts
each has its own five.

**The bill cannot be split.** Tags divide the lines that carry them, and lesson 13 makes the shop tag
everything it can. But not everything on a bill is a tagged resource. A machine somebody forgot to
tag lands under no team. Some charges, such as the support plan, belong to the account rather
than to any resource in it. When the whole shop is one account, those lines belong to nobody, and
"what does staging cost" has no exact answer. **When staging is its own account, the answer is its line
on the bill**, and lesson 3 shows how one bill still carries every account.

## The split the shop uses

The shape below is the one AWS's own guidance and most companies arrive at, and it is the one this
course builds in lessons 3 to 5:

| account | what lives there | who goes in |
|---|---|---|
| management | the organisation and the bill, and nothing else | almost nobody, almost never |
| `shop-prod` | the shop customers use | the deployment pipeline; people only to read, or in an emergency |
| `shop-staging` | a copy of the shop, to test releases on | the pipeline and the developers |
| `sandbox` | experiments, cleared out regularly | any developer, with a small budget |
| `security` | the tools that watch every other account | the security team, read-only elsewhere |
| `log-archive` | a copy of every account's logs, which nobody can delete | almost nobody; the logs arrive on their own |

**Production and staging are separate so that a test cannot touch customers**, and so that a
release is tried somewhere with the same shape before it reaches them. Many companies also keep a
development account per team; the shop is small and lets `sandbox` do that job.

**`security` and `log-archive` are separate from everything they watch.** The question they answer
is what happened, and the answer has to survive somebody who controls a workload account and wants
it to be different. If the logs of `shop-prod` live in `shop-prod`, whoever takes over that account
can delete the evidence of having done it. In an account of their own, with a guardrail that forbids
deleting them, they cannot. Lesson 4 writes that guardrail and lesson 5 builds the two accounts.

**The management account holds no workload**, for a reason lesson 4 makes precise: it is the one
account the organisation's guardrails cannot restrict. Anything running there runs outside every
rule the organisation sets.

## What it costs to have six

An account costs nothing to create or keep. **What it costs is the baseline**: every account needs
the same logging, the same guardrails, the same way for people to get in, and the same budget alert.
Six accounts set up by hand become six slightly different accounts within a month, and the
difference is found on the day it matters. The next three lessons solve that problem, in
order. Lesson 3 puts the accounts in one tree with one bill, and lesson 4 sets rules that every
account in a branch inherits. Lesson 5 builds the whole arrangement so that a new account **starts out
right** rather than being repaired afterwards.

Getting in is the other cost. A person with work in three accounts needs a way into each that is not
three passwords. Lesson 11 gives the shop one sign-in for all of them. A service in one account
that reads from another needs a role it may take on, which lesson 9 builds. Both are a door made on
purpose, which is exactly what the walls were for.
