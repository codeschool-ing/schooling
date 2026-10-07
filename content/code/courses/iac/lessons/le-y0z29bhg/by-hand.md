---
title: A network built by hand
version: 1
---

Nothing in this lesson asks you to type. Its transcripts are Ana's and are there to be read, and
its last four sections build the lab you will type in from lesson 2 on.

Ana runs the infrastructure of a small online shop. The first time she needed a network for it, she
did what almost everybody does the first time: she typed it. A virtual network (a **VPC**), one
subnet inside it, and a **security group**, the firewall AWS puts in front of a machine, letting the
web's port 443 in. She was careful enough to keep the commands in a file, so this is better than
clicking through a console:

```sh
#!/bin/sh
# The shop's network, as ana built it the first time.
set -e
VPC=$(aws ec2 create-vpc --cidr-block 10.20.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=shop}]' \
  --query Vpc.VpcId --output text)
SUBNET=$(aws ec2 create-subnet --vpc-id "$VPC" --cidr-block 10.20.1.0/24 \
  --availability-zone sa-east-1a --query Subnet.SubnetId --output text)
SG=$(aws ec2 create-security-group --vpc-id "$VPC" --group-name web \
  --description "web servers" --query GroupId --output text)
aws ec2 authorize-security-group-ingress --group-id "$SG" \
  --protocol tcp --port 443 --cidr 0.0.0.0/0 > /dev/null
echo "created $VPC, $SUBNET and $SG"
```

Each line asks AWS to **do** something: create, create, create, authorise. The ids it prints are the
ones AWS invented for what it made, and the script passes each one to the next command, because a
subnet has to know which VPC it belongs to. It ran once, and it worked:

```
ana@laptop:~/shop$ sh network.sh
created vpc-1dc5b2f02877661dd, subnet-47eb63b5982b1e4ad and sg-c4adfe0f7369e2179
ana@laptop:~/shop$ aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop --query "Vpcs[].[VpcId,CidrBlock]" --output text
vpc-1dc5b2f02877661dd	10.20.0.0/16
```

That is a network, and for an afternoon it is a perfectly good one. **The trouble starts the day
after**, and it is the same trouble whether the commands were typed, clicked or kept in a script
like this one. Three questions have no good answer:

- **What should exist?** The script says what was *done* on the day it ran. If anybody changed the
  network afterwards, the script does not know.
- **What does exist?** The only way to find out is to ask AWS, resource by resource, and compare by
  eye.
- **What happens if I run it again?** Nothing in the script says. Three sections on, you will see
  that the answer is "a second network".

A setup that exists only as the result of a sequence of commands has a name in this trade: a
**snowflake**. Every one is slightly different, nobody knows exactly how, and the day it has to be
rebuilt (a new region, a disaster, a copy for testing) is the day somebody discovers which steps
were never written down.

This course is about the alternative. **Infrastructure as code** means the network, the machines,
the buckets and what runs on them are described in files, the files are kept in version control,
and a program makes the real world match them. The rest of this lesson says which jobs that
alternative has to do. Lesson 2 writes the first description in Terraform.
