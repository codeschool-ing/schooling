---
title: A worked choice for the shop
version: 1
---

The shop has four pieces of compute, and they do not all want the same answer. **Choosing per
service is the point of this lesson**: a single platform for everything is a decision about the
team, sometimes a good one, and it should be taken as that rather than arrived at by default.

## The orders service

The orders service of lesson 8 is the one with a real profile. Its logs, averaged over ordinary
weekdays, give one or two requests a second at night, a climb from 07:00, a plateau of 35 to 40
from 09:00 to 16:00, and a slow fall into the evening. Written as 24 rates and given to the program:

```
ana@laptop:~/gcp$ python3 prices.py | python3 compare.py orders=2,1,1,1,1,1,2,6,18,35,40,38,30,36,40,38,30,22,14,10,8,6,4,3
profile      requests  Compute Engine    Run, request   Run, instance       Autopilot
orders         42.38M           97.84           54.97           49.93          112.67

Request-based billing is the cheaper of the two while an instance is busy less than 75% of the time, before the charge per request.
Autopilot includes the cluster fee; the free tier credit covers one cluster's fee a month.
```

**42.38 million requests a month, no idle hour and a peak of 40.** An instance is busy most of the
day and rarely empty at night, so Cloud Run with instance-based billing is the cheapest at 49.93,
with request-based close behind at 54.97. Compute Engine's two machines cost twice that and sit
mostly idle; Autopilot's floor of two pods and its cluster fee cost more still.

Now the question a choice should always be asked: what if it works? Ten times the traffic, the same
shape:

```
ana@laptop:~/gcp$ python3 prices.py | python3 compare.py orders-x10=20,10,10,10,10,10,20,60,180,350,400,380,300,360,400,380,300,220,140,100,80,60,40,30
profile      requests  Compute Engine    Run, request   Run, instance       Autopilot
orders-x10     423.76M           97.84          301.69          104.03          153.17

Request-based billing is the cheaper of the two while an instance is busy less than 75% of the time, before the charge per request.
Autopilot includes the cluster fee; the free tier credit covers one cluster's fee a month.
```

At ten times the volume, **two `e2-standard-2` machines, at 97.84, become cheaper than Cloud Run by
instance at 104.03**, because the machines were never full before and now are. Request-based billing
has fallen far behind, paying its fee on 424 million requests. The choice made today should
therefore be Cloud Run with instance-based billing, written down with the volume at which it gets
revisited, around ten times today's.

## The other three

- **The web front end** serves pages to people. Its profile follows the shop's customers, with
  quiet nights, and it fits Cloud Run for the same reasons as orders. It shares the orders
  service's build, its registry (lesson 21) and its deployment habits.
- **The photos worker** makes thumbnails when an image arrives. Nothing calls it on a schedule;
  each upload is an event. That is the shape of Cloud Run functions with an Eventarc trigger
  (lessons 17 and 18), and its bill follows uploads rather than hours.
- **The nightly export** builds a report of the day's orders and runs for about 20 minutes. It is
  not a service at all: it starts, works and stops. A Cloud Run job, started by Cloud Scheduler
  (lessons 10 and 20), pays for those 20 minutes and nothing else.

## The decision, written down

| service | where it runs | why | revisit when |
|---|---|---|---|
| orders | Cloud Run, instance-based billing | busy most of the day, scales to zero if it ever goes quiet | traffic reaches ten times today's |
| web | Cloud Run | the same shape as orders | the same |
| photos worker | Cloud Run functions, Eventarc | one event per upload | a single thumbnail takes longer than the function's limit |
| nightly export | Cloud Run job, Cloud Scheduler | work that finishes | the export takes hours |

**Nothing here runs on Compute Engine or GKE**, and that is a result, not a principle. A shop with a
service that needs a GPU, a long-lived connection or a protocol other than HTTP would have a row
that does. The table is a record of reasons, and its last column is the part most teams forget:
the condition under which the reasons stop being true.
