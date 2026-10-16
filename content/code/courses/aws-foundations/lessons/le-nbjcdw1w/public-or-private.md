---
title: More room, IPv6, and what makes a subnet public
version: 1
---

**A VPC can grow after it is created, and a subnet's name decides nothing.** This section adds a
second range to the shop's VPC, gives it IPv6, and then asks which of the nine subnets can reach
the internet. The answer is none of them, the three called `public` included, and the reason is the
whole of lesson 17.

## A second range

A `/16` is the largest primary range, and a VPC that fills it is not stuck: **up to five IPv4
ranges can be associated with one VPC**, a quota AWS raises on request. The common reason is a
platform that hands each machine many addresses, such as Kubernetes giving every pod one. The usual
place to find room is `100.64.0.0/10`, the block set aside for carrier networks, which the rest of
the shop's plan never uses.

```
ana@laptop:~/aws$ aws ec2 associate-vpc-cidr-block --vpc-id $vpc --cidr-block 100.64.0.0/16 --query "CidrBlockAssociation.[CidrBlock,CidrBlockState.State]" --output text
100.64.0.0/16	associating
ana@laptop:~/aws$ aws ec2 describe-route-tables --filters Name=vpc-id,Values=$vpc --query "RouteTables[].Routes[].[DestinationCidrBlock,GatewayId]" --output text
10.20.0.0/16	local
100.64.0.0/16	local
ana@laptop:~/aws$ overlap=$(aws ec2 associate-vpc-cidr-block --vpc-id $vpc --cidr-block 10.20.128.0/17 --query CidrBlockAssociation.AssociationId --output text)
ana@laptop:~/aws$ aws ec2 disassociate-vpc-cidr-block --association-id $overlap --query "CidrBlockAssociation.[CidrBlock,CidrBlockState.State]" --output text
10.20.128.0/17	disassociating
```

**Each range gets a `local` route of its own** in the route table, which is how a packet between
`10.20.x.x` and `100.64.x.x` stays inside the VPC. AWS refuses a second range that overlaps the
first, or a route already in one of the VPC's route tables. It also restricts ranges by family. A
VPC whose primary range is in `10.0.0.0/8` cannot add one from `172.16.0.0/12` or `192.168.0.0/16`.
**moto checks less**, and the last two commands show it. It accepted `10.20.128.0/17`, half of the
VPC's own primary range, which AWS would refuse. That refusal was not run here. The overlapping
range was taken off again with `disassociate-vpc-cidr-block`, so the lab matches what AWS would
hold.

## IPv6, briefly

**An IPv6 range on AWS is public by nature.** AWS gives a VPC a `/56` of globally unique addresses
from its own pool, and each subnet takes a `/64` of it. That is 2⁶⁴ addresses per subnet, so nobody
plans IPv6 subnets by size. There is no private IPv6 range in the sense of `10.0.0.0/8`. A machine
with an IPv6 address has one the whole internet could route to. **What keeps it private is a gateway
that lets connections out and none in**, the egress-only internet gateway of lesson 17.

```
ana@laptop:~/aws$ aws ec2 associate-vpc-cidr-block --vpc-id $vpc --amazon-provided-ipv6-cidr-block --query "Ipv6CidrBlockAssociation.Ipv6Pool" --output text
Amazon
ana@laptop:~/aws$ six=$(aws ec2 describe-vpcs --vpc-ids $vpc --query "Vpcs[0].Ipv6CidrBlockAssociationSet[0].Ipv6CidrBlock" --output text); echo $six
2400:6500:a393:7400::/56
ana@laptop:~/aws$ first=$(python3 -c "import ipaddress, sys; print(next(ipaddress.ip_network(sys.argv[1]).subnets(new_prefix=64)))" $six); echo $first
2400:6500:a393:7400::/64
ana@laptop:~/aws$ pa=$(aws ec2 describe-subnets --filters Name=tag:Name,Values=public-a --query "Subnets[0].SubnetId" --output text)
ana@laptop:~/aws$ aws ec2 associate-subnet-cidr-block --subnet-id $pa --ipv6-cidr-block $first --query "Ipv6CidrBlockAssociation.Ipv6CidrBlockState.State" --output text
associated
```

The `/56` here is moto's invention, from a block that belongs to AWS in the real world, and yours
will differ. The one-line Python program takes the first `/64` of it, the way `plan.py` took the
first `/20`. The subnet `public-a` now has an address in each family. The rest of this course keeps
to IPv4, which is where the shop's addresses and the price list's lines are.

## Public is a route, not a setting

This is the idea the lesson is built towards, and it is the one most often wrong. **A subnet is
public when its route table sends `0.0.0.0/0` to an internet gateway.** Nothing else makes it
public: not its name, not a tag, not the `MapPublicIpOnLaunch` flag that the default VPC's subnets
carry. That flag gives a machine a public address when it starts, and **an address with no route to
the internet goes nowhere**. It is a return label on a letter nobody posts.

So the question "is this subnet public?" is answered by reading its route table:

```
ana@laptop:~/aws$ aws ec2 describe-route-tables --filters Name=vpc-id,Values=$vpc --query "RouteTables[].[RouteTableId,Associations[0].Main]" --output text
rtb-8d2d42a15ed11e3a3	True
ana@laptop:~/aws$ aws ec2 describe-route-tables --filters Name=association.subnet-id,Values=$pa --query "RouteTables[].RouteTableId"
[]
ana@laptop:~/aws$ aws ec2 describe-route-tables --filters Name=vpc-id,Values=$vpc --query "RouteTables[0].Routes[].[DestinationCidrBlock || DestinationIpv6CidrBlock,GatewayId]" --output text
10.20.0.0/16	local
100.64.0.0/16	local
2400:6500:a393:7400::/56	local
```

The VPC has **one route table, the main one**, and the second command finds no table associated
with `public-a` at all. Both are expected. A subnet with no association of its own uses the main
table, **implicitly**, so a search for an explicit association answers with an empty list. And the
main table's routes are only the `local` ones, one for each range, IPv4 and IPv6: everything inside
the VPC, nothing outside it.

**All nine subnets are therefore private**, `public-a`, `public-b` and `public-c` included. The
names say what they are for. The routes say what they are, and right now the routes say the same
thing for all nine.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 470\" role=\"img\" data-fig=\"l16-shop-vpc\" aria-label=\"The shop's production VPC, shop-prod, 10.20.0.0/16, inside the region sa-east-1. It spans three Availability Zones, sa-east-1a, b and c, whose zone ids are sae1-az1, az2 and az3. Each zone holds three subnets, one per tier: public, app and data. Zone a has public-a 10.20.0.0/20, app-a 10.20.48.0/20 and data-a 10.20.96.0/20; zone b has public-b 10.20.16.0/20, app-b 10.20.64.0/20 and data-b 10.20.112.0/20; zone c has public-c 10.20.32.0/20, app-c 10.20.80.0/20 and data-c 10.20.128.0/20. Below them, the main route table, which all nine use for now, holds one route: 10.20.0.0/16 to local. The public tier is drawn with an amber edge because lesson 17 makes it public; today its route table is the same as everybody else's.\"><rect x=\"16.0\" y=\"16.0\" width=\"688.0\" height=\"404.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"32.0\" y=\"34.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">sa-east-1</text><rect x=\"36.0\" y=\"48.0\" width=\"648.0\" height=\"356.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></rect><text x=\"52.0\" y=\"66.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">shop-prod  10.20.0.0/16</text><rect x=\"56.0\" y=\"82.0\" width=\"192.0\" height=\"222.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"152.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">sa-east-1a</text><text x=\"152.0\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sae1-az1</text><rect x=\"70.0\" y=\"126.0\" width=\"164.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"152.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">public-a</text><text x=\"152.0\" y=\"159.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.0.0/20</text><rect x=\"70.0\" y=\"184.0\" width=\"164.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"152.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">app-a</text><text x=\"152.0\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.48.0/20</text><rect x=\"70.0\" y=\"242.0\" width=\"164.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"152.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">data-a</text><text x=\"152.0\" y=\"275.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.96.0/20</text><rect x=\"262.0\" y=\"82.0\" width=\"192.0\" height=\"222.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"358.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">sa-east-1b</text><text x=\"358.0\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sae1-az2</text><rect x=\"276.0\" y=\"126.0\" width=\"164.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"358.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">public-b</text><text x=\"358.0\" y=\"159.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.16.0/20</text><rect x=\"276.0\" y=\"184.0\" width=\"164.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"358.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">app-b</text><text x=\"358.0\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.64.0/20</text><rect x=\"276.0\" y=\"242.0\" width=\"164.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"358.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">data-b</text><text x=\"358.0\" y=\"275.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.112.0/20</text><rect x=\"468.0\" y=\"82.0\" width=\"192.0\" height=\"222.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"564.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">sa-east-1c</text><text x=\"564.0\" y=\"113.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sae1-az3</text><rect x=\"482.0\" y=\"126.0\" width=\"164.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"564.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">public-c</text><text x=\"564.0\" y=\"159.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.32.0/20</text><rect x=\"482.0\" y=\"184.0\" width=\"164.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"564.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">app-c</text><text x=\"564.0\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.80.0/20</text><rect x=\"482.0\" y=\"242.0\" width=\"164.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"564.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">data-c</text><text x=\"564.0\" y=\"275.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10.20.128.0/20</text><rect x=\"56.0\" y=\"320.0\" width=\"604.0\" height=\"66.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"358.0\" y=\"340.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">main route table, used by all nine until lesson 17</text><text x=\"358.0\" y=\"364.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">10.20.0.0/16  →  local</text><rect x=\"140.0\" y=\"436.0\" width=\"22.0\" height=\"14.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"170.0\" y=\"443.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">public tier, once lesson 17 routes it</text><rect x=\"430.0\" y=\"436.0\" width=\"22.0\" height=\"14.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"443.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">private tiers</text></svg>", "caption": "Nine subnets, three to a zone. Their names say what they are for; for now one route table says the same thing to all of them."}
```

Lesson 17 turns three of them public. It attaches an internet gateway and gives those three a route
table of their own that points `0.0.0.0/0` at it. The other six stay private, and they reach the
internet, when they must, through a NAT gateway placed in a public subnet. Two different route
tables, nine identical subnets: **public and private are a property of the route table.** A subnet
becomes one or the other by being associated with it.

## Starting the next lessons from here

moto forgets everything when it stops. Lessons 17 to 20 start from an empty moto and rebuild this
lesson's VPC and subnets with `bash net/16-vpc.sh`. That is why the script creates the VPC when
there is none. The second range and the IPv6 addresses are not in it, because none of lessons 17 to
20 needs them.
