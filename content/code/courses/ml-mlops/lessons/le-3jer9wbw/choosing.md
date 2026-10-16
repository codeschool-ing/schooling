---
title: Choosing, and what each choice costs to keep running
version: 1
---

The three deployments differ most in what they cost once they are running, and the cost is not
mainly money.

| | batch | real time | edge |
| --- | --- | --- | --- |
| runs | minutes a night | every minute of every day | on devices you do not control |
| must be up | for the length of the job | always, or the page that calls it fails | no |
| features from | the offline store | the online store, in milliseconds | the device, with code of its own |
| when it fails | a stale table, and tomorrow's run | errors in front of customers | wrong answers nobody sees |
| changing the version | the next run | a restart | an app update, eventually |
| the evidence kept | every score, in a table | every request, if it is logged | what devices send back |

**Start with batch and move only when a decision needs fresher answers than a night.** The lapse
model's decision, a monthly voucher list, needs nothing else. The member page that wants a live
score is better served by reading last night's row from `lapse_scores` than by a service. It is one
indexed lookup and it shows the same number marketing used. And the score cannot be fresher than the
features behind it anyway, which change when the member buys a book, not when they open a page.

**A service is worth it when the answer depends on the request itself**: the basket now, the
payment now, the search typed now. Then the online store, the always-on process and the monitoring
of lesson 9 all pay for themselves.

That last point is where most teams go wrong in one direction. A real-time service built for a
model whose inputs change nightly is a service that gives the same answer as last night's table,
with an outage risk the table never had.
