---
title: Fetch policies
version: 1
---

**A fetch policy tells the client, per query, whether to answer from the cache, from the server, or from
both.** Step 2 asked exactly what step 1 had asked, and the server's log shows it never arrived: the
default policy, `cache-first`, found every field it needed in the cache and answered from there.

| policy | reads the cache | asks the server | for |
|---|---|---|---|
| `cache-first` | yes, and stops if everything is there | only for what is missing | the default; data that changes rarely |
| `cache-and-network` | yes, at once | always, then updates | a screen that should show something now and the truth a moment later |
| `network-only` | no | always, and writes the answer into the cache | data that must be current, such as after a change made elsewhere |
| `no-cache` | no | always, and keeps nothing | an answer that must not be stored at all |
| `cache-only` | yes | never | data you know is there, or an offline screen |

Step 5 used `network-only`, which is why it reached the server where step 2 did not.

## Which one the planner wants

The planner's data changes in two ways: by the planner itself, through a mutation whose answer goes into
the cache, and by somebody else, on another device. `cache-first` handles the first. For the second there
is no setting that is right without knowing the product: a planner used on a phone and a laptop by the
same person might use `cache-and-network` when a page opens, so it draws at once from memory and
corrects itself a moment later. The planner in this lesson keeps the default.

## Stale is a decision

A cache answers quickly because it does not ask, which means it can be wrong. Every policy except
`network-only` and `no-cache` accepts that a screen may show something the server has since changed. That
is the trade every cache makes, a browser's and a CDN's included, and it deserves the same question: **how
old may this be before it misleads somebody?** A session's minutes can be an hour old. A bank balance cannot.
