---
title: A landing zone, and what Control Tower builds
version: 1
---

**A landing zone is the whole multi-account arrangement as it has to be before the first workload
arrives.** It is the tree of lessons 3 and 4, plus the logging, the guardrails and the way in for people,
set up so that every account added later starts out the same way. The wrong picture is a product,
or a single account configured with care. A landing zone is neither. It is a baseline that holds
for every account, today's and next year's, and **the hard part is the next account**, not the
first.

Lesson 2 listed what every account needs, and said that six accounts set up by hand become six
different accounts. A landing zone is the answer to that, and AWS sells one as a service.

## Control Tower

**AWS Control Tower builds a landing zone and keeps it in shape.** It is set up once, from the
management account, in a **home region** the company chooses. It governs the regions the
company lists, and the shop would choose `sa-east-1` for both. Control Tower itself costs nothing;
the services it switches on are charged as usual, which the next section prices.

**None of this was run for the course.** moto has no Control Tower, as the last section of this
lesson shows, so what follows is AWS's documented behaviour.

## What it sets up

| Control Tower creates | what it is for | the shop's name for it |
|---|---|---|
| an OU for security, named `Security` by default | the accounts that watch the others | `Security` |
| a **Log Archive** account in it | one bucket that receives every account's CloudTrail and Config records | `log-archive` |
| an **Audit** account in it | read access to every account for the security team, and where alerts arrive | `security` |
| optionally a second OU, `Sandbox` by default | a first home for new accounts | `Sandbox` |
| an organisation trail in CloudTrail | every API call of every account, delivered to Log Archive | |
| AWS Config in every governed account and region | a record of what each account contains, and how it changed | |
| IAM Identity Center, unless the company opts out | one sign-in for people across the accounts; lesson 11 | |
| the mandatory controls | guardrails that protect the landing zone itself; the next section | |

The names in the third column are lessons 2 and 3's. **Control Tower's Audit account is the shop's
`security`**: the place the security team works from, with read access everywhere and write access
nowhere it does not need. The shop's own `Workloads` OU is not part of the setup. A company creates
its own OUs in Control Tower afterwards and registers them, and from then on Control Tower governs
them.

## Account Factory

**A new account is made through Control Tower, not through Organizations.** Account Factory is the
part of Control Tower that creates an account inside a registered OU. It applies the landing zone to
the account before anybody uses it: the trail reaches it, Config starts recording, the OU's controls apply,
and the right people can sign in. That is the property lesson 2 asked for: a new account that starts
out right. A form or an API call delivers it, rather than somebody remembering a list of steps.

An account created earlier, or invited from outside as in lesson 3, is **enrolled** instead, and
receives the same baseline.

## Drift

**Drift is the landing zone changed behind Control Tower's back.** Control Tower knows what it set
up, and checks it. It catches an account moved between OUs directly in Organizations, an SCP it
manages edited or detached by hand, and an OU it governs deleted. It reports each of those as drift,
and each is repaired from Control Tower, by re-registering an OU or by repairing the landing zone.

The rule that follows is the one that makes a managed landing zone work: **once Control Tower runs
the tree, the tree is changed through Control Tower.** Lessons 3 and 4 drove Organizations directly.
That is right for understanding it and wrong for an organisation under Control Tower, where the same
`move-account` produces drift.
