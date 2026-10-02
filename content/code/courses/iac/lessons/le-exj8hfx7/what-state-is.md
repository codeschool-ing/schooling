---
title: What the state file holds
version: 1
---

Lesson 1 ended on a promise: Terraform can only compare what it knows how to read, so it has to
remember which real VPC belongs to which line of the file. This lesson is about that memory. Here
is the shop's network again, a VPC, a subnet and the `web` security group with its one HTTPS rule:

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

resource "aws_vpc" "shop" {
  cidr_block = "10.20.0.0/16"
  tags       = { Name = "shop" }
}

resource "aws_subnet" "a" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = "sa-east-1a"
  tags              = { Name = "shop-a" }
}

resource "aws_security_group" "web" {
  name        = "web"
  description = "web servers"
  vpc_id      = aws_vpc.shop.id
  tags        = { Name = "web" }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

Ana applies it, and three resources come into existence:

```
ana@laptop:~/shop$ terraform apply -auto-approve | tail -n 8
aws_vpc.shop: Creating...
aws_vpc.shop: Creation complete after 2s [id=vpc-10f2b2857589fd959]
aws_security_group.web: Creating...
aws_subnet.a: Creating...
aws_subnet.a: Creation complete after 0s [id=subnet-1849baa846a6631fa]
aws_security_group.web: Creation complete after 0s [id=sg-3bb7d165786e44657]

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

**A file appeared beside `main.tf` that she never wrote.** It is called `terraform.tfstate`, and
Terraform writes it every time it changes something:

```
ana@laptop:~/shop$ ls -a
.
..
.terraform
.terraform.lock.hcl
main.tf
terraform.tfstate
```

It is JSON, so `jq` can read it. The top of the file says what it is:

```
ana@laptop:~/shop$ jq "{version, terraform_version, serial, lineage}" terraform.tfstate
{
  "version": 4,
  "terraform_version": "1.16.4",
  "serial": 4,
  "lineage": "7d110614-d17a-9483-3aa9-392bbcba59d2"
}
```

`version` is the format of the file itself, not of anything in it. `terraform_version` is the
Terraform that last wrote it. `serial` goes up by one on every write, so of two copies the one with
the higher serial is the newer. `lineage` is a random id given to the state when it was created and
kept through every serial after that: two files with different lineages are not two versions of one
history, they are two histories, and Terraform refuses to write one over the other. You will see
both of those numbers do their job in the last section of this lesson.

Below the header is the part that matters, one entry per resource:

```
ana@laptop:~/shop$ jq -c ".resources[] | {type, name, id: .instances[0].attributes.id}" terraform.tfstate
{"type":"aws_security_group","name":"web","id":"sg-3bb7d165786e44657"}
{"type":"aws_subnet","name":"a","id":"subnet-1849baa846a6631fa"}
{"type":"aws_vpc","name":"shop","id":"vpc-10f2b2857589fd959"}
```

**That is the mapping.** On the left, an address that only exists in the configuration:
`aws_vpc.shop` is a type and a name Ana chose. On the right, an id that only exists in AWS: the
account invented it during the apply, and nothing in `main.tf` could ever contain it. The state is
the one place where the two meet.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Three columns. On the left, the configuration main.tf with three addresses: aws_vpc.shop, aws_subnet.a and aws_security_group.web. In the middle, the state, terraform.tfstate, which pairs each address with an id. On the right, the AWS account, where the VPC, the subnet and the security group exist under ids AWS invented. Only the state contains both the address and the id.\"><rect x=\"20\" y=\"20\" width=\"200\" height=\"200\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the configuration</text><text x=\"120.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">main.tf</text><rect x=\"260\" y=\"20\" width=\"200\" height=\"200\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the state</text><text x=\"360.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">terraform.tfstate</text><rect x=\"500\" y=\"20\" width=\"200\" height=\"200\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the account</text><text x=\"600.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">AWS (moto)</text><rect x=\"30\" y=\"80\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">aws_vpc.shop</text><rect x=\"270\" y=\"80\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">aws_vpc.shop  →  vpc-…</text><rect x=\"510\" y=\"80\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">vpc-…</text><rect x=\"30\" y=\"125\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"141.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">aws_subnet.a</text><rect x=\"270\" y=\"125\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"141.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">aws_subnet.a  →  subnet-…</text><rect x=\"510\" y=\"125\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"141.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">subnet-…</text><rect x=\"30\" y=\"170\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">aws_security_group.web</text><rect x=\"270\" y=\"170\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper)\">aws_security_group.web  →  sg-…</text><rect x=\"510\" y=\"170\" width=\"180\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"186.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">sg-…</text><text x=\"360.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">the only place where an address meets an id</text></svg>", "caption": "The state is the join: an address only the configuration has, beside an id only AWS has."}
```

Why can Terraform not look the VPC up instead, by its `Name` tag? Because a tag is not an identity.
Lesson 1 already created two VPCs called `shop` with the same range, and AWS accepted both. A search
by name finds zero, one or several, and Terraform would have to guess which one is *the* `aws_vpc.shop`.
With the id written down there is nothing to guess: on the next plan it asks AWS for exactly that
object and compares what comes back with the file.

Each entry holds more than an id. It is a copy of every attribute the provider returned, including
the ones AWS computed, and a list of what the resource depended on:

```
ana@laptop:~/shop$ jq ".resources[] | select(.name == \"web\") | .instances[0] | {arn: .attributes.arn, owner_id: .attributes.owner_id, dependencies}" terraform.tfstate
{
  "arn": "arn:aws:ec2:sa-east-1:123456789012:security-group/sg-3bb7d165786e44657",
  "owner_id": "123456789012",
  "dependencies": [
    "aws_vpc.shop"
  ]
}
```

The `dependencies` list is there for the day the configuration no longer says. Delete the whole
`main.tf` and Terraform still knows, from the state alone, that the security group has to go before
the VPC it lives in. The attribute copy is why a plan can show `~ update in-place` with the old
value beside the new one, and it is also why the state is **sensitive**: whatever a provider
returns lands in it, and lesson 12 finds a password there in plain text.

So there are three things, and every command in this lesson is about keeping them in agreement:
**the configuration** says what should exist, **the real account** has what does exist, and **the
state** says which real object answers to which address. Lose the third, and the other two can no
longer be compared.
