---
title: The request profile, read before the price list
version: 1
---

The usual way to choose compute is by reputation: Lambda is cheap, containers are flexible,
instances are old-fashioned. **Each of those is true for one shape of traffic and false for
another**, and the price lists of lessons 1, 9, 14 and 22 already say why. An instance and a
container are billed for every hour they exist. A function is billed for every request it serves.
App Runner sits between them, billing memory while it waits and the processor while it works. So the
first thing to know about a workload is not its language or its framework. It is when the requests
arrive.

## A profile is 24 numbers

Write the traffic down as requests per second for each hour of an ordinary day. That is a
*request profile*, and it is enough for the arithmetic of this lesson. Four of them will serve as
examples, each one a different kind of service:

- **steady**, 30 requests a second around the clock: an API other systems call all day and night;
- **office**, 60 a second from 09:00 to 18:00 and nothing outside it: an internal tool;
- **nightly**, 14 a second for two hours from 02:00, and silence the rest of the day: a job that
  receives a partner's files once a night;
- **busy**, 400 a second around the clock: the steady service, thirteen times larger.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Three request profiles drawn as bars over a 24-hour day, on one scale up to 60 requests a second. steady: 30 a second in every hour. office: 60 a second from 09:00 to 18:00 and nothing outside those hours. nightly: 14 a second from 02:00 to 04:00 and nothing the rest of the day.\"><text x=\"20\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">steady</text><text x=\"20\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">30 a second, all day</text><path d=\"M200 20 L200 90\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"194\" y=\"26\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">60</text><rect x=\"201.0\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"221.4\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"241.8\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"262.2\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"282.7\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"303.1\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"323.5\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"343.9\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"364.3\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"384.8\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"405.2\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"425.6\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"446.0\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"466.4\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"486.8\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"507.2\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"527.7\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"548.1\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"568.5\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"588.9\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"609.3\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"629.8\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"650.2\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><rect x=\"670.6\" y=\"55.0\" width=\"18.4\" height=\"35.0\" fill=\"var(--phosphor)\"></rect><path d=\"M200 90 L690 90\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"20\" y=\"145\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">office</text><text x=\"20\" y=\"163\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60 a second, 09:00 to 18:00</text><path d=\"M200 115 L200 185\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"194\" y=\"121\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">60</text><rect x=\"384.8\" y=\"115.0\" width=\"18.4\" height=\"70.0\" fill=\"var(--phosphor)\"></rect><rect x=\"405.2\" y=\"115.0\" width=\"18.4\" height=\"70.0\" fill=\"var(--phosphor)\"></rect><rect x=\"425.6\" y=\"115.0\" width=\"18.4\" height=\"70.0\" fill=\"var(--phosphor)\"></rect><rect x=\"446.0\" y=\"115.0\" width=\"18.4\" height=\"70.0\" fill=\"var(--phosphor)\"></rect><rect x=\"466.4\" y=\"115.0\" width=\"18.4\" height=\"70.0\" fill=\"var(--phosphor)\"></rect><rect x=\"486.8\" y=\"115.0\" width=\"18.4\" height=\"70.0\" fill=\"var(--phosphor)\"></rect><rect x=\"507.2\" y=\"115.0\" width=\"18.4\" height=\"70.0\" fill=\"var(--phosphor)\"></rect><rect x=\"527.7\" y=\"115.0\" width=\"18.4\" height=\"70.0\" fill=\"var(--phosphor)\"></rect><rect x=\"548.1\" y=\"115.0\" width=\"18.4\" height=\"70.0\" fill=\"var(--phosphor)\"></rect><path d=\"M200 185 L690 185\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"20\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">nightly</text><text x=\"20\" y=\"258\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">14 a second, 02:00 to 04:00</text><path d=\"M200 210 L200 280\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"194\" y=\"216\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">60</text><rect x=\"241.8\" y=\"263.7\" width=\"18.4\" height=\"16.3\" fill=\"var(--phosphor)\"></rect><rect x=\"262.2\" y=\"263.7\" width=\"18.4\" height=\"16.3\" fill=\"var(--phosphor)\"></rect><path d=\"M200 280 L690 280\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"200.0\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">00:00</text><text x=\"322.5\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">06:00</text><text x=\"445.0\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">12:00</text><text x=\"567.5\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">18:00</text><text x=\"690.0\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">24:00</text><text x=\"445.0\" y=\"320\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">requests per second, hour by hour, on one scale</text></svg>", "caption": "Three services with three shapes. The volume, the peak and the idle hours read off each one decide different columns of the bill."}
```

The fourth is left out of the drawing because at the same scale it would be a wall. It is in the
comparison of the next section, and it changes the answer.

## Four numbers to read off a profile

**The volume** is the sum of the profile over a month. At 30 a second that is 30 × 3,600 × 24 =
2,592,000 requests a day, and over the average month of 730 hours, 30.42 days, it is 78.84 million.
The office profile carries 1,944,000 a day, 59.13 million a month; the nightly one 100,800 a day,
3.07 million a month. Lambda's bill is proportional to this number and to nothing else in the
profile.

**The peak** is the busiest hour. Instances and containers have to be sized for it, or scaled up to
it in time (lesson 5), and between peaks they wait at your expense. The office profile has a peak
of 60 against a steady 30, so at its busiest it needs twice the capacity, while it carries fewer
requests over the month.

**The idle hours** are the ones with no request at all: none for steady, 15 a day for office, 22
for nightly. An idle hour is where the models part company. Lambda pays nothing for it, App Runner
pays memory, and an instance or a task pays in full unless something stops it.

**The duration** is how long one request runs. It multiplies Lambda's second meter, the GB-second.
It also decides concurrency, which lesson 16 defined as rate times duration: at 60 requests a
second and 100 ms each, six requests are in flight at once. And it decides which services can carry
the request at all, which is section 04's subject.

| profile | requests a day | a month | peak per second | idle hours a day |
| --- | --- | --- | --- | --- |
| steady | 2,592,000 | 78.84 M | 30 | 0 |
| office | 1,944,000 | 59.13 M | 60 | 15 |
| nightly | 100,800 | 3.07 M | 14 | 22 |
| busy | 34,560,000 | 1,051.20 M | 400 | 0 |

## Where a profile comes from

**An existing service already has one**, in its load balancer's request counts or its API's
metrics, a CloudWatch graph per hour that `aws-operations` lessons 8 to 10 teach you to read.
Take a week, not a day: Monday is not Sunday, and the end of the month is not the middle. Take the
busiest week you can find, because the peak is the number that breaks things.

A new service has no history, and its profile is an estimate. **Write the estimate down anyway**,
with where each number came from: "the shop sells about 2,000 orders a day, each page view makes
eight API calls, evenings are three times the morning". An estimate on paper can be checked against
the first month of real traffic. An estimate in somebody's head turns into "we always knew it would
be cheap" by the time the bill arrives.

Two mistakes recur. The first is to use the **average** instead of the profile: 59.13 million
requests a month averages to 22.5 a second, which hides both the peak of 60 and the 15 silent hours,
the two numbers that decide between the options. The second is to forget the **trickle**: an
outside monitor that calls every minute, or a client that polls every few seconds, turns an idle
hour into a busy one for App Runner, which has to keep an instance active to answer it. Section 05
shows what that costs.
