---
title: Validation rules, preconditions and checks
version: 2
---

A type says what shape a value has. **A validation rule says which values of that shape are
acceptable**, and it does it in the variable's own block, with an error message you write.
Terraform has four places to put a rule like that, and they differ in when they run and in what
happens when one fails.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Three moments of a run, left to right: the values arrive, the plan, the apply. When the values arrive, a variable's validation runs, and its failure is an error before anything is planned. During the plan, a precondition runs and fails as an error; a postcondition runs if the value is already known; a check block runs and only warns. During the apply, a postcondition whose value was unknown runs after the change is made, and the check block runs again and warns.\"><defs><marker id=\"ru-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"30\" y=\"30\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the values arrive</text><rect x=\"270\" y=\"30\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">plan</text><rect x=\"510\" y=\"30\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">apply</text><path d=\"M212 52 L266 52\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ru-ah-wire)\"></path><path d=\"M452 52 L506 52\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ru-ah-wire)\"></path><text x=\"120.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">validation</text><text x=\"120.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">error: nothing is planned</text><text x=\"360.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">precondition</text><text x=\"360.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">error, before the resource</text><text x=\"360.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">postcondition</text><text x=\"360.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">error, if the value is known</text><text x=\"360.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">check</text><text x=\"360.0\" y=\"248.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a warning; the plan goes on</text><text x=\"600.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">postcondition</text><text x=\"600.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">error, after the change</text><text x=\"600.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">check</text><text x=\"600.0\" y=\"248.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a warning, again</text></svg>", "caption": "Where each kind of rule is checked. Only a check block lets the run carry on."}
```

## Validation, in the variable

Ana's variables, in `variables.tf`, gain one rule each:

```hcl
variable "environment" {
  type        = string
  default     = "dev"
  description = "dev or prod."

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "The environment is dev or prod; the shop has no other."
  }
}

variable "network" {
  type = object({
    cidr   = string
    azs    = list(string)
    public = optional(bool, false)
  })
  default = {
    cidr = "10.20.0.0/16"
    azs  = ["sa-east-1a", "sa-east-1c"]
  }

  validation {
    condition     = can(cidrsubnet(var.network.cidr, 8, 2))
    error_message = "The network needs a CIDR range with room for /24 subnets, such as 10.20.0.0/16."
  }
}
```

A `validation` block holds a `condition`, an expression that must be `true`, and an
`error_message` for when it is not. A variable may have several. The condition for `network` is
the `can` shape from the functions section: it asks whether `cidrsubnet` could cut the second
`/24` out of the range, and treats any error as "no". Here they are refusing:

```
ana@laptop:~/shop$ terraform plan -var environment=staging

Planning failed. Terraform encountered an error while generating this plan.

╷
│ Error: Invalid value for variable
│ 
│   on variables.tf line 1:
│    1: variable "environment" {
│     ├────────────────
│     │ var.environment is "staging"
│ 
│ The environment is dev or prod; the shop has no other.
│ 
│ This was checked by the validation rule at variables.tf:6,3-13.
╵
```

```
ana@laptop:~/shop$ terraform plan -var 'network={ cidr = "10.20.0.0/26", azs = ["sa-east-1a", "sa-east-1c"] }'
aws_vpc.shop: Refreshing state... [id=vpc-1421f4c581e114d46]

Planning failed. Terraform encountered an error while generating this plan.

╷
│ Error: Invalid value for variable
│ 
│   on variables.tf line 12:
│   12: variable "network" {
│     ├────────────────
│     │ var.network.cidr is "10.20.0.0/26"
│ 
│ The network needs a CIDR range with room for /24 subnets, such as
│ 10.20.0.0/16.
│ 
│ This was checked by the validation rule at variables.tf:23,3-13.
╵
```

**Nothing was planned in either run.** The message is the sentence Ana wrote, under a line saying
which value broke it, so the person who typed `staging` learns what the
shop accepts, in words, before anything is planned or changed. A `/26` is a valid range and
passes the type, and it still has no room for `/24` subnets, so the rule says so. Since Terraform
1.9 a condition may refer to other variables as well as its own.

## Preconditions and postconditions, on a resource

Some rules are about a value that no single variable holds. The shop's assets bucket is named
from three pieces, and S3 refuses a bucket name longer than 63 characters. Ana writes it in
`bucket.tf`:

```hcl
locals {
  bucket = "${local.name}-assets-${var.owner}"
}

resource "aws_s3_bucket" "assets" {
  bucket = local.bucket

  lifecycle {
    precondition {
      condition     = length(local.bucket) <= 63
      error_message = "Bucket names stop at 63 characters; ${local.bucket} has ${length(local.bucket)}."
    }
    postcondition {
      condition     = self.region == "sa-east-1"
      error_message = "The shop's files stay in São Paulo."
    }
  }
}
```

A **precondition** lives in a resource's `lifecycle` block and is checked before Terraform plans
that resource. A **postcondition** is checked against the resource as it will be, or as it came
back, and refers to it as `self`. Here the precondition guards the name, and the postcondition
checks that the bucket landed in São Paulo. With an owner long enough to break the name:

```
ana@laptop:~/shop$ terraform plan -var owner=ana-and-everybody-else-on-the-platform-team-of-the-shop
aws_vpc.shop: Refreshing state... [id=vpc-1421f4c581e114d46]
aws_subnet.c: Refreshing state... [id=subnet-719532a052c2db8ea]
aws_subnet.a: Refreshing state... [id=subnet-e30146a6aa7865aaf]

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  ~ update in-place

Terraform planned the following actions, but then encountered a problem:
```

Terraform planned the tag updates the long owner causes on the other three resources, and then:

```
Plan: 0 to add, 3 to change, 0 to destroy.
╷
│ Error: Resource precondition failed
│ 
│   on bucket.tf line 10, in resource "aws_s3_bucket" "assets":
│   10:       condition     = length(local.bucket) <= 63
│     ├────────────────
│     │ local.bucket is "shop-dev-assets-ana-and-everybody-else-on-the-platform-team-of-the-shop"
│ 
│ Bucket names stop at 63 characters;
│ shop-dev-assets-ana-and-everybody-else-on-the-platform-team-of-the-shop has
│ 71.
╵
```

The error quotes the name and its length, 71, because the message is itself a template. **The
plan failed, so nothing was applied**, the tag updates included. Without the precondition the
same name would have reached S3 at apply time, after the other changes had been made.

A postcondition whose value is known during the plan is checked then, as this region is. When the
value only exists after the change, Terraform checks it after making the change, and a failure
then is an error with the resource already created or changed. That is the price of a rule about
something only AWS can tell you. With the default owner, `ana`, the name fits, and Ana creates the
bucket with `terraform apply -auto-approve`; the plan below finds it already there.

## Check blocks, which only warn

A `check` block stands on its own, outside any resource, and **a failed assertion is a warning,
not an error**. Ana's goes in `checks.tf`:

```hcl
check "two_zones" {
  assert {
    condition     = length(distinct(var.network.azs)) >= 2
    error_message = "With one zone, the shop goes down with that zone."
  }
}
```

Given the same zone twice, the plan goes ahead:

```
ana@laptop:~/shop$ terraform plan -var 'network={ cidr = "10.20.0.0/16", azs = ["sa-east-1a", "sa-east-1a"] }'
aws_vpc.shop: Refreshing state... [id=vpc-1421f4c581e114d46]
aws_s3_bucket.assets: Refreshing state... [id=shop-dev-assets-ana]
aws_subnet.c: Refreshing state... [id=subnet-719532a052c2db8ea]
aws_subnet.a: Refreshing state... [id=subnet-e30146a6aa7865aaf]

Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
-/+ destroy and then create replacement

Terraform will perform the following actions:

  # aws_subnet.c must be replaced
-/+ resource "aws_subnet" "c" {
      ~ arn                                            = "arn:aws:ec2:sa-east-1:123456789012:subnet/subnet-719532a052c2db8ea" -> (known after apply)
      ~ availability_zone                              = "sa-east-1c" -> "sa-east-1a" # forces replacement
```

```
Plan: 1 to add, 0 to change, 1 to destroy.
╷
│ Warning: Check block assertion failed
│ 
│   on checks.tf line 3, in check "two_zones":
│    3:     condition     = length(distinct(var.network.azs)) >= 2
│     ├────────────────
│     │ var.network.azs is list of string with 2 elements
│ 
│ With one zone, the shop goes down with that zone.
╵
```

The plan would replace subnet `c` in zone `sa-east-1a`, and the check said what it thought of
that and let it proceed. That is the right tool for something worth knowing and not worth
stopping for; a rule that must hold belongs in a validation or a precondition. Lesson 13 tests
rules like these on purpose, by feeding them values that should fail.
