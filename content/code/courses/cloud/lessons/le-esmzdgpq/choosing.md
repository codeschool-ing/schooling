---
title: "Choosing: a checklist, not a winner"
version: 1
---

The question people ask is **"which provider is best?"**, and it has no answer, because it leaves
out the only things that decide it: what you are building, for whom, and who will run it. What
this section gives you instead is the order in which to ask. Each question removes candidates, and
the early ones remove the most.

| ask | why it comes here | where this course covers it |
| --- | --- | --- |
| Which managed services does the design need? | a service only hyperscalers sell rules out the rest at once | this lesson, lessons 4 to 8 |
| Where are the users, and where may the data live? | latency and the law, and some providers have no region there | lessons 2 and 9 |
| What does the team already know? | the provider you can operate is cheaper than the one you cannot | this lesson |
| What support will you need, and at what hour? | an outage at 3 a.m. is when support is tested | this lesson |
| What would leaving cost? | data transfer out, and every proprietary service used | this lesson, lesson 10 |
| What shape will the bill take? | many meters, or a few monthly prices | lesson 10 |

## The services first

Write down every piece your design assumes, and mark the ones you are not willing to run yourself.
If the list is a machine, a PostgreSQL database and object storage, **every provider in this
lesson qualifies**, and the other questions decide. If the list includes a data warehouse, a managed
queue or a directory of the company's staff, the choice is already among the hyperscalers, and
sometimes already one of them.

## Then where

Lesson 9 measures the latency; here the question is only whether the provider is there at all. For
users in Brazil, AWS has `sa-east-1`, Azure has Brazil South, Google Cloud has
`southamerica-east1`, and Akamai has a São Paulo region. **DigitalOcean and Hetzner have none in
South America.** Where personal data may be stored is the other half, and lesson 2 discussed it: a
region in the country is not always required, but when it is, it is not negotiable.

## The team, and support

A team that has run AWS for five years will run it better than a cheaper provider it has never
used, and the difference shows up as incidents rather than as a line on the invoice. That is a
reason to stay, not a law: skills can be learnt, and the tracks this course belongs to exist for
that. Support is the related question. The hyperscalers sell support plans as a separate product;
before you depend on a provider, find out what answering you in the middle of the night costs there.

## What leaving costs

Leaving has two prices. One is on the sheet: data leaving AWS for the internet is `0.1500` USD per
GB for the first 10 TB a month in `sa-east-1`, and data coming in is `0.0000`. Moving 5,000 GB of
files out of São Paulo in one month is 5,000 × 0.1500 = 750 USD at list price. **Coming in is free
and going out is not**, at every hyperscaler, and the asymmetry is worth remembering on the day you move in.

The other price is not on any sheet: the work of replacing whatever you built on a service only one
provider sells. A virtual machine, PostgreSQL, the S3 API and Kubernetes move between providers
with modest effort, because every provider sells something equivalent. A design built on DynamoDB,
BigQuery or Azure's identity integration moves only by being rewritten. Neither is wrong; **choose
the proprietary service knowing what the exit costs**, instead of discovering it on the day you
need it.

## Two cases

A three-person company selling to customers in Brazil, with a web application, PostgreSQL and
uploaded images, needs the core, in the country. The candidates are the three hyperscalers and
Akamai, and a Brazilian provider if its catalogue covers the core; the team's skills and the shape
of the bill decide among them.

A company whose staff sign in through Microsoft 365, running SQL Server on Windows machines in its
own building, starts with Azure ahead on identity and licences. Another provider has to win that comparison; Azure does not have to lose it.

Neither case produces a winner the next company could copy, and neither was meant to.
