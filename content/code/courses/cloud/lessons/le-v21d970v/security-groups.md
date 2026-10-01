---
title: "Security groups: a stateful filter on each machine"
version: 1
---

A route decides where a packet may go. A filter decides whether it is let through when it gets
there, and the one you will use most is the **security group**: a firewall attached to an instance's
network interface. The provider enforces it outside the machine, so nothing running on the instance
can switch it off.

Three properties define it, and each one is a mistake somebody makes once.

**It only allows.** A security group is a list of allow rules; there is no deny rule to write.
Whatever no rule allows is dropped. A new group on AWS has no inbound rules, so nothing gets in,
and one outbound rule allowing everything out.

**It is stateful.** The provider tracks connections. When a rule lets a request in to port 443,
the reply goes back out without any outbound rule saying so, and when the instance opens a
connection outwards, the answer comes back in without an inbound rule. You write rules for who may
**start** a conversation, and the rest of it follows.

**A source can be another security group.** Instead of an address range, a rule can name a group,
and it then admits traffic from any interface that carries that group. This is the property that
makes the layouts in this lesson work, because in the cloud addresses do not stay put: the
autoscaling group of lesson 4 replaces an instance and the new one has a new private address. A
database that accepts port 5432 only from the application's group keeps admitting every
application server, today's and tomorrow's, and nothing else in the VPC.

## A group's rules, written down

On AWS, inbound rules are added with `aws ec2 authorize-security-group-ingress`, which takes them
as JSON in `--ip-permissions`. The CLI prints the shape of one permission without contacting AWS:

```
ana@laptop:~/cloud$ aws ec2 authorize-security-group-ingress --generate-cli-skeleton | jq '.IpPermissions[0] | keys'
[
  "FromPort",
  "IpProtocol",
  "IpRanges",
  "Ipv6Ranges",
  "PrefixListIds",
  "ToPort",
  "UserIdGroupPairs"
]
```

Here are two rules for the application servers' group, in that shape. They were written for this
lesson and applied nowhere; the group ids are placeholders in the form AWS's own documentation
uses.

```schooling-example
{"language": "json", "file": "app-ingress.json", "parts": [{"code": "[\n  {\n    \"IpProtocol\": \"tcp\",\n    \"FromPort\": 8080,\n    \"ToPort\": 8080,", "note": "The file is a list of permissions, and this is the first. A protocol and a range of ports, from `FromPort` to `ToPort`: a single port is a range of one. The application listens on 8080 in this lesson's layout, and only the load balancer talks to it there."}, {"code": "    \"UserIdGroupPairs\": [\n      {\n        \"GroupId\": \"sg-0123456789abcdef0\",\n        \"Description\": \"from the load balancer's group\"\n      }\n    ]\n  },", "note": "**The source is a group, not an address.** Any network interface carrying the load balancer's group may open a connection to 8080. When the load balancer's nodes change address, which is the provider's business, this rule does not change. `Description` is for the next person who reads the group."}, {"code": "  {\n    \"IpProtocol\": \"tcp\",\n    \"FromPort\": 22,\n    \"ToPort\": 22,", "note": "The second permission, SSH on 22. It has the same shape as the first; only the source is of a different kind."}, {"code": "    \"IpRanges\": [\n      {\n        \"CidrIp\": \"203.0.113.0/24\",\n        \"Description\": \"SSH from the office\"\n      }\n    ]\n  }\n]", "note": "An address range as the source, written in CIDR. `203.0.113.0/24` is a block reserved for documentation, standing in for the office's public addresses. The same rule with `0.0.0.0/0` would offer SSH to every address on the internet."}]}
```

Written to a file, it would be handed over as
`aws ec2 authorize-security-group-ingress --group-id <the app's group> --ip-permissions file://app-ingress.json`.
Not run here: there is no account in this course, and what AWS would answer is not shown.

## What the rules do not say, and what that means

There is no outbound rule in that file, and none is needed for the replies. There is no rule for
the database either: the database's own group carries one permission, TCP 5432 with the
application's group as its source, and that is the entire answer to "who may reach the database".

**An interface can carry more than one group**, up to a limit, and the rules add up: a packet is let
in if any rule of any attached group allows it. That makes groups composable, one for "reachable by
the load balancer", one for "reachable by the monitoring system", and it means removing a rule from
one group does not close a port another group opens.

Because a dropped packet is simply not delivered, a security group never answers. A connection it
blocks does not get "connection refused"; it gets nothing, and the client waits until it gives up.
The last section of this lesson turns that silence into a diagnosis.
