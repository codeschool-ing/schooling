---
title: Network ACLs, stateless and attached to the subnet
version: 1
---

**A network ACL is a numbered list of allow and deny rules at the edge of a subnet, read in order
until one matches.** It checks every packet that enters or leaves the subnet, and it remembers
nothing. A reply is a new packet like any other, and it has to be allowed on its own. That one
property, **stateless**, is where nearly every mistake with network ACLs comes from.

| | security group | network ACL |
|---|---|---|
| attached to | a network interface | a subnet |
| rules | allow only | allow and deny |
| evaluated | all rules together | by number, lowest first, first match decides |
| replies | allowed by themselves (stateful) | need a rule of their own (stateless) |
| a new one | denies all inbound, allows all outbound | denies everything both ways |

## The default network ACL

The default network ACL that came with the VPC is associated with all nine subnets, and it lets
everything through in both directions:

```
ana@laptop:~/aws$ aws ec2 describe-network-acls --filters Name=vpc-id,Values=$vpc Name=default,Values=true --query "NetworkAcls[0].Entries[].[Egress,RuleNumber,Protocol,CidrBlock,RuleAction]" --output text
True	100	-1	0.0.0.0/0	allow
True	32767	-1	0.0.0.0/0	deny
False	100	-1	0.0.0.0/0	allow
False	32767	-1	0.0.0.0/0	deny
```

Two rules each way. **Rule 100 allows every protocol (`-1`) from everywhere.** The rule numbered
`32767` is the one the console shows as `*`. It is the last rule of every network ACL, it denies
whatever no other rule matched, and it cannot be removed. Under the default network ACL it never
fires, since rule 100 matches first.

That is why most VPCs run on the default network ACL and filter with security groups alone. It is a
reasonable place to stand. **A network ACL earns its place when a subnet needs a deny**, or when a
team wants a second, coarser filter that one wrong security group cannot open.

## A network ACL for the public tier

The shop's public subnets face the internet, and one address, `198.51.100.7`, has been hammering the
checkout. A security group cannot refuse one address, and a network ACL can. A new network ACL in
AWS starts with only the two `*` rules, so it denies everything until somebody adds rules. **moto's
starts with no rules at all**, as the second command shows. The rules below make the difference
irrelevant, since the shop writes every rule it relies on.

```
ana@laptop:~/aws$ acl=$(aws ec2 create-network-acl --vpc-id $vpc --tag-specifications 'ResourceType=network-acl,Tags=[{Key=Name,Value=public}]' --query NetworkAcl.NetworkAclId --output text)
ana@laptop:~/aws$ aws ec2 describe-network-acls --network-acl-ids $acl --query "NetworkAcls[0].Entries"
[]
ana@laptop:~/aws$ aws ec2 create-network-acl-entry --network-acl-id $acl --ingress --rule-number 90 --protocol -1 --cidr-block 198.51.100.7/32 --rule-action deny
ana@laptop:~/aws$ aws ec2 create-network-acl-entry --network-acl-id $acl --ingress --rule-number 100 --protocol tcp --port-range From=443,To=443 --cidr-block 0.0.0.0/0 --rule-action allow
ana@laptop:~/aws$ aws ec2 create-network-acl-entry --network-acl-id $acl --ingress --rule-number 110 --protocol tcp --port-range From=1024,To=65535 --cidr-block 0.0.0.0/0 --rule-action allow
ana@laptop:~/aws$ aws ec2 create-network-acl-entry --network-acl-id $acl --ingress --rule-number 120 --protocol -1 --cidr-block 10.20.0.0/16 --rule-action allow
ana@laptop:~/aws$ aws ec2 create-network-acl-entry --network-acl-id $acl --egress --rule-number 100 --protocol tcp --port-range From=1024,To=65535 --cidr-block 0.0.0.0/0 --rule-action allow
ana@laptop:~/aws$ aws ec2 create-network-acl-entry --network-acl-id $acl --egress --rule-number 110 --protocol tcp --port-range From=443,To=443 --cidr-block 0.0.0.0/0 --rule-action allow
ana@laptop:~/aws$ aws ec2 create-network-acl-entry --network-acl-id $acl --egress --rule-number 120 --protocol -1 --cidr-block 10.20.0.0/16 --rule-action allow
```

**Rule 90 comes before rule 100 on purpose.** Rules are read lowest first and the first match
decides. So the deny for `198.51.100.7` has to come before the allow for port 443, which would
otherwise match that address too and let it in. Numbering in steps of ten leaves room to slip a
rule in later without renumbering everything.

## Return traffic, and the ephemeral ports

Rule 110 inbound and rule 100 outbound are the stateless part. A customer's browser connects
**from** a port its own system picked, somewhere in the high range, **to** port 443. The reply goes
back to that high port, and the network ACL, which remembers nothing, has to allow it as an outbound
packet in its own right. These client ports are called **ephemeral**. The range differs between
systems: Linux picks from 32768 to 60999, others from lower. So AWS's documentation recommends
allowing **1024 to 65535**.

The same happens the other way. The NAT gateway in a public subnet opens connections out to the
payment provider on 443, which rule 110 outbound allows. The replies arrive at a high port, which is
what rule 110 inbound is for. Rule 120 each way lets the public subnets talk to the rest of the VPC,
where the security groups do the fine work.

## Putting it on the subnets

A subnet is associated with exactly one network ACL. Moving a subnet onto the new one means
replacing its current association, which it has with the default:

```
ana@laptop:~/aws$ for z in a b c; do s=$(aws ec2 describe-subnets --filters Name=tag:Name,Values=public-$z --query "Subnets[0].SubnetId" --output text); a=$(aws ec2 describe-network-acls --filters Name=association.subnet-id,Values=$s --query "NetworkAcls[0].Associations[?SubnetId=='$s'].NetworkAclAssociationId" --output text); aws ec2 replace-network-acl-association --association-id $a --network-acl-id $acl --query NewAssociationId --output text; done
aclassoc-addac5f73498b5330
aclassoc-d7893beb113e2fe70
aclassoc-18a17f112a84b508d
ana@laptop:~/aws$ aws ec2 describe-network-acls --network-acl-ids $acl --query "sort_by(NetworkAcls[0].Entries,&RuleNumber)[].[Egress,RuleNumber,Protocol,PortRange.From,PortRange.To,CidrBlock,RuleAction]" --output text
False	90	-1	None	None	198.51.100.7/32	deny
False	100	6	443	443	0.0.0.0/0	allow
True	100	6	1024	65535	0.0.0.0/0	allow
False	110	6	1024	65535	0.0.0.0/0	allow
True	110	6	443	443	0.0.0.0/0	allow
False	120	-1	None	None	10.20.0.0/16	allow
True	120	-1	None	None	10.20.0.0/16	allow
```

The three public subnets now answer to `public`. The six private ones stay on the default, which
lets everything through and leaves the filtering to their security groups. The last command reads
the rules back by number. `False` is inbound and `True` outbound, TCP appears as its protocol
number, `6`, and the deny comes first.
