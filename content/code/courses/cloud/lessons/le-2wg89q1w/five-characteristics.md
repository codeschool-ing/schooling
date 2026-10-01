---
title: Five characteristics, and a server that has one of them
version: 1
---

In 2011 the US National Institute of Standards and Technology published a short document, Special
Publication 800-145, *The NIST Definition of Cloud Computing*. It names **five essential
characteristics**, three service models and four deployment models. The service models are this
lesson and the deployment models are lesson 2. It is still the definition people cite, because it
describes properties a service has rather than products somebody sells, and properties do not go out
of date.

A service is cloud computing, in NIST's sense, when it has all five.

## On-demand self-service

You get computing, a machine or a disk or storage space, **when you ask for it and without a person
at the provider taking part**. The request goes to an API; the provider's software checks your
account and your limits and creates the thing. A console where you click "create" is the same
request with a form in front of it. Nobody at the other end has to read it, so it is answered at three in the morning as fast as at noon.

## Broad network access

The service is reached **over the network, by standard means**. The console is a web page, the API
is HTTPS, and the command-line tools are programs that call that same API. So the same account is
managed from a laptop, a phone or a script running on another server, and the machines you create
are reached by the protocols the `networks` course taught: SSH to log in, HTTP to serve a page.

## Resource pooling

The provider's physical resources **serve many customers at once**, and are handed out and taken back
as demand moves. You do not know which server your machine runs on or which disk holds your data;
you choose a location at a coarser level, a region such as `sa-east-1`, and the provider places you
inside it. The sheet shows the pooling in the sizes it sells: a `t3.micro` has 2 vCPU and 1 GiB of
memory, far smaller than any server anybody builds. It is a slice of a larger one, and the rest of
that server belongs to other customers.

## Rapid elasticity

Capacity **grows and shrinks quickly, and can do it on its own**. A shop runs two machines most of
the year, ten in the week of a sale and two again after it, and from where the customer stands the
supply looks unlimited. Elasticity is what pooling buys you: the ten machines are there because the
provider keeps spare capacity shared by everybody, not because you ordered them in October. Lesson 4
shows how the growing and shrinking is automated.

## Measured service

Usage is **metered, and the meter is what you pay by**. The course's price sheet quotes a
machine by the hour, storage by the gigabyte-month and Lambda by the million requests and the
GB-second. Because the provider measures, you can measure too: the same numbers that make the bill
show you which part of a system is costing what, which is what lesson 10 is about.

## A rented server, held against the five

Take the older kind of hosting from the previous section: a physical server rented by the month,
ordered through a form and installed by a technician. Hold it against the list.

| characteristic | a server rented by the month |
|---|---|
| on-demand self-service | no: a person installs it, and the wait is days |
| broad network access | yes: you reach it over the internet like anything else |
| resource pooling | no: the whole machine is yours, and idle when you are |
| rapid elasticity | no: a bigger one is a new order and a new wait |
| measured service | no: the price is the same whatever you used |

**One of five.** It is somebody else's computer and it is on the internet, and neither of those
makes it cloud. Each "no" in that table is a decision you take months ahead and pay for whether you
were right or not.

The line between the two has blurred since 2011. Some companies that rent dedicated servers now
provision them through an API in minutes and bill them by the hour, which moves them up the table,
and lesson 3 meets providers on both sides of it. The five are the test to apply, whatever a
company calls itself.
