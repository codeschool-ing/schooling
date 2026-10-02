---
title: No match, two matches, and an empty list
version: 1
---

A resource block that fails stops at the apply. **A data source that fails stops the plan**, and the
whole plan with it, because nothing that refers to the answer can be worked out without one. There
are three ways a lookup can go wrong, and only two of them make any noise.

**No match.** The VPC Ana asked for does not exist, because its tag is `shop` and not `shop-prod`. A
second directory, `~/shop/probe`, holds small configurations for trying this out, and the first asks
for the wrong name:

```hcl
provider "aws" {
  region = "sa-east-1"
}

data "aws_vpc" "prod" {
  tags = {
    Name = "shop-prod"
  }
}
```

```
ana@laptop:~/shop/probe$ terraform plan
data.aws_vpc.prod: Reading...

Planning failed. Terraform encountered an error while generating this plan.

╷
│ Error: no matching EC2 VPC found
│ 
│   with data.aws_vpc.prod,
│   on main.tf line 5, in data "aws_vpc" "prod":
│    5: data "aws_vpc" "prod" {
│ 
╵
```

**Two matches, for a data source that returns one.** A singular data source (`aws_vpc`, `aws_ami`,
`aws_subnet`) must find exactly one thing, and refuses to choose between two. Ask for every
`shop-web-*` image without `most_recent`, now that the image team has published two:

```hcl
provider "aws" {
  region = "sa-east-1"
}

data "aws_ami" "web" {
  owners = ["self"]

  filter {
    name   = "name"
    values = ["shop-web-*"]
  }
}
```

```
ana@laptop:~/shop/probe$ terraform plan
data.aws_ami.web: Reading...

Planning failed. Terraform encountered an error while generating this plan.

╷
│ Error: Your query returned more than one result. Please try a more specific search criteria, or set `most_recent` attribute to true.
│ 
│   with data.aws_ami.web,
│   on main.tf line 5, in data "aws_ami" "web":
│    5: data "aws_ami" "web" {
│ 
╵
```

The error is the useful outcome. A lookup that picked one of two at random would deploy something
different on different days, and nobody would see why.

**No match, for a data source that returns a list.** The plural ones (`aws_subnets`, `aws_vpcs`,
`aws_availability_zones`) answer with a list, and an empty list is a perfectly good answer:

```hcl
provider "aws" {
  region = "sa-east-1"
}

data "aws_subnets" "private" {
  tags = {
    Tier = "private"
  }
}

output "private_subnets" {
  value = data.aws_subnets.private.ids
}
```

```
ana@laptop:~/shop/probe$ terraform apply -auto-approve
data.aws_subnets.private: Reading...
data.aws_subnets.private: Read complete after 0s [id=sa-east-1]

Changes to Outputs:
  + private_subnets = []

You can apply this plan to save these new output values to the Terraform
state, without changing any real infrastructure.

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

private_subnets = tolist([])
```

No error and no warning. There are no private subnets, and the configuration carries on with zero of
them. A security group with an empty list of sources or an autoscaling group placed in no subnet is
exactly the kind of mistake that applies quietly. When an empty list is wrong, say so: a
`precondition` or a `check` block from lesson 3 can refuse it with a message of your own.

**The match that breaks later** is the one that hurts, because the configuration did not change. The
network team builds a staging copy of the network and copies the tags along with everything else:

```
ana@laptop:~/shop/app$ aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop --query "Vpcs[].[CidrBlock,Tags[?Key==\`Environment\`]|[0].Value]" --output text
10.20.0.0/16	prod
10.30.0.0/16	staging
```

Ana's configuration, untouched since it last planned cleanly, now stops:

```
ana@laptop:~/shop/app$ terraform plan
data.local_file.office: Reading...
data.local_file.office: Read complete after 0s [id=d31eb9db97a1f63a12b9d3ed7b67d80fde5b4ab8]
data.aws_ami.web: Reading...
data.aws_vpc.shop: Reading...
data.aws_region.current: Reading...
data.aws_caller_identity.current: Reading...
data.aws_region.current: Read complete after 0s [id=sa-east-1]
data.aws_caller_identity.current: Read complete after 0s [id=123456789012]
aws_s3_bucket.assets: Refreshing state... [id=shop-assets-123456789012]
data.aws_ami.web: Read complete after 0s [id=ami-737937c26a362335e]
data.aws_iam_policy_document.assets: Reading...
data.aws_iam_policy_document.assets: Read complete after 0s [id=2993801947]
aws_s3_bucket_policy.assets: Refreshing state... [id=shop-assets-123456789012]

Planning failed. Terraform encountered an error while generating this plan.

╷
│ Error: multiple EC2 VPCs matched; use additional constraints to reduce matches to a single EC2 VPC
│ 
│   with data.aws_vpc.shop,
│   on network.tf line 1, in data "aws_vpc" "shop":
│    1: data "aws_vpc" "shop" {
│ 
╵
```

Her lookup was correct on the day she wrote it. **A data source's query is a contract with whoever
owns the thing it looks up**, and the contract was never written down: "there is one VPC tagged
`shop`" was true by accident. The fix is to ask for what she actually means, the production network:

```hcl
data "aws_vpc" "shop" {
  tags = {
    Name        = "shop"
    Environment = "prod"
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

```
No changes. Your infrastructure matches the configuration.
```

Tags are a weak contract because anybody can copy them. Two habits make it stronger. Agree the tags
with the other team, as an interface they promise to keep unique, rather than guessing them from the
console. And where the other side is itself a Terraform configuration, read its **outputs** instead,
which it publishes on purpose: that is `terraform_remote_state`, and lesson 8 uses it to join the
network's configuration to the application's.
