---
title: Route tables, and the gateway that makes a subnet public
version: 1
---

**A route table is a list of destinations, each with a target, and every subnet uses exactly one.**
When a machine sends a packet, the VPC router reads the table of the machine's subnet. It finds the
route whose destination contains the packet's address, and hands the packet to that route's target.
Lesson 16 ended with nine subnets and one table that knew only the VPC itself. This lesson gives the
shop three kinds of way out, and each of them is a line in a table.

The wrong picture is a router you configure once for the whole VPC. **There are as many routing
decisions as there are route tables.** Two machines in two subnets of one VPC can send the same
packet to two different places, because their subnets use different tables.

## Starting from lesson 16

Restart moto in the first terminal (Ctrl+C, then `moto_server -p 4567`) so this lesson starts from
an empty AWS, and rebuild lesson 16's VPC with the script it left in `~/aws/net`. The ids moto
invents will differ from the ones printed here.

```
ana@laptop:~/aws$ bash net/16-vpc.sh
public-a	10.20.0.0/20	sae1-az1	4091
public-b	10.20.16.0/20	sae1-az2	4091
public-c	10.20.32.0/20	sae1-az3	4091
app-a	10.20.48.0/20	sae1-az1	4091
app-b	10.20.64.0/20	sae1-az2	4091
app-c	10.20.80.0/20	sae1-az3	4091
data-a	10.20.96.0/20	sae1-az1	4091
data-b	10.20.112.0/20	sae1-az2	4091
data-c	10.20.128.0/20	sae1-az3	4091
ana@laptop:~/aws$ vpc=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop-prod --query "Vpcs[0].VpcId" --output text)
ana@laptop:~/aws$ aws ec2 describe-route-tables --filters Name=vpc-id,Values=$vpc --query "RouteTables[].Routes[]"
[
    {
        "DestinationCidrBlock": "10.20.0.0/16",
        "GatewayId": "local",
        "Origin": "CreateRouteTable",
        "State": "active"
    }
]
```

The second command keeps the VPC's id in `vpc`, as lesson 16 did, and the third prints the one table
the VPC has. **The `local` route is the VPC's own range**: any packet for an address inside
`10.20.0.0/16` stays inside the VPC, whichever subnet it is for. AWS puts it in every table, and it
cannot be deleted. That is why two machines in the VPC always reach each other, as far as routing
goes. Whether the packet is then allowed in is lesson 18's question.

## The main table, and the ones you make

**The main route table is the one a subnet uses when nobody gave it another.** Lesson 16 found all
nine subnets using it implicitly. That makes it the table for every subnet created in a hurry. The
safe habit is to **leave the main table private, and give each subnet that needs more an explicit
table of its own**. A subnet added next year without thought then lands somewhere closed.

A table belongs to one VPC and can serve many subnets, and a subnet is associated with one table at
a time. Moving a subnet to another table is `replace-route-table-association`, and it takes effect
for the next packet. That is also why a wrong association is an outage that starts at once.

## An internet gateway

**An internet gateway is the VPC's door to the internet**: a target a route can name, attached to
one VPC. AWS runs it across every zone of the region, so it has no zone of its own to lose. It also
translates between a machine's private address and the public address the internet sees. That is why
a machine behind it needs a public address of its own. It costs nothing by the hour. What it carries
is billed as data transfer, at the prices lesson 1 read.

```
ana@laptop:~/aws$ igw=$(aws ec2 create-internet-gateway --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=shop-prod}]' --query InternetGateway.InternetGatewayId --output text)
ana@laptop:~/aws$ aws ec2 attach-internet-gateway --internet-gateway-id $igw --vpc-id $vpc
ana@laptop:~/aws$ aws ec2 describe-internet-gateways --internet-gateway-ids $igw --query "InternetGateways[0].Attachments[].[VpcId,State]" --output text
vpc-4d9b138dab1e13c0a	available
ana@laptop:~/aws$ aws ec2 attach-internet-gateway --internet-gateway-id $igw --vpc-id $(aws ec2 describe-vpcs --filters Name=is-default,Values=true --query "Vpcs[0].VpcId" --output text)

aws: [ERROR]: An error occurred (Resource.AlreadyAssociated) when calling the AttachInternetGateway operation: Resource igw-7678c2ce06f59ad39 is already associated.
```

**A gateway attaches to one VPC at a time.** Asked to attach this one to the default VPC as well,
moto refused with `Resource.AlreadyAssociated`, as AWS does. The rule runs the other way too, one
internet gateway per VPC, and AWS refuses a second. That refusal was not run here.

## The public route table

Attaching the gateway changed nothing yet, which is the point of lesson 16: no table sends anything
to it. **A subnet becomes public the moment its table has a route for `0.0.0.0/0` to the internet
gateway.** So the shop makes one table for that and associates the three public subnets with it:

```
ana@laptop:~/aws$ pub=$(aws ec2 create-route-table --vpc-id $vpc --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=public}]' --query RouteTable.RouteTableId --output text)
ana@laptop:~/aws$ aws ec2 create-route --route-table-id $pub --destination-cidr-block 0.0.0.0/0 --gateway-id $igw
{
    "Return": true
}
ana@laptop:~/aws$ for z in a b c; do aws ec2 associate-route-table --route-table-id $pub --subnet-id $(aws ec2 describe-subnets --filters Name=tag:Name,Values=public-$z --query "Subnets[0].SubnetId" --output text) --query AssociationState.State --output text; done
associated
associated
associated
ana@laptop:~/aws$ aws ec2 describe-route-tables --route-table-ids $pub --query "RouteTables[0].Routes[].[DestinationCidrBlock,GatewayId]" --output text
10.20.0.0/16	local
0.0.0.0/0	igw-7678c2ce06f59ad39
ana@laptop:~/aws$ pa=$(aws ec2 describe-subnets --filters Name=tag:Name,Values=public-a --query "Subnets[0].SubnetId" --output text)
ana@laptop:~/aws$ aws ec2 describe-route-tables --filters Name=association.subnet-id,Values=$pa --query "RouteTables[].Tags[?Key==\`Name\`].Value[]" --output text
public
```

**`0.0.0.0/0` is every IPv4 address**, the shortest prefix there is, so it is the route a packet
takes when nothing more specific matches. In the `public` table that means: inside the VPC, `local`;
anywhere else, out through the gateway. `public-a`, `public-b` and `public-c` are now public, and
the filter that answered `[]` in lesson 16 finds their table.

**The other six subnets are still private**, and they cannot simply use the same table. A machine in
`app-a` has no public address, so the internet gateway would have nothing to translate its address
into. And a database in `data-a` should not be one route away from the internet in any case. The
next section gives them a way out that works in one direction only.

## What moto does not do here

**moto routes nothing.** It stores every table, every route and every association exactly as AWS
returns them, and no packet ever moves through any of them. There are no machines to send one and no
network behind the records. Everything this lesson says about where a packet goes is read off the
tables, the way you would read a map. The figure in the next section walks three packets through
them by hand. On AWS, the place to check a path for real is VPC Reachability Analyzer, which lesson
18 names alongside the other tools that watch traffic.
