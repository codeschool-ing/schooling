---
title: "Subnets: slices of the range, and the addresses you do not get"
version: 1
---

A VPC's range is not where machines go. **Machines go in subnets**: smaller CIDR blocks carved out of
the VPC's range, as the previous section carved `10.0.0.0/16` into `/20`s. An instance is launched
into one subnet and takes its private address from that subnet's block. Two subnets of one VPC may
not overlap, and everything the rest of this lesson attaches — a route table, a network ACL, a
load balancer — attaches to subnets.

Why divide at all, when one big block would hold everything? Because the subnet is the unit that
the other controls act on. A route table decides where a whole subnet's traffic may go, so machines
that must never reach the internet go in a subnet whose table has no way out, and machines that
face the internet go in another. The division is a statement about who may talk to what.

## A subnet and a zone

**On AWS, a subnet lives in exactly one availability zone.** You pick the zone when you create it,
and every instance launched into it runs there. So an application that should survive the loss of
a zone needs at least two subnets for each role, one in each zone, and that is why the layouts in
this lesson come in pairs.

The other two providers draw the line elsewhere, and it is worth being exact about it. **On Google
Cloud a subnet is regional**: it spans every zone of its region, and you choose the zone per
instance. On Azure, too, a virtual network and its subnets span all the zones of their region, and
the zone is chosen per resource. The design goal is the same everywhere, machines of each role in
more than one zone; what changes is whether the subnet carries the zone or the instance does.
Lesson 9 is what a zone is, physically, and what crossing between two costs in time.

## The addresses the provider keeps

A `/24` has 256 addresses. You cannot use all of them, because **AWS reserves five addresses in
every subnet**: the first four and the last. In a subnet `10.0.1.0/24` they are these, and
subtracting them leaves the count you can actually hand to machines:

```
ana@laptop:~/cloud$ python3 -c "import ipaddress; s = ipaddress.ip_network('10.0.1.0/24'); print(s[0], s[1], s[2], s[3], s[-1]); print(s.num_addresses - 5)"
10.0.1.0 10.0.1.1 10.0.1.2 10.0.1.3 10.0.1.255
251
ana@laptop:~/cloud$ python3 -c "print(2**(32-28) - 5)"
11
```

AWS documents what each is for. `10.0.1.0` is the network address. `10.0.1.1` is the VPC router,
the gateway every instance in the subnet sends to. `10.0.1.2` is reserved for the provider's DNS
server. `10.0.1.3` is kept for future use. `10.0.1.255` would be the broadcast address, and the
VPC does not carry broadcasts, but the address is held back anyway.

**251 usable addresses in a `/24`**, and at the small end the loss bites. AWS allows subnets from
`/16` down to `/28`; a `/28` is 16 addresses, and the second command shows that 11 of them are
left. Azure also keeps five in each subnet; Google Cloud keeps four in each subnet's primary range.
The exact list differs, and the habit is the same: subtract before you size.

## Sizing without regret

Addresses in a subnet are consumed by more than your own instances. A load balancer puts a node in
each subnet it serves, and each node takes an address; a managed database takes one; so does every
interface of every instance that an autoscaling group (lesson 4) starts during a busy hour. A subnet
that is full refuses the next launch, and on AWS a subnet's range cannot be changed once it exists.

So the default is generous. With `10.0.0.0/16` there are sixteen `/20`s to give away, each with
4,091 usable addresses on AWS, and even six of them — public, application and database, in two
zones — leave ten unused for whatever comes next. Running out of VPC is much harder than running out
of subnet, and a `/28` saves nothing worth having.
