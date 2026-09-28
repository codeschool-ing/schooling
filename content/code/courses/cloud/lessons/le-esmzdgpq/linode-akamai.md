---
title: "Linode, now Akamai: machines beside a delivery network"
version: 1
---

Linode started in 2003 selling Linux virtual servers, three years before EC2, which makes it one of the
early companies to rent a virtual machine to anyone with a card. For most of its life it looked
like DigitalOcean does today: a short product list, a monthly price per plan with transfer
included, and customers who were mostly developers and small companies.

**In 2022 Akamai bought it**, and that changed what it is for.

## What Akamai adds

Akamai is one of the oldest content delivery networks. Its business was, and is, a very large
number of servers placed close to users, inside or near the networks of internet providers. They
answer requests for websites and video, so that the request does not have to cross the world. What
it did not have was a place to rent an ordinary virtual machine. Linode was that place.

So the product that used to be called Linode is now sold under **Akamai's name, as Akamai's
cloud computing**. Its argument is the combination: virtual machines, disks and databases in a set
of regions, next to a delivery network that reaches much further than the regions do. A
video service, for example, can keep its encoding machines in a region and hand the finished files
to the delivery network in front of them, from one company and on one bill.

The name Linode has not disappeared. It is still in the API's address, in the command-line tool
(`linode-cli`) and in much of the documentation, and people still say "a Linode" for one of its
virtual machines. **When you read Linode and Akamai cloud in two places, they are the same
product.**

## The product list

It is the short list again, with names of its own:

| what | Linode's name |
| --- | --- |
| a virtual machine | a Linode, with shared or dedicated processors |
| block disks | Block Storage volumes |
| object storage | Object Storage, S3-compatible |
| a load balancer | a NodeBalancer |
| managed Kubernetes | LKE, the Linode Kubernetes Engine |

Managed databases and private networks sit beside them. The price model is the one DigitalOcean
and Hetzner share: **a plan has a monthly price, with transfer included**, and the hourly rate stops
counting at that monthly price. Akamai publishes the amounts on its own pages, which this course did
not capture.

## A region in São Paulo

Of the three smaller providers in this lesson's title, **Akamai's is the one with a region in São
Paulo**. For a Brazilian team that wants the short list and the simple bill, but needs its machines
in the country for latency or for the law, that single fact can decide between the three before
price is even looked at.

It also shows why the checklist at the end of this lesson puts regions before price. A provider
that is cheaper and on another continent is not cheaper for a user who notices every round trip,
and lesson 9 is where that trip gets a number.
