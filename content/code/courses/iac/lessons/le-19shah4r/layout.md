---
title: What a published module carries
version: 1
---

Terraform needs only `.tf` files to use a module. **The people calling it need more**, and the
layout most published modules share exists for them rather than for Terraform. It is called the
standard module structure, and the registry expects it. After three more files, Ana's repository
has it:

```
ana@laptop:~/src/terraform-aws-network$ tree --noreport
.
├── CHANGELOG.md
├── README.md
├── examples
│   └── basic
│       └── main.tf
├── main.tf
├── moved.tf
├── outputs.tf
├── variables.tf
└── versions.tf
```

Each file has one job. `main.tf`, `variables.tf` and `outputs.tf` are the three from "writing-one",
and splitting them is a convention rather than a rule: a reader who wants the interface opens two
short files and never needs the third. `moved.tf` keeps the `moved` blocks from "versioning" in one
place, so the day they can be deleted they are easy to find. `CHANGELOG.md` is the note that came
with `v2.0.0`. The other three are new.

## `versions.tf`: what the module needs

```hcl
terraform {
  required_version = ">= 1.1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
  }
}
```

**A module states the lowest versions it works with, and leaves the rest to the root.** `>= 6.0`
says the module was written against version 6 of the AWS provider. The shop's root says `~> 6.0`,
and the root's lock file records exactly which version was installed; Terraform intersects every
constraint in the configuration and chooses one provider version for all of them. A module that
pinned `= 6.67.0` would force that exact version on every caller, and two such modules with
different pins could never be used together. `required_version` does the same for Terraform
itself: `moved` blocks arrived in Terraform 1.1, so the module says `>= 1.1` rather than letting an
older Terraform fail on a block it has never heard of.

## `README.md`: how to call it

```
# terraform-aws-network

A VPC and a map of subnets in it, each tagged `<name>-<key>`.

    module "network" {
      source = "git::https://git.example.com/shop/terraform-aws-network.git?ref=v2.0.0"

      name       = "shop"
      cidr_block = "10.20.0.0/16"
      subnets = {
        a = { az = "sa-east-1a", cidr = "10.20.1.0/24" }
      }
    }

Inputs: `name`, `cidr_block`, `subnets`. Outputs: `vpc_id`, `subnet_ids`.
Read CHANGELOG.md before upgrading across a major version.
```

The example call is the most-read part of any module. Its `source` is written for a real Git server
rather than the lab's stand-in, and its `ref` is the current version, so whoever copies it starts on a
version that is still maintained. The registry shows this file as the module's page, and tools such
as `terraform-docs` can generate the list of inputs and outputs from `variables.tf` and
`outputs.tf`, which keeps the two from disagreeing.

## `examples/`: a call that is known to work

```hcl
provider "aws" {
  region = "sa-east-1"
}

module "network" {
  source = "../.."

  name       = "example"
  cidr_block = "10.99.0.0/16"
  subnets = {
    a = { az = "sa-east-1a", cidr = "10.99.1.0/24" }
  }
}

output "vpc_id" {
  value = module.network.vpc_id
}
```

**An example is a root module that calls the module from its parent directory**, `source = "../.."`,
with its own provider block, which the module itself must not have. It is documentation that can
be run, and the cheapest check that the module still works after a change:

```
ana@laptop:~/src/terraform-aws-network/examples/basic$ terraform init | grep -E "Initializing modules|- network|successfully"
Initializing modules...
- network in ../..
Terraform has been successfully initialized!
ana@laptop:~/src/terraform-aws-network/examples/basic$ terraform validate
Success! The configuration is valid.
```

`validate` checks that the call matches the interface: every argument is a variable the module
declares, every required one is given, every type fits. It found nothing to complain about, and it
needed no AWS at all. An `apply` of the example against a test account is the stronger check, and
lesson 13 makes both of them into tests that run on every change.

A module that grows parts worth calling on their own puts them in `modules/` inside its own
repository, each with the same three files, and callers reach one with a `//` in the source, such as
`…terraform-aws-network.git//modules/endpoints?ref=v2.1.0`. Until a second part exists, one
directory is the whole of it.
