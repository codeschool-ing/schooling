---
title: A network somebody else owns
version: 2
---

In most companies the network is not the application team's. At the shop, a network team owns the
VPC and its subnets, and they built them with the AWS CLI from a script of their own, long before
Ana wrote any Terraform. This is that script, and in your lab you play the network team: save it
as `~/network-team/create-network.sh` and run it once, now, with `sh create-network.sh` from that
directory, in a terminal that has read `iac-env.sh`. It prints nothing when it works:

```sh
#!/bin/sh
# The shared network, created by the network team with the AWS CLI.
# Ana's configuration does not create these and must not destroy them.
set -e
VPC=$(aws ec2 create-vpc --cidr-block 10.20.0.0/16 \
  --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=shop},{Key=Environment,Value=prod},{Key=Owner,Value=network}]' \
  --query Vpc.VpcId --output text)
aws ec2 create-subnet --vpc-id "$VPC" --cidr-block 10.20.1.0/24 --availability-zone sa-east-1a \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=shop-public-a},{Key=Tier,Value=public}]' > /dev/null
aws ec2 create-subnet --vpc-id "$VPC" --cidr-block 10.20.2.0/24 --availability-zone sa-east-1c \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=shop-public-c},{Key=Tier,Value=public}]' > /dev/null
```

Ana needs a security group inside that VPC, and the tempting answers are both wrong. She could
**copy the VPC id** from the AWS console into her configuration, and it would work until the network
is rebuilt and the id changes, at which point her configuration points at a VPC that no longer
exists. Or she could **write an `aws_vpc` resource** with the same range, and Terraform would create
a second VPC, because a resource block means "make this exist", not "find this".

What she wants is to look it up, the way she would by hand. By hand, she asks AWS for the VPC tagged
`shop` and sees who owns it:

```
ana@laptop:~/shop/app$ aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop --query "Vpcs[].[VpcId,CidrBlock,Tags[?Key==\`Owner\`]|[0].Value]" --output text
vpc-6689436bfc5f4d19d	10.20.0.0/16	network
```

In Terraform the same question is a data source, and the tags are the query. Ana writes it in
`network.tf`, beside `main.tf`:

```hcl
data "aws_vpc" "shop" {
  tags = {
    Name = "shop"
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.shop.id]
  }
  tags = {
    Tier = "public"
  }
}

resource "aws_security_group" "web" {
  name        = "web"
  description = "web servers"
  vpc_id      = data.aws_vpc.shop.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "vpc_cidr" {
  value = data.aws_vpc.shop.cidr_block
}

output "public_subnets" {
  value = length(data.aws_subnets.public.ids)
}
```

`data "aws_vpc"` returns one VPC whose tags match all of those given. `data "aws_subnets"` (plural)
returns the ids of every subnet matching its filters, here the ones in that VPC tagged
`Tier = public`. The security group then refers to `data.aws_vpc.shop.id` exactly as it would refer to
a resource's id, and the plan shows what that bought:

```
ana@laptop:~/shop/app$ terraform plan
data.aws_caller_identity.current: Reading...
data.aws_region.current: Reading...
data.aws_region.current: Read complete after 0s [id=sa-east-1]
data.aws_vpc.shop: Reading...
data.aws_caller_identity.current: Read complete after 0s [id=123456789012]
data.aws_vpc.shop: Read complete after 0s [id=vpc-6689436bfc5f4d19d]
data.aws_subnets.public: Reading...
data.aws_subnets.public: Read complete after 0s [id=sa-east-1]
```
```
      + vpc_id                 = "vpc-6689436bfc5f4d19d"
    }

Plan: 1 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + public_subnets = 2
  + vpc_cidr       = "10.20.0.0/16"
```

The VPC was read during the plan, so its id is **already in the plan**, as a real value where a
resource being created would show `(known after apply)`. The outputs say the range is
`10.20.0.0/16` and that two subnets matched. Nothing in Ana's configuration names an id: the day the
network team rebuilds the VPC with the same tags, her next plan finds the new one.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Two boundaries in one AWS account. On the left, the network team's VPC and two public subnets, made with the AWS CLI and recorded in no Terraform state. On the right, Ana's configuration: its state holds the security group it created, and two data entries that only read the VPC and the subnets across the boundary. A destroy removes what is inside Ana's state and nothing on the left.\"><defs><marker id=\"ow-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"300\" height=\"250\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"35.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">made by the network team, with the CLI</text><rect x=\"50\" y=\"65\" width=\"240\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">VPC</text><text x=\"170.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Name = shop</text><rect x=\"50\" y=\"140\" width=\"110\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">subnet</text><rect x=\"180\" y=\"140\" width=\"110\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"235.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">subnet</text><text x=\"105.0\" y=\"179.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">Tier = public</text><text x=\"235.0\" y=\"179.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">Tier = public</text><text x=\"170.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">in no Terraform state</text><rect x=\"400\" y=\"20\" width=\"300\" height=\"250\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"415.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">Ana's state</text><rect x=\"420\" y=\"65\" width=\"260\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"550.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">data.aws_vpc.shop</text><rect x=\"420\" y=\"140\" width=\"260\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"550.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">data.aws_subnets.public</text><rect x=\"420\" y=\"205\" width=\"260\" height=\"45\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">aws_security_group.web</text><path d=\"M418 90 L292 90\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#ow-ah-phosphor)\"></path><path d=\"M418 165 L292 165\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#ow-ah-phosphor)\"></path><text x=\"360.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">reads</text><text x=\"360.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">reads</text></svg>", "caption": "A data source reads across the boundary and records what it read; only what the configuration created is Terraform's to destroy."}
```

**The boundary also holds in the other direction.** A data source is never destroyed, because
Terraform never created it. After the apply has made the group, `terraform plan -destroy` asks what
a destroy would remove, and it lists exactly one thing:

```
  # aws_security_group.web will be destroyed
  - resource "aws_security_group" "web" {
```
```
Plan: 0 to add, 0 to change, 1 to destroy.
```

One to destroy, and it is the security group. The VPC and its subnets belong to the network team and
stay where they are whatever Ana does with her configuration, which is what makes it safe for the two
teams to share a network at all.

**What she gave up in exchange is a contract.** Her configuration now depends on a tag the network
team chose, and on that tag staying unique. Nothing written down says so, which is why
the last section of this lesson is about the day it stops being true.
