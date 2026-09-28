---
title: "DigitalOcean: a short list, written for developers"
version: 1
---

DigitalOcean is a New York company that set out to sell one developer a server in under a minute,
with a price on the page that did not need a calculator. Its virtual machines are called
**Droplets**, and the rest of the product line is short. Volumes are its block storage and Spaces
its S3-compatible object storage. Beside them sit managed databases, load balancers, private
networks and managed Kubernetes. The last is App Platform, a platform in the sense of lesson 1 that
builds and runs an application from its repository.

## Developer-first, in practice

"Developer-first" is a slogan until you look at what it means here. It means **the defaults are
chosen for one person with one project**: a Droplet is created from a short form, reaches the
internet with a public address, and accepts the SSH key you gave it. It means a large library of
written tutorials on setting up servers and software, which many people read long before they had
any account there, because they explain Linux administration rather than DigitalOcean.

And it means leaving things out. There is no catalogue of hundreds of managed services, no data
warehouse, no queue of the SQS kind. A team that needs one runs it on a Droplet or buys it from
someone else.

## The price model

The model is the part worth understanding, because it is the opposite of the metering you met in
the AWS section. **Each Droplet size has one monthly price**, and the same page shows it as an
hourly rate too. You are charged for the time the Droplet exists, and a Droplet that exists all
month costs the monthly price and no more. A quantity of outbound data transfer comes with each
Droplet, pooled across the account, and only transfer beyond that pool is charged by the gigabyte.

Compare what a single machine costs to read at each kind of provider:

| | a hyperscaler | DigitalOcean |
| --- | --- | --- |
| the machine | per hour or per second, by size | one monthly price, by size |
| its disk | a separate line, per GB-month | included in the size |
| its public IPv4 address | a separate line, per hour | included |
| data it sends out | a separate line, per GB | included up to an allowance |

The AWS sheet in this course shows the separate lines are real: a public IPv4 address is `0.0050`
USD an hour in both regions, and a gp3 disk is `0.1520` USD per GB-month in `sa-east-1`. None of
them is large. The point is that **at DigitalOcean the bill for a small project is a few lines you
could predict in advance**, and at a hyperscaler it is the sum of several meters.

The amounts themselves are on DigitalOcean's pricing pages, which this course did not capture. The
comparison is yours to make, with the method at the end of this lesson.

## Regions

DigitalOcean runs data centres in North America, Europe, Asia and Australia, and **none in South
America**. A shop in Brazil whose customers are in Brazil serves them from another continent, which
costs latency (lesson 9) and raises the question of where personal data may be kept (lesson 2).
That is not a reason to rule it out; it is a line on the checklist at the end of this lesson.
