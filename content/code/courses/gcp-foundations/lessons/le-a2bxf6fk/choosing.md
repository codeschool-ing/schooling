---
title: Choosing one, and what it costs
version: 1
---

**Choosing a load balancer is answering the three questions of the first section in order**, and most
choices are made by the first answer that rules something out.

| the planner's case | the deciding fact | the load balancer |
|---|---|---|
| the public website and its API | HTTP, customers everywhere, TLS at the edge | global external Application |
| a reports service other teams call from inside | HTTP, nobody outside, one region | regional internal Application |
| a partner sends files over SFTP | TCP, not HTTP, from the internet | external proxy Network |
| an internal database pool | TCP, inside, the database must see the caller's address | internal passthrough Network |
| a game server on UDP | UDP, and the client's own packets | external passthrough Network |

Two rules of thumb sit behind the table. **If it is HTTP, use an Application Load Balancer**, because the
URL map, the CDN and Cloud Armor are only there. **If the backend must see the client's real address in the
packet, it is passthrough**, because every proxy, by being one, replaces it; the Application Load Balancers
pass the original address on in the `X-Forwarded-For` header instead, which is enough for an HTTP
application and nothing else.

Regional load balancers built on Envoy, the regional Application and proxy Network ones, need one more thing
in the network: a **proxy-only subnet** in their region, a range set aside for the proxies Google runs on the
customer's behalf. It is a `/23` or so of lesson 15's arithmetic, kept out of everything else, and forgetting
it is the usual reason the first regional load balancer refuses to be created.

## What it costs

The Cloud Load Balancing pricing page, read on 30 October 2026, prices the global external Application Load
Balancer in two parts:

| part | price |
|---|---|
| **forwarding rules** | 0.025 USD an hour for the first five together, 0.01 for each one after that; counted per project, and global and regional rules separately |
| **data processed** | charged in the region where the traffic is processed; for Iowa, the page's default, 0.008 USD per GiB in and 0.008 out |

São Paulo has its own figure in the same table, chosen by the region selector on the page, which is not text
this lesson could read. The arithmetic is the same shape either way. The planner's one forwarding rule all
month is 730 hours at 0.025, **18.25 dollars**, whatever the traffic. A terabyte served through it adds the
processing charge on top of the egress of lesson 1, and **Cloud CDN is the lever**: a response served from
the cache at the edge never passes through the load balancer, so it is processed by nobody and billed as CDN
egress instead.

**The first five rules cost the same as one.** The planner's HTTPS rule needs a second on port 80 only to
redirect plain HTTP to HTTPS, which it wants, and the second rule costs nothing more: both are inside the first
five, and the pricing page's own example says one rule and three rules are both 0.025 an hour.
