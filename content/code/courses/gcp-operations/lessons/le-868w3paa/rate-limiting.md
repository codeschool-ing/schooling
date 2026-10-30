---
title: Rate limiting, and the ban that follows
version: 1
---

**A rate limit counts requests per key over an interval and acts on the ones above a threshold.** Rule 2000 of
the shop's policy counts requests to `/checkout` per client address (`enforce_on_key = "IP"`), and lets through
the first sixty in any minute. That is the throttle half. The other half is the **ban**: `rate_based_ban` with
`ban_duration_sec = 600` means a client that goes over the threshold is refused with `429` for ten minutes,
whatever it sends during them. A plain throttle (`action = "throttle"`) would refuse only the requests above the
rate and keep serving the rest. None of this was run; it is the same plan.

## Choosing the numbers

Sixty checkouts a minute from one address is far above anything a person does, and far below what a script
trying stolen card numbers does. That is the purpose of this rule: **card testing**, where a fraudster runs
thousands of small payments to find which stolen cards still work, and the shop pays a fee on every attempt. The
numbers come from the shop's own logs (the per-minute counts of lesson 10, grouped by client), not from a guess:
the highest legitimate rate in the last month, with room to spare.

## The key is the hard part

| `enforce_on_key` | counts per | the risk |
|---|---|---|
| `IP` | client address | a whole office or mobile carrier behind one address shares the limit |
| `HTTP_HEADER` | the value of a header you name, such as an API key | a client that leaves the header out is counted under one empty key |
| `HTTP_COOKIE` | a cookie's value | a cookie is set by the client and can be changed at will |
| `ALL` | everything together | one global limit, useful as a last fuse |

The shop counts by address because its customers are people at home, one address each. A shop selling to
companies would find a hundred employees behind one corporate address and ban all of them together; there the
key would be the customer's session or account.

## Seeing it work, without Google

A rate limit's effect is visible in the load balancer's request log, where a refused request carries the rule's
priority and the outcome. The lesson 10 technique applies: a log-based counter on
`jsonPayload.enforcedSecurityPolicy.outcome="DENY"`, split by priority, says how many requests each rule refused
per minute, and a sudden jump on rule 2000 is either an attack or a threshold set too low. Either way, somebody
should look, which is a ticket rather than a page (lesson 14).
