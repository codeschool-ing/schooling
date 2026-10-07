---
title: The layers of a test, and what each one costs
version: 2
---

Most people arrive believing that infrastructure code cannot really be tested: the only way to
know whether a configuration works is to apply it in a development account and look. **That is
one test, the slowest and dearest of five**, and it finds a mistake last, after everything cheaper
had a chance to find it first. A test suite for Terraform is a ladder. Each rung needs more than
the one above it and finds something the one above cannot see.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Five checks in a table, cheapest at the top. terraform fmt needs nothing and finds layout. terraform validate needs the providers installed and finds wrong names, arguments and references. A scanner, lesson 14, needs nothing and finds what the code exposes. A test run with command = plan needs an API that answers, or a mock, and finds what the plan would do with given values. A test run with command = apply needs an account, here moto, and finds what AWS accepts and reports back. An arrow down the side says each step is slower, costs more and is closer to AWS.\"><defs><marker id=\"ly-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"150.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">check</text><text x=\"345.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">needs</text><text x=\"555.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">finds</text><rect x=\"60\" y=\"44\" width=\"650\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">terraform fmt</text><text x=\"345.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nothing</text><text x=\"555.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">layout</text><rect x=\"60\" y=\"100\" width=\"650\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">terraform validate</text><text x=\"345.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the providers installed</text><text x=\"555.0\" y=\"123.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">names, arguments, references</text><rect x=\"60\" y=\"156\" width=\"650\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"179.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a scanner (lesson 14)</text><text x=\"345.0\" y=\"179.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nothing</text><text x=\"555.0\" y=\"179.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what the code exposes</text><rect x=\"60\" y=\"212\" width=\"650\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">command = plan</text><text x=\"345.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">an API that answers, or a mock</text><text x=\"555.0\" y=\"235.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what the plan does with these values</text><rect x=\"60\" y=\"268\" width=\"650\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"291.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">command = apply</text><text x=\"345.0\" y=\"291.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">an account (here, moto)</text><text x=\"555.0\" y=\"291.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what AWS accepts and reports back</text><path d=\"M30 48 L30 312\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ly-ah-amber)\"></path><text x=\"30.0\" y=\"322.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">slower, dearer, closer to AWS</text></svg>", "caption": "Each check finds what the ones above it cannot, and costs more to run."}
```

**`terraform fmt`** checks only the layout of the files, and needs nothing at all. It belongs in
the suite because a pull request that reformats forty lines to change one hides the one.

**`terraform validate`** reads every file in the directory and checks it against itself and
against the providers' schemas: that every argument exists, every reference points at something
declared, every type fits. It needs the providers installed and nothing else. No credentials, no
API and no values for the variables. That is its strength, and it is also everything it misses.

**A scanner**, lesson 14's subject, reads the same files for what they expose: a bucket open to
the world, port 22 open to `0.0.0.0/0`. It is a rule about the code, written by somebody else, and
it is named here only so you know where it sits.

**A test run with `command = plan`** gives the module values and asserts things about the plan
Terraform would make with them: how many subnets, in which zones, under which names. It creates
nothing, so it can run on every commit. It needs a provider that answers questions during the plan,
which is AWS, moto in this course, or a mock that answers instead.

**A test run with `command = apply`** builds the thing, asserts against what came back, and
destroys it. It is the only rung that finds out whether AWS accepts what the plan proposed, and on
a real account it is the only rung that costs money.

## The module under test

The module this lesson tests is small on purpose. Lesson 10 is about writing modules; this one
needs only something with inputs, a rule or two and resources whose shape depends on the values.
Ana's `network` module lives in `~/shop/modules/network`, and takes a name, a range and a map of
subnets, in `variables.tf`:

```hcl
variable "name" {
  type        = string
  description = "Prefix for every Name tag."
}

variable "cidr" {
  type        = string
  description = "The VPC's range, such as 10.20.0.0/16."

  validation {
    condition     = can(cidrnetmask(var.cidr))
    error_message = "cidr must be an IPv4 range such as 10.20.0.0/16."
  }
}

variable "subnets" {
  type = map(object({
    cidr = string
    az   = string
  }))
  description = "One subnet per key: its range and its availability zone."
}
```

`main.tf`:

```hcl
data "aws_availability_zones" "here" {
  state = "available"
}

resource "aws_vpc" "this" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  tags                 = { Name = var.name }
}

resource "aws_subnet" "this" {
  for_each = var.subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags              = { Name = "${var.name}-${each.key}" }

  lifecycle {
    precondition {
      condition     = contains(data.aws_availability_zones.here.names, each.value.az)
      error_message = "Zone ${each.value.az} is not one this region offers."
    }
  }
}
```

The `precondition` reads the zones the region actually offers from a data source, so a subnet in
a zone that does not exist is refused before anything is created. Lesson 3 introduced both
kinds of rule; here they matter because they are things a test can aim at. `versions.tf` requires
Terraform 1.9 or newer and the AWS provider:

```hcl
terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
```

And `outputs.tf` returns the VPC's id and a map of subnet ids. Ana typed it in a hurry, and the next
section is about what that looks like, so copy it as it is here, indentation and all:

```hcl
output "vpc_id" {
    value = aws_vpc.this.id
}

output "subnet_ids" {
  value = {for k, s in aws_subnet.this: k => s.id}
}
```

By the end of the lesson the module carries four test files and a helper module, all under
`tests/`, which is where `terraform test` looks by default:

```
ana@laptop:~/shop/modules/network$ tree
.
├── main.tf
├── outputs.tf
├── tests
│   ├── aws
│   │   └── main.tf
│   ├── e2e.tftest.hcl
│   ├── plan.tftest.hcl
│   ├── rules.tftest.hcl
│   └── unit.tftest.hcl
├── variables.tf
└── versions.tf

3 directories, 9 files
```

**Most of the tests sit at the cheap end.** Of the eight runs in the finished suite, four need no
AWS at all, two ask AWS questions during a plan, and two apply against it. That proportion is the
point of the ladder: catch a mistake on the rung that costs least to climb, and save the apply for
the few questions only AWS can answer.
