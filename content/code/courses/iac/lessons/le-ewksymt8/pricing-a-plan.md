---
title: Pricing a plan before it is applied
version: 2
---

The usual picture is that cost arrives on the bill, a month after the change that caused it, and is
somebody else's department. **A plan already holds most of the answer.** It names every resource
that will exist, and for the resources sold by the hour it names the attribute that sets the price:
an instance's type, a disk's size, the fact that a NAT gateway exists at all. Join that with a price
list and the month is known before `apply`.

Here is the shop's network and its two web servers, in `~/shop`. `main.tf` is the plain `terraform`
and `provider` block from lesson 2:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "sa-east-1"
}
```

`network.tf` holds the network:

```hcl
resource "aws_vpc" "shop" {
  cidr_block = "10.20.0.0/16"
  tags       = { Name = "shop" }
}

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = "sa-east-1a"
  tags              = { Name = "shop-public-a" }
}

resource "aws_subnet" "private_c" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.2.0/24"
  availability_zone = "sa-east-1c"
  tags              = { Name = "shop-private-c" }
}

resource "aws_internet_gateway" "shop" {
  vpc_id = aws_vpc.shop.id
}

resource "aws_eip" "nat" {
  domain = "vpc"
}

# lets the private subnet reach the internet without being reachable from it
resource "aws_nat_gateway" "shop" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id
  depends_on    = [aws_internet_gateway.shop]
}
```

and `web.tf` the two servers:

```hcl
resource "aws_instance" "web" {
  count         = 2
  ami           = "ami-1e749f67"
  instance_type = "t3.medium"
  subnet_id     = aws_subnet.private_c.id

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = { Name = "web-${count.index}" }
}
```

Ana keeps the directory in Git, with a `.gitignore` of `.terraform/`, `*.tfstate*` and `tfplan`.
After `terraform init` she commits everything, `price.py` below included, as *the shop: network and
two web servers*. The plan creates eight things:

```
ana@laptop:~/shop$ terraform plan -no-color -out tfplan | grep -E "will be created|Plan:"
  # aws_eip.nat will be created
  # aws_instance.web[0] will be created
  # aws_instance.web[1] will be created
  # aws_internet_gateway.shop will be created
  # aws_nat_gateway.shop will be created
  # aws_subnet.private_c will be created
  # aws_subnet.public_a will be created
  # aws_vpc.shop will be created
Plan: 8 to add, 0 to change, 0 to destroy.
```

Lesson 9 showed the same plan as JSON, which is the form a program can read. The instance type is
already there, as a plain value, before anything was created:

```
ana@laptop:~/shop$ terraform show -json tfplan | jq -c '.resource_changes[] | select(.type == "aws_instance") | [.address, .change.actions[0], .change.after.instance_type]'
["aws_instance.web[0]","create","t3.medium"]
["aws_instance.web[1]","create","t3.medium"]
```

## The prices, and where they come from

**The prices are written into the script, not looked up when it runs.** The AWS price list is a
download that changes, so the prices below are lines of the cloud course's price sheet, `prices.py`,
copied from its `sa-east-1` column as that course prints them: AWS's public list prices in USD,
before tax, at the offer versions it pins, `AmazonEC2` 20260925174521 and `AmazonVPC`
20260917190528. Lesson 10 of the cloud course explains how that sheet is read and why a pinned
version prints the same numbers next year. What this lesson does is the arithmetic, so your run of
it prints the figures on this page.

`price.py`, saved in `~/shop`, reads a plan on its standard input, prices the four kinds of resource it has a line for,
and counts a month as 730 hours, the cloud course's convention:

```python
#!/usr/bin/env python3
"""What a plan adds to the monthly bill, at list price.

    terraform show -json tfplan | python3 price.py
"""
import json
import sys

HOURS = 730  # an average month: 8,760 hours a year over 12

# sa-east-1, USD, from the cloud course's prices.py
# (offers AmazonEC2 20260925174521 and AmazonVPC 20260917190528)
INSTANCE_PER_HOUR = {"t3.micro": 0.01680, "t3.medium": 0.06720, "m7i.large": 0.16065}
NAT_PER_HOUR = 0.0930
IPV4_PER_HOUR = 0.0050
GP3_PER_GB_MONTH = 0.1520


def monthly(kind, v):
    """USD a month for one resource, or None if the sheet has no line for it."""
    if kind == "aws_instance":
        disk = sum(d["volume_size"] for d in v["root_block_device"])
        return INSTANCE_PER_HOUR[v["instance_type"]] * HOURS + disk * GP3_PER_GB_MONTH
    if kind == "aws_nat_gateway":
        return NAT_PER_HOUR * HOURS
    if kind == "aws_eip":
        return IPV4_PER_HOUR * HOURS
    return None


total, unpriced = 0.0, []
for rc in json.load(sys.stdin)["resource_changes"]:
    actions = rc["change"]["actions"]
    if actions in (["no-op"], ["read"]):
        continue
    before, after = (rc["change"][k] for k in ("before", "after"))
    old = monthly(rc["type"], before) if before else 0.0
    new = monthly(rc["type"], after) if after else 0.0
    if old is None or new is None:
        unpriced.append(rc["address"])
        continue
    total += new - old
    print(f"{rc['address']:22} {'/'.join(actions):8} {old:8.2f} -> {new:8.2f}")
print(f"{'change per month, USD':41} {total:+8.2f}")
if unpriced:
    print("no line on the sheet:", ", ".join(unpriced))
```

For an update it prices the resource before and after and prints the difference, which is why it
reads both `before` and `after`. **A resource the sheet has no line for is listed, never dropped**,
because a total that quietly skipped something would look complete.

```
ana@laptop:~/shop$ terraform show -json tfplan | python3 price.py
aws_eip.nat            create       0.00 ->     3.65
aws_instance.web[0]    create       0.00 ->    52.10
aws_instance.web[1]    create       0.00 ->    52.10
aws_nat_gateway.shop   create       0.00 ->    67.89
change per month, USD                      +175.73
no line on the sheet: aws_internet_gateway.shop, aws_subnet.private_c, aws_subnet.public_a, aws_vpc.shop
```

Before a single resource exists, the plan is worth **175.73 USD a month** at list price. The
surprise is the order. The NAT gateway, one line in `network.tf` with a comment above it, costs
67.89, more than either web server at 52.10. Each server's 52.10 is its hours plus its 20 GB disk;
the address the gateway holds adds 3.65. The VPC, the subnets and the internet gateway have no
line, because AWS does not charge for them by the hour.

Ana applies the saved plan, `terraform apply -auto-approve tfplan`, so the network exists for the
rest of the lesson.

## What a plan cannot price

The total is a floor. **A plan knows what will exist, not how much it will be used.** The cloud
course's sheet has a second NAT gateway line, 0.0930 USD for each GB it processes, and no plan says
how many gigabytes the web servers will fetch. The same is true of data sent to the internet, S3
requests and a Lambda function's invocations. Discounts, commitments and tax are missing as well,
because they belong to the account rather than to the configuration.

That still makes the estimate useful in exactly the place this course cares about: the review.
Everything a change adds by the hour is visible before it is applied, and the next section puts that
number where a reviewer reads.
