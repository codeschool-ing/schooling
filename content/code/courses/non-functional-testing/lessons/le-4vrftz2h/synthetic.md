---
title: Synthetic and real-user monitoring
version: 1
---

Lesson 22's metrics come from inside the server. They count what the server answered and time
what the server did, and they share one blind spot with the server itself: **a request that never
reached it leaves no trace there.** A DNS record pointing at the wrong address, a certificate that
expired at midnight, a load balancer sending everybody to a machine that is switched off. To the
server that is a quiet night, and the request rate going down looks like people going to bed.

So production is watched from outside as well, and there are two ways to stand outside.

**Synthetic monitoring** is a program pretending to be a customer, on a schedule. Every minute it
does what a customer would do — open the list of shows, pick one, book a seat — and checks that
each step answered, answered correctly and answered in time. Nobody has to be using the system for
it to work, so it finds the outage at 04:00 before the first real customer at 07:00 does. It is a
functional test, a load test of one user and a monitor at the same time, run against production
for as long as production exists.

**Real-user monitoring**, RUM for short, measures the people who are actually there. A small script
in the page reports how long each visit took to load, which errors the browser threw, which
country and which kind of phone. Lesson 10's Core Web Vitals are read this way when they come
from the field rather than from Lighthouse. It sees everything real users do and nothing they do
not: at 04:00 it has nothing to say.

| | synthetic | real users |
|---|---|---|
| who makes the traffic | your script, on a schedule | your customers, when they feel like it |
| sees an outage with nobody using the system | yes | no |
| sees the path nobody scripted | no | yes |
| results comparable from one day to the next | yes, the same journey every time | only in aggregate, the mix of users moves |
| cost | the probe's own traffic, and its test data | a script on every page, and what it collects about people |

**They answer different questions, so a team needs both.** The synthetic check says *the journey I
wrote still works*; real-user monitoring says *this is what people are going through*. The rest of
this lesson builds the first, because it can be built from nothing in the machine you have.

## Runscope, and where it went

The products for synthetic API monitoring are older than most teams that use them. **Runscope** is
the one this lesson's title names, a hosted service of the 2010s. You wrote a sequence of API
requests with assertions on each one — status, a field in the JSON body, a time limit — and it ran
them on a schedule from locations around the world and told you when one failed. That is exactly the shape of the probe in the next section.

Its history is a small lesson in what happens to a SaaS tool. According to the press coverage of
the time and to Wikipedia's article on it, **CA Technologies bought Runscope in September 2017**,
a year after buying BlazeMeter, the load-testing service, and put the two side by side. Broadcom
bought CA in 2018. In 2019 Runscope's monitoring was merged into the BlazeMeter platform, where it
became its API monitoring feature, and in 2021 Broadcom sold BlazeMeter to Perforce. Those dates
come from secondary sources — news reports and Wikipedia — and were not checked against the
original announcements, and whether the old runscope.com service still accepts new accounts was
not checked at all. Nothing in this lesson ran either product.

What survives every acquisition is the idea, and the idea is portable. The tests you write in a
hosted product are written in that product's format, and moving them when the product changes
owner is the same lock-in lesson 22 described for dashboards. A probe that is a file in your own
repository moves with you.

Datadog, New Relic and Grafana Cloud all sell synthetic checks today, as do Checkly, Uptime Robot
and many others; so, in a sense, does k6, which can run a script with `checks` and `thresholds` on
a schedule from Grafana's own locations.
