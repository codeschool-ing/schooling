---
title: Asking every subnet at once
version: 1
---

**The question the first section asked of one subnet — which table do you follow, and does it lead
to an internet gateway? — is a dozen lines of Python, and asked of every subnet it finds what no
diagram shows.** The two failures this lesson has met, a route nobody meant and a port open to
everybody, are both readable from configuration alone. That is how every tool lesson 16 names finds
them, and it is worth writing once yourself so that you know what such a tool can and cannot see.

## One more fault to find

The web servers need a security group, and it gets two inbound rules: HTTPS from everybody, which is
what a public booking site is for, and SSH from everybody, which somebody added to debug a deploy and
never removed:

```
ana@laptop:~/aws$ web_sg=$(aws ec2 create-security-group --group-name clinic-web --description "public booking site" --vpc-id "$vpc" --query GroupId --output text)
ana@laptop:~/aws$ aws ec2 authorize-security-group-ingress --group-id "$web_sg" --protocol tcp --port 443 --cidr 0.0.0.0/0 --query Return
true
ana@laptop:~/aws$ aws ec2 authorize-security-group-ingress --group-id "$web_sg" --protocol tcp --port 22 --cidr 0.0.0.0/0 --query Return
true
```

## The checker

Save this as `exposure.py` in `~/aws`. The copy button takes the program without the notes:

```schooling-example
{"language": "python", "file": "exposure.py", "parts": [{"code": "import boto3\n\nec2 = boto3.client(\"ec2\")\ntables = ec2.describe_route_tables()[\"RouteTables\"]\n", "note": "boto3 is AWS's library for Python. It came with moto into `~/aws/venv`, and it reads the same variables as the command line, so after `source ~/aws/env.sh` it talks to moto. One call fetches every route table in the region."}, {"code": "\nto_internet = set()\nfor table in tables:\n    for route in table[\"Routes\"]:\n        if (route.get(\"DestinationCidrBlock\") == \"0.0.0.0/0\"\n                and route.get(\"GatewayId\", \"\").startswith(\"igw-\")):\n            to_internet.add(table[\"RouteTableId\"])\n", "note": "A table is a way out when it sends `0.0.0.0/0` to an internet gateway. That is the first section's definition of a public subnet, written as a test."}, {"code": "\nexplicit, main = {}, {}\nfor table in tables:\n    for assoc in table[\"Associations\"]:\n        if assoc.get(\"Main\"):\n            main[table[\"VpcId\"]] = table[\"RouteTableId\"]\n        elif \"SubnetId\" in assoc:\n            explicit[assoc[\"SubnetId\"]] = table[\"RouteTableId\"]\n", "note": "Which table each subnet follows: the one it was given, or else its VPC's main table. Leaving out the second half is how a checker misses exactly the subnet caio exposed."}, {"code": "\nfor subnet in ec2.describe_subnets()[\"Subnets\"]:\n    sid = subnet[\"SubnetId\"]\n    table = explicit.get(sid, main.get(subnet[\"VpcId\"]))\n    if table in to_internet:\n        print(f\"ROUTE TO INTERNET  {sid}  {subnet['CidrBlock']}  via {table}\")\n    if subnet[\"MapPublicIpOnLaunch\"]:\n        print(f\"PUBLIC ADDRESSES   {sid}  {subnet['CidrBlock']}  on every new machine\")\n", "note": "Two findings per subnet. A route to the internet is half of exposure; a subnet that hands every new machine a public address is the other half, waiting for its first machine."}, {"code": "\nfor group in ec2.describe_security_groups()[\"SecurityGroups\"]:\n    for rule in group[\"IpPermissions\"]:\n        if any(r[\"CidrIp\"] == \"0.0.0.0/0\" for r in rule.get(\"IpRanges\", [])):\n            ports = \"all\" if rule[\"IpProtocol\"] == \"-1\" else f\"{rule['FromPort']}-{rule['ToPort']}\"\n            print(f\"OPEN TO EVERYONE   {group['GroupId']}  {group['GroupName']}  ports {ports}\")\n", "note": "Inbound rules that admit every address, with their ports. An account with hundreds of groups needs boto3's paginators, since each `describe_` call returns one page; this lab's answers fit in one."}]}
```

Run it with the virtual environment's Python, which `env.sh` already put first on your path:

```
ana@laptop:~/aws$ python3 exposure.py
PUBLIC ADDRESSES   subnet-6f0ef582fb97933ef  172.31.0.0/20  on every new machine
ROUTE TO INTERNET  subnet-dda1142fe1dec00ef  10.20.1.0/24  via rtb-d0bb3440449efd0c5
PUBLIC ADDRESSES   subnet-1977ad43adcf3e034  172.31.16.0/20  on every new machine
PUBLIC ADDRESSES   subnet-9ca48938cc8c8b594  172.31.32.0/20  on every new machine
OPEN TO EVERYONE   sg-34c14ab9253ba3bb0  clinic-web  ports 443-443
OPEN TO EVERYONE   sg-34c14ab9253ba3bb0  clinic-web  ports 22-22
```

Read the lines one at a time, because **a finding is a question, not a verdict**:

- **the web subnet has a route to the internet**, and it should: that is where the booking site
  lives. Intended;
- **the three default subnets hand out public addresses** to every machine launched in them. That is
  the default VPC lesson 1 met, in each of its regions. moto's default VPC has no internet gateway,
  so the checker found no route there; **AWS's default VPC has one**, with the route in its main
  table, and against a real account the same program would print `ROUTE TO INTERNET` for each of
  those subnets too. That difference is moto's, and the claim about AWS is from its documentation;
- **HTTPS open to everybody** on the web group is the site doing its job;
- **SSH open to everybody** is the fault.

Nothing in the output says which is which. The checker can find every place where the network meets
the internet. Only somebody who knows what the clinic meant can say which of those meetings is a
mistake, which is also why lesson 16 spends a section on what happens to a finding after it is
printed.

## Fixing the one that is wrong

Remove the rule and ask again:

```
ana@laptop:~/aws$ aws ec2 revoke-security-group-ingress --group-id "$web_sg" --protocol tcp --port 22 --cidr 0.0.0.0/0 --query Return
true
ana@laptop:~/aws$ python3 exposure.py
PUBLIC ADDRESSES   subnet-6f0ef582fb97933ef  172.31.0.0/20  on every new machine
ROUTE TO INTERNET  subnet-dda1142fe1dec00ef  10.20.1.0/24  via rtb-d0bb3440449efd0c5
PUBLIC ADDRESSES   subnet-1977ad43adcf3e034  172.31.16.0/20  on every new machine
PUBLIC ADDRESSES   subnet-9ca48938cc8c8b594  172.31.32.0/20  on every new machine
OPEN TO EVERYONE   sg-34c14ab9253ba3bb0  clinic-web  ports 443-443
```

The SSH line is gone and the intended ones are still there. Somebody who needs a shell on a web
server gets it through AWS Systems Manager Session Manager, which needs no inbound port at all, or
from one known address; not through a port the whole internet can knock on.

**What the checker cannot see** is just as important as what it found. It reads one region, where
the default VPCs say there are 38. It reads neither network ACLs, nor routes through a NAT gateway or
a peering connection, nor a transit gateway. And it says nothing about whether any packet actually
flowed, which is the next section's subject.
