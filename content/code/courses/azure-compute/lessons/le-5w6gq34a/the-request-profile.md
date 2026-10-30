---
title: The request profile, read before the price list
version: 1
---

The usual way to choose compute is by reputation: Functions is cheap, AKS is what serious teams
run, a virtual machine is old-fashioned. **Each of those is true for one shape of traffic and false
for another**, and the billing models of the earlier lessons already say why. A virtual machine, an
App Service plan's instance and an AKS node are billed for every hour they exist (lessons 1, 18
and 11). A Container Apps replica is billed by the second, at a reduced rate while it is idle and
not at all at zero (lesson 8). A function on Flex Consumption is billed for the seconds it executes
and the executions themselves (lesson 16). So the first thing to know about a workload is not its
language or its framework. It is when the requests arrive.

## A profile is 24 numbers

Write the traffic down as requests per second for each hour of an ordinary day. That is a
*request profile*, and it is enough for the arithmetic of this lesson. Five of them will serve as
examples, each one a different kind of service:

- **steady**, 30 requests a second around the clock: an API other systems call day and night;
- **office**, 60 a second from 09:00 to 18:00 and nothing outside it: an internal tool;
- **nightly**, 14 a second for two hours from 02:00, and silence the rest of the day: a service that
  receives a partner's files once a night;
- **webhook**, 0.05 a second around the clock, one call every twenty seconds: a partner's system
  telling you that something changed;
- **busy**, 400 a second around the clock: the steady service, thirteen times larger.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Three request profiles drawn as bars over a 24-hour day, on one scale up to 60 requests a second. steady: 30 a second in every hour. office: 60 a second from 09:00 to 18:00 and nothing outside those hours. nightly: 14 a second from 02:00 to 04:00 and nothing the rest of the day.\"><text x=\"20\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">steady</text><text x=\"20\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">30 a second, all day</text><path d=\"M200 20 L200 90\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"194\" y=\"26\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">60</text><rect x=\"201.0\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"221.4\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"241.8\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"262.2\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"282.7\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"303.1\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"323.5\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"343.9\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"364.3\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"384.8\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"405.2\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"425.6\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"446.0\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"466.4\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"486.8\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"507.2\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"527.7\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"548.1\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"568.5\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"588.9\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"609.3\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"629.8\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"650.2\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"670.6\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><path d=\"M200 90 L690 90\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"20\" y=\"145\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">office</text><text x=\"20\" y=\"163\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60 a second, 09:00 to 18:00</text><path d=\"M200 115 L200 185\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"194\" y=\"121\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">60</text><rect x=\"384.8\" y=\"115.0\" width=\"18.4\" height=\"70.0\" fill=\"var(--phosphor)\"></rect><rect x=\"405.2\" y=\"115.0\" width=\"18.4\" height=\"70.0\" fill=\"var(--phosphor)\"></rect><rect x=\"425.6\" y=\"115.0\" width=\"18.4\" height=\"70.0\" fill=\"var(--phosphor)\"></rect><rect x=\"446.0\" y=\"115.0\" width=\"18.4\" height=\"70.0\" fill=\"var(--phosphor)\"></rect><rect x=\"466.4\" y=\"115.0\" width=\"18.4\" height=\"70.0\" fill=\"var(--phosphor)\"></rect><rect x=\"486.8\" y=\"115.0\" width=\"18.4\" height=\"70.0\" fill=\"var(--phosphor)\"></rect><rect x=\"507.2\" y=\"115.0\" width=\"18.4\" height=\"70.0\" fill=\"var(--phosphor)\"></rect><rect x=\"527.7\" y=\"115.0\" width=\"18.4\" height=\"70.0\" fill=\"var(--phosphor)\"></rect><rect x=\"548.1\" y=\"115.0\" width=\"18.4\" height=\"70.0\" fill=\"var(--phosphor)\"></rect><path d=\"M200 185 L690 185\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"20\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">nightly</text><text x=\"20\" y=\"258\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">14 a second, 02:00 to 04:00</text><path d=\"M200 210 L200 280\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"194\" y=\"216\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">60</text><rect x=\"241.8\" y=\"263.7\" width=\"18.4\" height=\"16.3\" fill=\"var(--phosphor)\"></rect><rect x=\"262.2\" y=\"263.7\" width=\"18.4\" height=\"16.3\" fill=\"var(--phosphor)\"></rect><path d=\"M200 280 L690 280\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"200.0\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">00:00</text><text x=\"322.5\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">06:00</text><text x=\"445.0\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">12:00</text><text x=\"567.5\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">18:00</text><text x=\"690.0\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">24:00</text><text x=\"445.0\" y=\"320\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">requests per second, hour by hour, on one scale</text></svg>", "caption": "Three services with three shapes. The volume, the peak and the idle hours read off each one decide different lines of the bill."}
```

The other two are left out of the drawing. At this scale the webhook would be a line too thin to
see and the busy service a wall. Both are in the comparison of the next section, and each changes
the answer in its own direction.

## Four numbers to read off a profile

**The volume** is the sum of the profile over a month. At 30 a second that is 30 × 3,600 × 24 =
2,592,000 requests a day, and over the average month of 730 hours, 30.42 days, it is 78.84 million.
The office profile carries 1,944,000 a day, 59.13 million a month; the nightly one 100,800 a day,
3.07 million a month; the webhook 4,320 a day, 0.13 million a month. A function's bill follows this
number, and so does the request charge of Container Apps once a subscription has used its free two
million.

**The peak** is the busiest hour. Machines, plan instances, replicas and nodes have to be sized for
it, or added in time for it (lesson 4 for a scale set, lesson 8 for replicas), and between peaks
they wait at your expense. The office profile peaks at 60 against the steady one's 30, so at its
busiest it needs twice the capacity, while it carries fewer requests over the month.

**The idle hours** are the ones with no request at all: none for steady and webhook, 15 a day for
office, 22 for nightly. An idle hour is where the billing models part company. A function pays
nothing for it. A Container Apps replica kept at its minimum pays the idle rate, and a revision at
zero pays nothing. A virtual machine, a plan instance or a node pays in full.

**The duration** is how long one request runs, and it does three jobs. It multiplies a function's
GB-seconds. It decides how many requests are in flight at once, which is the rate times the
duration: at 60 a second and 100 ms each, six. That matters more on Functions than it looks,
because **a Python function app handles one HTTP request per instance at a time by default**, by
Microsoft's documentation on HTTP concurrency for Flex Consumption, read on 30 October 2026. Six
requests in flight are six instances. And the duration decides which services can carry the
request at all, which is the subject of section 04: the longest request, not the typical one.

| profile | requests a day | a month | peak per second | idle hours a day |
| --- | --- | --- | --- | --- |
| steady | 2,592,000 | 78.84 M | 30 | 0 |
| office | 1,944,000 | 59.13 M | 60 | 15 |
| nightly | 100,800 | 3.07 M | 14 | 22 |
| webhook | 4,320 | 0.13 M | 0.05 | 0 |
| busy | 34,560,000 | 1,051.20 M | 400 | 0 |

The webhook is the odd row and worth a second look. It never sleeps, so it has no idle hour, and
it carries almost nothing. An instance kept for it is busy for a fraction of a second every twenty
seconds and paid for all of them.

## Where a profile comes from

**An existing service already has one**, in its request counts per hour: the metrics of the load
balancer or Application Gateway in front of it, or of the Container App or web app itself, which
`azure-operations` lessons 8 to 13 teach you to read in Azure Monitor. Take a week, not a day:
Monday is not Sunday, and the end of the month is not the middle. Take the busiest week you can
find, because the peak is the number that breaks things.

A new service has no history, and its profile is an estimate. **Write the estimate down anyway**,
with where each number came from: "the shop sells about 2,000 orders a day, each page view makes
eight API calls, evenings are three times the morning". An estimate on paper can be checked against
the first month of real traffic. An estimate in somebody's head turns into "we always knew it would
be cheap" by the time the bill arrives.

Two mistakes recur. The first is to use the **average** instead of the profile: 59.13 million
requests a month averages to 22.5 a second, which hides both the peak of 60 and the 15 silent hours,
the two numbers that decide between the options. The second is to forget the **trickle**: an
outside monitor that calls every minute, or a client that polls every few seconds, turns an idle
hour into an active one. Under Microsoft's billing rules a Container Apps replica is idle only
while it handles no request, uses less than 0.01 of a core and receives under 1,000 bytes a
second, so a trickle keeps it on the active rate. Section 05 shows what that costs the shop.
