---
title: When a region fails
version: 1
---

The picture most people hold of an outage is binary: the cloud is up, or the cloud is down. Real
incidents are more partial than that, and the most useful distinction for reading one, and for
designing against one, is between two halves of every service. **The control plane changes things;
the data plane runs them.**

The **control plane** is the part you call to create, change or delete: launch an instance, resize a
database, create a user, edit a DNS record, change a load balancer's rules. It is an API, with a
console on top of it, and it is used a few times a day.

The **data plane** is the part that does the work you already set up: the running instance answering
requests, the bucket serving objects, the DNS servers answering queries for the records that already
exist, the load balancer forwarding traffic. It is used millions of times a day, and providers build
it to keep working when the control plane does not.

So a failure can take away the ability to change anything while everything already running carries
on. **Your instances keep serving; you cannot launch a new one.** That is a bad afternoon for anybody
whose recovery plan begins with "launch more instances", and a quiet one for anybody whose plan needed
nothing new.

## Recovery plans that need the control plane

Look at the recovery strategies from the section on a second region with this distinction in hand.
Backup and restore builds a whole system in the second region: every step is a control-plane call,
made in the second region, which is fine as long as the trouble is in the first. Now look inside one
region. A design that survives a zone failure by **launching** replacement instances in the surviving
zone needs the control plane at the worst possible moment, when many other customers are trying to
do the same thing. A design that already has enough capacity running in the other zone needs nothing
from the control plane at all: the load balancer's health checks, which are data plane, move the
traffic.

AWS's own guidance calls this property **static stability**: a system that keeps working through a
failure without having to change anything. It costs capacity you pay for and do not use on a normal
day, which is the same trade the whole lesson keeps making.

## Global services that live in one region

Some services are global, in the sense that you do not choose a region for them: identity and access
management, DNS, the content delivery network. Their data planes are spread out. **Their control
planes are not always**, and AWS documents, in its guidance on fault isolation, that the control
planes of several global services, IAM, Route 53 and CloudFront among them, run in `us-east-1`.

Read what that means for an application that lives entirely in `sa-east-1`. If `us-east-1` has a
control-plane problem, your instances in São Paulo keep running, the roles your instances already hold
keep working, and your DNS keeps answering. But creating a new role or changing a DNS
record to point at your standby may not work until Virginia recovers. **A failover plan whose first
step is "change the DNS record" depends on a region you never chose.**

## Know where your dependencies live

The practical lesson is a table, written before the day it is needed. For every dependency, write
down where it runs and what you lose when that place fails:

| dependency | where it runs | if that place fails |
|---|---|---|
| application instances | `sa-east-1`, zones a and b | the other zone carries the load |
| database | `sa-east-1a`, standby in `sa-east-1b` | the standby is promoted |
| DNS records | global; changes go through `us-east-1` | answers continue, edits may not |
| payment gateway | the gateway's own provider and region | ask them, and write the answer down |
| sign-in provider | the provider's region | nobody new signs in |

Two rows in that table are not yours at all. Third-party services run somewhere too, and a gateway or
a sign-in provider hosted in one region is a dependency on that region, whether or not your own
account has ever touched it. The table is only useful if it is honest about those rows as well.

A building burning down is the failure everybody plans for. The one that surprises is a dependency
nobody knew about, which turns out to live somewhere else. `observability`
is the course that watches these dependencies while they run; this table is what tells you which ones
to watch.
