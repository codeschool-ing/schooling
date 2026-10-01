---
title: "When a machine cannot be reached: the path, in order"
version: 1
---

"I can't reach the server" has five usual causes in a VPC, and they sit along one path. In order:
the program, the machine's security group, the subnet's network ACL, the subnet's route table, and
the way in from outside, a public address or a load balancer. Checking them in a fixed order, and
reading the symptom before you start, turns an afternoon of changing settings at random into a few
minutes.

## Read the symptom first

`networks` taught the difference between the two failures a client reports, and in a VPC it points
straight at half the list.

**A timeout means something dropped the packet.** Nothing answered at all. Security groups and
network ACLs drop without a word, a route table with no way back loses the reply, and an instance
with no public address has nothing at that address to answer. Every one of those looks the same
from the client: it waits and gives up.

**"Connection refused" means the packet arrived.** The machine's own operating system answered, with
a TCP reset, because nothing listens on that port. So the security group let it in, the ACL let it
in, the route delivered it, and you can stop looking at the network. The fault is on the machine:
the service is not running, runs on another port, or listens only on `127.0.0.1`.

## The checklist

Work outwards from the machine, because the inner checks are the cheapest and the most often
wrong.

1. Is the service listening, and on which address? On the instance, through the provider's
   console session or SSH from inside the VPC, `ss -tln` lists the listening TCP sockets.
   `0.0.0.0:8080` accepts connections on every interface; `127.0.0.1:8080` accepts only from the
   machine itself, and everything from outside is refused. A service that is fine on the machine
   and refused from anywhere else is this, almost every time.
2. The instance's security groups. Is there a rule for this protocol and port, and does its
   source include where the connection comes from? From the internet that is the client's address;
   through a load balancer it is the load balancer's group, not the client.
3. The subnet's network ACL. Both directions: the inbound rule for the port, and the outbound
   rule for the replies to the ephemeral ports. Check the rule numbers, since a deny with a lower
   number wins.
4. The subnet's route table. A public instance's subnet needs `0.0.0.0/0` to the internet
   gateway; a private instance that must reach out needs it to a NAT gateway.
5. The way in. Reached directly, the instance needs a public address. Reached through a load
   balancer, look at the target's health status: a target the load balancer considers unhealthy
   receives nothing, and the reason for the failing check is usually one of steps 1 to 3 seen from
   the load balancer's side.

## Test from the right place

Where you test from splits the path in two. **From another instance in the same VPC**, a connection
to the private address, with `nc -zv -w 3 10.0.32.10 8080`, crosses the security group and, if the
two are in different subnets, the ACLs. It does not cross the internet gateway or the public address. If that
works and the outside does not, the service is fine and the fault lies between the outside and the
machine: a rule's source, the ACL, the route, the address. If it fails too, start again at step 1.

Change one thing at a time, and put back what did not help. A security group opened to
`0.0.0.0/0` "just to test" that fixes nothing is a hole that stays behind; one that fixes it tells
you the source was wrong, and the right fix is the source, not the open rule. The providers also
record accepted and rejected packets if you turn it on, in what AWS calls VPC flow logs, and
`observability` is where reading them belongs.
