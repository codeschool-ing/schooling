---
title: Locals, and saying a thing once
version: 1
---

Every resource of the shop should carry the same three tags, `Project`, `Owner` and
`Environment`, and a name built from the environment. Written out by hand in each resource, the
three copies agree on the day they are typed and drift apart on the first edit somebody makes to
only two of them. **A local value names an expression once**, and everything else refers to the
name:

```hcl
locals {
  name = "shop-${var.environment}"

  common_tags = {
    Project     = "shop"
    Owner       = var.owner
    Environment = var.environment
  }
}
```

The block is `locals`, plural, and holds as many names as you like; a reference is `local.name`,
singular. That mismatch is a typo everybody makes once. A local may use any expression, including
other locals, variables and resource attributes, and Terraform works out the order from the
references, as it does for resources.

The subnets now read everything from somewhere else: the range from `cidrsubnet`, the zone from
the variable, the tags from the local, merged with a `Name` of their own:

```hcl
resource "aws_subnet" "a" {
  vpc_id                  = aws_vpc.shop.id
  cidr_block              = cidrsubnet(var.network.cidr, 8, 1)
  availability_zone       = var.network.azs[0]
  map_public_ip_on_launch = var.network.public
  tags                    = merge(local.common_tags, { Name = "${local.name}-a" })
}

resource "aws_subnet" "c" {
  vpc_id                  = aws_vpc.shop.id
  cidr_block              = cidrsubnet(var.network.cidr, 8, 2)
  availability_zone       = var.network.azs[1]
  map_public_ip_on_launch = var.network.public
  tags                    = merge(local.common_tags, { Name = "${local.name}-c" })
}
```

The VPC in `main.tf` gets the same treatment, and the tags now come from one place in every file:

```
ana@laptop:~/shop$ grep -n "tags" *.tf
locals.tf:4:  common_tags = {
main.tf:20:  tags                 = merge(local.common_tags, { Name = local.name })
network.tf:6:  tags                    = merge(local.common_tags, { Name = "${local.name}-a" })
network.tf:14:  tags                    = merge(local.common_tags, { Name = "${local.name}-c" })
```

Applied on moto, the plan shows each value worked out. Here is the first subnet, cut short after
its tags:

```
ana@laptop:~/shop$ terraform apply -auto-approve

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_subnet.a will be created
  + resource "aws_subnet" "a" {
      + arn                                            = (known after apply)
      + assign_ipv6_address_on_creation                = false
      + availability_zone                              = "sa-east-1a"
      + availability_zone_id                           = (known after apply)
      + cidr_block                                     = "10.20.1.0/24"
      + enable_dns64                                   = false
      + enable_resource_name_dns_a_record_on_launch    = false
      + enable_resource_name_dns_aaaa_record_on_launch = false
      + id                                             = (known after apply)
      + ipv6_cidr_block                                = (known after apply)
      + ipv6_cidr_block_association_id                 = (known after apply)
      + ipv6_native                                    = false
      + map_public_ip_on_launch                        = false
      + owner_id                                       = (known after apply)
      + private_dns_hostname_type_on_launch            = (known after apply)
      + region                                         = "sa-east-1"
      + tags                                           = {
          + "Environment" = "dev"
          + "Name"        = "shop-dev-a"
          + "Owner"       = "ana"
          + "Project"     = "shop"
        }
```

And the end of the run:

```
Plan: 3 to add, 0 to change, 0 to destroy.
aws_vpc.shop: Creating...
aws_vpc.shop: Creation complete after 1s [id=vpc-1421f4c581e114d46]
aws_subnet.c: Creating...
aws_subnet.a: Creating...
aws_subnet.c: Creation complete after 0s [id=subnet-719532a052c2db8ea]
aws_subnet.a: Creation complete after 0s [id=subnet-e30146a6aa7865aaf]

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

Three resources, and not one of their tags or ranges was typed twice. `shop-dev-a` came from
`"${local.name}-a"`, which came from `var.environment`; change the environment and every name and
tag follows.

## A local is not a variable

The two look alike from inside the file, since both are a name with a value, and they are
different from outside it. **A variable is an input**: whoever runs Terraform can set it, with
`-var`, a `.tfvars` file or a `TF_VAR_` environment variable, as lesson 2 showed. **A local is
internal**, and nobody outside the configuration can reach it:

```
ana@laptop:~/shop$ terraform plan -var name=shop-test
╷
│ Error: Value for undeclared variable
│ 
│ A variable named "name" was assigned on the command line, but the root
│ module does not declare a variable of that name. To use this value, add a
│ "variable" block to the configuration.
╵
```

That decides which one to use. If the value is a choice the person running Terraform should be
able to make, the environment or the network range, it is a variable. If it is derived from other
values, or is a fact that should not be overridden, like the tag that says which project a
resource belongs to, it is a local. Making it a variable "just in case" invites somebody to set
`Project` to something else on the command line one day.

**Do not wrap every literal in a local.** `local.vpc_cidr = "10.20.0.0/16"`, used once, only adds
a jump for the reader. A local earns its place when it is used more than once, or when its name
says something the expression does not, as `common_tags` does. Lesson 16 meets another route to
the same tags, the provider's `default_tags`, which applies them to every resource the provider
creates.
