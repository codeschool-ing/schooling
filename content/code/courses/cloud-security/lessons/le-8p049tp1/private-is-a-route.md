---
title: Private is a route, not a name
version: 1
---

**A subnet is public when its route table sends `0.0.0.0/0` to an internet gateway, and private
when it does not. Nothing else decides it.** Not the subnet's name, not the tag somebody gave it,
not the diagram on the wiki. The `cloud` course's lesson 6 built a VPC with both kinds; this section
is about how one turns into the other without anybody meaning it to.

The wrong picture is that "private subnet" is a setting you choose when you create one, the way you
choose its address range. There is no such setting. AWS has no field called *private*; it has route
tables, and a subnet takes the routes of whichever table it is associated with. **And a subnet that
was never associated with any table takes the routes of the VPC's main table**, which is the detail
this section turns on.

## Two subnets, one table each, and a third table nobody looks at

Start moto in the first terminal, empty, and read `env.sh` in both. Then build the clinic's network:
the VPC, a subnet for the web servers, a subnet for the patient records database, and an internet
gateway:

```
ana@laptop:~/aws$ vpc=$(aws ec2 create-vpc --cidr-block 10.20.0.0/16 --query Vpc.VpcId --output text)
ana@laptop:~/aws$ web=$(aws ec2 create-subnet --vpc-id "$vpc" --cidr-block 10.20.1.0/24 --availability-zone sa-east-1a --query Subnet.SubnetId --output text)
ana@laptop:~/aws$ records=$(aws ec2 create-subnet --vpc-id "$vpc" --cidr-block 10.20.2.0/24 --availability-zone sa-east-1a --query Subnet.SubnetId --output text)
ana@laptop:~/aws$ igw=$(aws ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text)
ana@laptop:~/aws$ aws ec2 attach-internet-gateway --vpc-id "$vpc" --internet-gateway-id "$igw"
```

The web subnet gets a table of its own, with the route to the internet in it:

```
ana@laptop:~/aws$ public=$(aws ec2 create-route-table --vpc-id "$vpc" --query RouteTable.RouteTableId --output text)
ana@laptop:~/aws$ aws ec2 create-route --route-table-id "$public" --destination-cidr-block 0.0.0.0/0 --gateway-id "$igw" --query Return
true
ana@laptop:~/aws$ aws ec2 associate-route-table --route-table-id "$public" --subnet-id "$web" --query AssociationState.State --output text
associated
```

Now ask each subnet what its routes are. `association.subnet-id` finds the table a subnet was
explicitly given:

```
ana@laptop:~/aws$ aws ec2 describe-route-tables --filters Name=association.subnet-id,Values="$web" --query "RouteTables[].Routes[].[DestinationCidrBlock,GatewayId]" --output text
10.20.0.0/16	local
0.0.0.0/0	igw-f5bc6d7c25f3d4ffe
ana@laptop:~/aws$ aws ec2 describe-route-tables --filters Name=association.subnet-id,Values="$records" --query "RouteTables[].Routes[].[DestinationCidrBlock,GatewayId]" --output text
```

**The records subnet answers nothing**: nobody associated it with a table. That is not an error and
it is not "no routes". It means the subnet follows the **main route table**, the one AWS creates with
every VPC. Find it, and read it:

```
ana@laptop:~/aws$ main=$(aws ec2 describe-route-tables --filters Name=vpc-id,Values="$vpc" Name=association.main,Values=true --query "RouteTables[0].RouteTableId" --output text)
ana@laptop:~/aws$ aws ec2 describe-route-tables --route-table-ids "$main" --query "RouteTables[].Routes[].[DestinationCidrBlock,GatewayId]" --output text
10.20.0.0/16	local
```

`local` and nothing else. The records subnet can reach the rest of the VPC and nothing beyond it,
which is exactly what a database holding medical records should be able to do. It is private, and it
is private **by inheritance**: nothing about the subnet itself says so.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 400\" role=\"img\" data-fig=\"l08-routes\" aria-label=\"The clinic's VPC, 10.20.0.0/16, with an internet gateway on its edge. The web subnet, 10.20.1.0/24, is associated with its own route table, which sends 0.0.0.0/0 to the internet gateway: it is public. The records subnet, 10.20.2.0/24, has no table of its own, so it follows the VPC's main table, which holds only the local route: it is private by inheritance. A single route added to the main table, 0.0.0.0/0 to the internet gateway, reaches every subnet that follows it, the records subnet included.\"><defs><marker id=\"l08-routes-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l08-routes-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"360.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">the internet</text><rect x=\"300.0\" y=\"34.0\" width=\"120.0\" height=\"32.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">internet gateway</text><rect x=\"20.0\" y=\"82.0\" width=\"680.0\" height=\"304.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"36.0\" y=\"100.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">VPC 10.20.0.0/16</text><rect x=\"48.0\" y=\"290.0\" width=\"260.0\" height=\"72.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"178.0\" y=\"314.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">web subnet</text><text x=\"178.0\" y=\"338.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.1.0/24</text><rect x=\"48.0\" y=\"124.0\" width=\"260.0\" height=\"96.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"64.0\" y=\"144.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">its own table</text><text x=\"64.0\" y=\"170.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10.20.0.0/16  local</text><text x=\"64.0\" y=\"194.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">0.0.0.0/0     igw</text><path d=\"M178.0 288.0 L178.0 222.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-routes-af-ah-paper-dim)\"></path><text x=\"186.0\" y=\"256.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">associated</text><path d=\"M308.0 172.0 L330.0 172.0 L330.0 68.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-routes-af-ah-amber)\"></path><rect x=\"412.0\" y=\"290.0\" width=\"260.0\" height=\"72.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"542.0\" y=\"314.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">records subnet</text><text x=\"542.0\" y=\"338.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10.20.2.0/24</text><rect x=\"412.0\" y=\"124.0\" width=\"260.0\" height=\"96.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"428.0\" y=\"144.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the VPC's main table</text><text x=\"428.0\" y=\"170.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">10.20.0.0/16  local</text><text x=\"428.0\" y=\"194.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">+ 0.0.0.0/0   igw</text><text x=\"600.0\" y=\"194.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">caio's route</text><path d=\"M542.0 288.0 L542.0 222.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l08-routes-af-ah-paper-dim)\"></path><text x=\"550.0\" y=\"241.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">no table of its own:</text><text x=\"550.0\" y=\"254.2\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">follows the main one</text><path d=\"M672.0 172.0 L688.0 172.0 L688.0 50.0 L422.0 50.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l08-routes-af-ah-amber)\"></path></svg>", "caption": "A subnet's privacy is a property of the table it follows. The records subnet was private only because the main table was, and one route added there for something else changed it."}
```

## The subnet that reached the internet

Months later, caio needs a test machine in the VPC to download a package. The machine sits in a
subnet nobody associated either, so it uses the main table, and the quickest fix he finds is to give
the main table the same route the web table has:

```
ana@laptop:~/aws$ aws ec2 create-route --route-table-id "$main" --destination-cidr-block 0.0.0.0/0 --gateway-id "$igw" --query Return
true
ana@laptop:~/aws$ aws ec2 describe-route-tables --route-table-ids "$main" --query "RouteTables[].Routes[].[DestinationCidrBlock,GatewayId]" --output text
10.20.0.0/16	local
0.0.0.0/0	igw-f5bc6d7c25f3d4ffe
```

His download works. **And the records subnet, which he never touched, now has a route to the
internet.** One request, aimed at one test machine, changed the network of every subnet that had no
table of its own. Nothing printed a warning, because nothing was wrong as far as AWS was concerned: a
route was added to a table.

A route is half of exposure. A machine in that subnet still needs a public address, and its security
group still has to let the traffic in; the next two sections are about those. But the half that kept
the database unreachable from the internet whatever else went wrong is gone, and the network's
diagram still says *private*.

## The fix, and the proof

Two changes. Take the route back out of the main table, and give the records subnet **a table of its
own**, so that its privacy is written down rather than inherited from a table everybody shares:

```
ana@laptop:~/aws$ aws ec2 delete-route --route-table-id "$main" --destination-cidr-block 0.0.0.0/0
ana@laptop:~/aws$ private=$(aws ec2 create-route-table --vpc-id "$vpc" --query RouteTable.RouteTableId --output text)
ana@laptop:~/aws$ aws ec2 associate-route-table --route-table-id "$private" --subnet-id "$records" --query AssociationState.State --output text
associated
ana@laptop:~/aws$ aws ec2 describe-route-tables --filters Name=association.subnet-id,Values="$records" --query "RouteTables[].Routes[].[DestinationCidrBlock,GatewayId]" --output text
10.20.0.0/16	local
```

The second half is the one that lasts. **A subnet that matters gets an explicit association**, and
the main table is left with `local` alone, so that the next person who edits it changes only the
subnets nobody has thought about. AWS lets you go further and make a private table the main one; the
principle is the same: the default should be the closed one.

The proof is the question asked at the start, asked again. The routes now come from the records
subnet's own table, and there is no `0.0.0.0/0` among them. The section after next turns that
question into a program that asks it of every subnet at once.
