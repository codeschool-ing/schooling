---
title: Rate limiting, and what it can count by
version: 1
---

A rate-based rule counts requests and acts on whoever sends too many. The shop's `login-rate` reads:

- **count by** `IP`, the address the request came from;
- **over** a window of 300 seconds;
- **only** requests whose path starts with `/login`, the scope-down statement;
- **block** an address once it has sent more than 100 of them in the window.

A person logging in sends a handful of requests. A program trying a list of stolen passwords sends
thousands, and a limit of a hundred in five minutes stops it while leaving every person alone. The
limit is per address: a thousand different addresses each staying under it are a thousand addresses
WAF lets through, which is why this rule is one layer and not the defence.

## The window

`EvaluationWindowSec` may be 60, 120, 300 or 600 seconds, and the limit may be as low as 10. **The rule
blocks while the address is over the limit and lets it through again once its rate in the window falls
below**, on its own, with nobody unblocking anything. Counting is not instant: AWS documents a short
delay between an address crossing the limit and the block taking effect, so a few requests past the
hundredth get through. A rate limit is a brake, not a wall, and it is sized for a kind of traffic
rather than for an exact number.

The arithmetic is worth doing before choosing a number. An attacker at 3 requests a second crosses 100
in under 34 seconds. A shop whose own mobile app retries a failed login 5 times, behind a mobile
carrier that puts 40 customers behind one address, sends 200 in a bad five minutes from people who did
nothing wrong. **The second case is the one that hurts**, because it fails real customers in silence.

## Counting by something other than the address

`AggregateKeyType` can be `IP`, `FORWARDED_IP`, `CONSTANT` or `CUSTOM_KEYS`:

| key | counts | when |
|---|---|---|
| `IP` | per source address | the default, and right when the client connects directly |
| `FORWARDED_IP` | per address in a header such as `X-Forwarded-For` | behind a proxy or CDN that WAF does not sit on |
| `CONSTANT` | every request the scope-down matches, together | a ceiling on one endpoint, whoever calls it |
| `CUSTOM_KEYS` | per combination of up to five keys: a header, a cookie, a query argument, the path | per API key, or per session, rather than per address |

`FORWARDED_IP` trusts a header the client can write. It is right only when something in front, under
the team's control, sets it, and the web ACL is told which header and what to do with a missing or
malformed one. Counting by a header an attacker controls lets the attacker choose a new count for every
request.

## Where a rate limit belongs

Keep rate-based rules **after** the IP set and before the managed group, as the shop's are. The IP set is
certain and decides first. A request from an address already over its limit is then refused before the
managed rules look at it, so its log record names the rate rule as the reason, which is the record the
team will want to read. A rate rule for the whole site, with no
scope-down and a generous limit of a few thousand, is a common second one: it costs one rule and
catches a single address hammering everything.
