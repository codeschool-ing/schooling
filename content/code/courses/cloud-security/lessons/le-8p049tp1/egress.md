---
title: Egress: the direction nobody filters
version: 1
---

**Every security group AWS creates allows all outbound traffic to anywhere, until somebody removes
the rule.** Inbound rules get reviewed, argued about and written narrowly. Outbound rules are rarely
read at all, and that is the direction data leaves in.

The wrong idea is that a server nobody can reach from the internet cannot send anything to it. A
private subnet with a NAT gateway, which is how most private subnets get their software updates, can
open a connection to any address on the internet. **NAT lets connections out and not in; it says
nothing about what goes out.** A process on the records database that has been made to misbehave,
through a vulnerable library or a stolen credential, can upload the table it holds to any server
that will take it, and the database's inbound rules never see it.

## What a new security group allows

Create the database's security group in the clinic's VPC, and read its outbound rules before writing
anything:

```
ana@laptop:~/aws$ db=$(aws ec2 create-security-group --group-name records-db --description "patient records database" --vpc-id "$vpc" --query GroupId --output text)
ana@laptop:~/aws$ aws ec2 describe-security-groups --group-ids "$db" --query "SecurityGroups[0].IpPermissionsEgress[].[IpProtocol,IpRanges[0].CidrIp]" --output text
-1	0.0.0.0/0
```

**Protocol `-1` is every protocol, and `0.0.0.0/0` is every address.** Nobody wrote that rule; it
came with the group. The inbound side starts empty, so the database's one legitimate client gets a
rule naming its port and the web subnet's range, and nothing wider:

```
ana@laptop:~/aws$ aws ec2 authorize-security-group-ingress --group-id "$db" --protocol tcp --port 5432 --cidr 10.20.1.0/24 --query Return
true
```

## Closing the outbound side

A database answers queries; it does not start conversations with the internet. So its outbound rule
can be the VPC and nothing else. Security groups are **stateful**: the reply to a query the web
servers sent is let back out whatever the outbound rules say, so narrowing them breaks no answer.
Remove the rule that came with the group, and write the one that should have been there:

```
ana@laptop:~/aws$ aws ec2 revoke-security-group-egress --group-id "$db" --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=0.0.0.0/0}]" --query Return
true
ana@laptop:~/aws$ aws ec2 authorize-security-group-egress --group-id "$db" --ip-permissions "IpProtocol=-1,IpRanges=[{CidrIp=10.20.0.0/16}]" --query Return
true
ana@laptop:~/aws$ aws ec2 describe-security-groups --group-ids "$db" --query "SecurityGroups[0].IpPermissionsEgress[].[IpProtocol,IpRanges[0].CidrIp]" --output text
-1	10.20.0.0/16
```

Now a process on the database that tries to reach an address outside `10.20.0.0/16` gets no
connection, whatever route its subnet has. That is the point of having two controls: **the route
table decides where traffic can go, the security group decides what this machine may send**, and
the database is now private by both.

moto stores these rules and carries no traffic, so the lab can show the rules and not a connection
being refused. What the rules do with real packets is AWS's documented behaviour, not a run.

## When a machine really needs the internet

Some do: a server that fetches updates, or calls a payment provider. An outbound rule can only name
addresses, and the services worth reaching live behind addresses that change. The documented
options, none of them run here:

| control | what it filters on | what it costs |
|---|---|---|
| a security group or network ACL | address ranges and ports | free; useless against a destination that changes its addresses |
| a proxy the machines must go through | the host name asked for, and it can log every request | a server to run and keep up |
| AWS Network Firewall, Azure Firewall, Google Cloud's Cloud NGFW | host names and domain lists, inspected in the network | billed per hour and per gigabyte |
| DNS filtering, such as Route 53 Resolver DNS Firewall | which names the machines may resolve | cheap, and a name never resolved is a connection never made |

**An allow list of the few destinations a workload needs is the strong version**; a block list of
known bad ones is the weak one, because nobody's list contains the server a thief set up yesterday.
For the records database the list is empty, and that is the easiest case there is.
