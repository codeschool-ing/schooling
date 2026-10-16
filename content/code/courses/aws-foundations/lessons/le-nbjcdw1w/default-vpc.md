---
title: The default VPC, and the one the shop builds instead
version: 1
---

**A VPC is a range of private addresses that belongs to one account in one region**, and every
machine, database and load balancer that AWS gives an address to sits inside one. The name stands
for virtual private cloud. It is not a cable or a switch; it is a record that says which addresses
exist, which zones they live in, and where a packet addressed to each of them may go.

The common wrong picture is that a VPC is something you have to build before anything else works.
**Every account already has one in every region**, made by AWS when the account was opened: the
default VPC. Most people's first machine lands there without their ever having heard the word.

## Looking at the default VPC

Restart moto in the first terminal (Ctrl+C, then `moto_server -p 4567`) so this lesson starts from
an empty AWS. An empty moto still has a default VPC in `sa-east-1`, because AWS's accounts do:

```
ana@laptop:~/aws$ aws ec2 describe-vpcs --query "Vpcs[].[VpcId,CidrBlock,IsDefault]" --output text
vpc-fcbbbe17385be3d51	172.31.0.0/16	True
ana@laptop:~/aws$ aws ec2 describe-subnets --query "Subnets[].[AvailabilityZone,CidrBlock,AvailableIpAddressCount,DefaultForAz,MapPublicIpOnLaunch]" --output text
sa-east-1a	172.31.0.0/20	4091	True	True
sa-east-1b	172.31.16.0/20	4091	True	True
sa-east-1c	172.31.32.0/20	4091	True	True
ana@laptop:~/aws$ aws ec2 describe-internet-gateways --query "InternetGateways[].InternetGatewayId"
[]
```

Three things in that answer are worth reading. **The range is `172.31.0.0/16`**, 65,536
addresses, and it is the same range in every default VPC of every account: each account the
organisation of lesson 3 opens gets a default VPC of its own, and each says `172.31.0.0/16`. **There
is one subnet per zone**, a `/20` of 4,096 addresses with 4,091 usable, which the next section
explains. And **`MapPublicIpOnLaunch` is `True`** in all three: a machine launched there gets a
public address without being asked.

The fourth thing is the empty list at the end, and there moto and AWS part ways. **In AWS the
default VPC has an internet gateway attached**, and its main route table sends `0.0.0.0/0` to it,
so every default subnet is open to the internet from the first minute. moto creates neither, so its
default VPC is less exposed than the real one. That part was not run here; it is AWS's documented
behaviour, and lesson 17 builds the same arrangement by hand so you can see each piece.

## Why production does not live there

The default VPC exists so that somebody trying AWS for an afternoon can launch a machine and reach
it. That is its whole job, and three of its properties work against a shop that will run for years:

- **Its range collides with every other account's.** Two VPCs whose ranges overlap cannot be
  connected to each other, which lesson 20 shows moto accepting and AWS refusing. The shop has a
  staging account and an office network to join to production; six accounts all saying
  `172.31.0.0/16` can never be joined at all.
- **Every subnet in it is public.** A database launched there without a second thought gets a
  public address and a route to the internet. The safe arrangement has to be built; the default
  hands you the unsafe one.
- **Nobody chose it.** It has no tiers, no room set aside, and no tags saying whose it is. Whatever
  somebody creates without naming a VPC lands in it, so it collects the accidents.

So the default VPC is left alone, or deleted, and the shop's production network is a VPC of its
own. Many organisations delete the default VPC in every region of every account, so that nothing can
land there by accident.

## Choosing a range, and creating the VPC

A VPC's range is written in **CIDR notation**: an address, a slash and the number of leading bits
that are fixed. `10.20.0.0/16` fixes the first 16 bits, `10.20`, and leaves 16 bits free, so it
holds 2¹⁶ = 65,536 addresses, from `10.20.0.0` to `10.20.255.255`. AWS takes a primary range
between `/16`, the largest, and `/28`, sixteen addresses.

The range should come from the private blocks of RFC 1918 (`10.0.0.0/8`, `172.16.0.0/12` and
`192.168.0.0/16`), and it should be **chosen against every other network it may ever meet**,
because a range cannot be changed once a VPC has it. The shop's plan is written down in one place:

| network | range |
|---|---|
| production, account `shop-prod` | `10.20.0.0/16` |
| staging, account `shop-staging` | `10.30.0.0/16` |
| the office and its datacentre | `192.168.0.0/16` |

None overlaps another, and each VPC takes the largest range AWS allows. Private addresses cost
nothing, and a VPC that runs out of room is a migration, so there is no saving in a small one.

Creating it is one command, and the tags say what it is and whose:

```
ana@laptop:~/aws$ vpc=$(aws ec2 create-vpc --cidr-block 10.20.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=shop-prod},{Key=project,Value=shop},{Key=env,Value=prod}]' --query Vpc.VpcId --output text)
ana@laptop:~/aws$ echo $vpc
vpc-ea674f1598f0aca72
ana@laptop:~/aws$ aws ec2 describe-route-tables --filters Name=vpc-id,Values=$vpc --query "length(RouteTables)"
1
ana@laptop:~/aws$ aws ec2 describe-security-groups --filters Name=vpc-id,Values=$vpc --query "SecurityGroups[].GroupName" --output text
default
ana@laptop:~/aws$ aws ec2 describe-network-acls --filters Name=vpc-id,Values=$vpc --query "NetworkAcls[].IsDefault" --output text
True
```

The first line keeps the new VPC's id in a shell variable, `vpc`, which the rest of this lesson's
commands use; the id in your terminal will differ from the one printed here, because moto invents
its ids. **A VPC is created with three things already inside it**: a main route table, a default
security group and a default network ACL, each counted by one of the last three commands. Lesson
17 is about the first and lesson 18 about the other two. **It has no subnets yet**, and a VPC with
no subnets can hold nothing, because every address AWS hands out comes from a subnet.

The range sits inside the limits AWS sets, and moto holds the same limits at both ends:

```
ana@laptop:~/aws$ aws ec2 create-vpc --cidr-block 10.0.0.0/8

aws: [ERROR]: An error occurred (InvalidVpc.Range) when calling the CreateVpc operation: The CIDR '10.0.0.0/8' is invalid.
ana@laptop:~/aws$ aws ec2 create-vpc --cidr-block 10.0.0.0/29

aws: [ERROR]: An error occurred (InvalidVpc.Range) when calling the CreateVpc operation: The CIDR '10.0.0.0/29' is invalid.
```

**A `/8` is too large and a `/29` too small**, whatever range they start from. The next section
cuts the shop's `/16` into the pieces machines actually live in.
