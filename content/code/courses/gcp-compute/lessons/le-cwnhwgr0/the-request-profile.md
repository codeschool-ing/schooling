---
title: The request profile, read before the price list
version: 1
---

The usual way to choose compute is by reputation: Cloud Run is cheap, Kubernetes is flexible,
virtual machines are old-fashioned. **Each of those is true for one shape of traffic and false for
another**, and the price sheet of lesson 1 already says why. A Compute Engine machine and an
Autopilot pod are billed for every hour they exist. Cloud Run bills in two ways: for the whole life
of an instance, or only while a request is inside it. So the first thing to know about a service is
not its language or its framework. It is when the requests arrive.

## A profile is 24 numbers

Write the traffic down as requests per second for each hour of an ordinary day. That is a **request
profile**, and it is enough for the arithmetic of this lesson. Five will serve as examples, each a
different kind of service:

- **steady**, 30 requests a second around the clock: an API other systems call day and night;
- **office**, 60 a second from 09:00 to 18:00 and nothing outside it: an internal tool;
- **nightly**, 14 a second for two hours from 02:00, and silence the rest of the day: a service that
  receives a partner's files once a night;
- **busy**, 400 a second around the clock: the steady service, thirteen times larger;
- **sparse**, one request a second all day: a webhook, a status page, an admin screen.

## Four numbers to read off a profile

**The volume** is the sum of the profile over a month. At 30 a second that is 30 × 3,600 × 24 =
2,592,000 requests a day, and over the average month of 730 hours, 30.42 days, it is 78.84 million:

```
ana@laptop:~/gcp$ python3 -c "print(30 * 3600 * 24, 30 * 3600 * 24 * 730 / 24)"
2592000 78840000.0
```

Cloud Run's fee per request is proportional to this number and to nothing else in the profile.

**The peak** is the busiest hour. Machines and pods have to be sized for it, or scaled up to it in
time (lesson 5), and between peaks they wait at your expense. The office profile peaks at 60 against
a steady 30, so at its busiest it needs twice the capacity, while it carries fewer requests over the
month.

**The idle hours** are the ones with no request at all: none for steady, 15 a day for office, 22
for nightly. An idle hour is where the models part company. Cloud Run scales to zero and pays
nothing for it; a machine or a pod pays in full unless something stops it.

**The duration** is how long one request runs, and with the rate it decides **how busy an instance
is**. At one request a second and 100 ms each, an instance has a request inside it about a tenth of
the time; at 30 a second it almost never has none. That fraction is the number Cloud Run's two
billing modes divide on, as the next section shows. The duration also decides which services can
carry the request at all, which is section 04's subject.

| profile | requests a day | a month | peak per second | idle hours a day |
| --- | --- | --- | --- | --- |
| steady | 2,592,000 | 78.84 M | 30 | 0 |
| office | 1,944,000 | 59.13 M | 60 | 15 |
| nightly | 100,800 | 3.07 M | 14 | 22 |
| busy | 34,560,000 | 1,051.20 M | 400 | 0 |
| sparse | 86,400 | 2.63 M | 1 | 0 |

## Where the numbers come from

For a service that already runs, the profile is in its logs or its metrics: requests per hour,
averaged over a few ordinary weeks, with the slowest and busiest days set aside to look at
separately. `gcp-operations` is the course where Cloud Monitoring and Cloud Logging give you those
numbers. For a service that does not exist yet, the profile is an estimate, and it should be
written down as one, with the reasoning beside it, because it is the assumption every other number
in this lesson rests on.
