---
title: Why a function goes into a VPC, and what it does not get there
version: 1
---

A common instinct is that a function is safer inside a VPC, as a server is safer behind a
firewall. **A function goes into a VPC for one reason: to reach something that only has a private
address.** It does not become harder to attack there, because nothing could connect to it in the
first place, and it gives up something on the way in. The question to ask before attaching one is
not "should this be private" but "what does this function need to reach, and where does that
thing live".

## Where a function runs when nobody says

A function with no VPC configuration still runs in a network: one that AWS owns and operates,
outside your account. From there it can open connections to the internet and to every public AWS
endpoint, which is how it calls S3, DynamoDB, SQS or a payment provider's API. **It has no
address in your VPC**, so it cannot open a connection to anything that exists only inside it.

And nothing reaches it from outside. A Lambda function has no listening port of its own, no
public address and no security group to open. Every request arrives through Lambda's own
service, which is reached by an API call that IAM authorises, and lesson 15's triggers are all
variations of that call. This is why putting a function in a VPC adds no protection against
inbound attacks: there was no inbound path to close.

## What needs it

The things that need a function in your VPC are the things with private addresses:

- **a database in a private subnet**, the commonest case by far: RDS or Aurora, which `aws-data`
  covers, and a PostgreSQL on EC2 that nobody would give a public address;
- **a cache**, ElastiCache for Redis or Memcached, which is only ever reachable inside its VPC;
- **an internal load balancer** in front of services that are not public, lesson 8's ECS
  services among them;
- **a file system on EFS**, which lesson 3 described, mounted by the function through mount
  targets in the subnets;
- **something on premises**, reached through a VPN or Direct Connect that ends in the VPC.

What does **not** need it is anything reached through a public AWS API with IAM: S3, DynamoDB,
SQS, SNS, Secrets Manager, Step Functions. Those are called with a signed request, and the
function's role decides whether the call is allowed. Putting a function in a VPC to "protect"
its access to DynamoDB is the instinct of the first paragraph, and it gets the function nothing
but a network problem.

## What it gives up

**A function in a VPC loses the internet.** Its network interfaces sit in your subnets, they
have private addresses only, and its traffic follows your route tables. A subnet without a route
to a NAT gateway, which is what "private" means in `aws-foundations` lesson 17, sends nothing to
the internet, and that includes the public endpoints of S3, SQS and every other AWS service the
function used to reach without a thought.

The trap inside this is a public subnet. **Putting the function in a public subnet does not give
it the internet back**, because Lambda never assigns a public address to the interfaces it uses,
and a subnet's route to an internet gateway is useless to an interface without one. AWS's
documentation says this outright, and it is the first thing a team tries.

So the decision has a price on each side. A function that needs a private database and also calls
a public API needs both a VPC and a way back out, and the way out is either a NAT gateway, billed
by the hour and by the gigabyte, or a VPC endpoint per AWS service. This lesson's last section
prices the first and builds the second.

There used to be a third price, paid on every cold start, and it is the reason "keep Lambda out
of VPCs" is advice you will still read. The next two sections configure a function in a VPC and
then explain what AWS changed in 2019 that made the advice obsolete.
