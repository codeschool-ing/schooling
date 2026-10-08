---
title: Testing that a rule refuses what it should
version: 2
---

The module has two rules: `cidr` must be a range with a mask, and a subnet's zone must be one the
region offers. Both were written for the day somebody passes the wrong value, and **a rule nobody
has seen refuse anything is a rule nobody knows works**. A run that feeds it a bad value would
normally fail, which is the opposite of what a test should report. `expect_failures` turns that
round. Ana's `tests/rules.tftest.hcl`:

```hcl
mock_provider "aws" {}

override_data {
  target = data.aws_availability_zones.here
  values = {
    names = ["sa-east-1a", "sa-east-1b", "sa-east-1c"]
  }
}

variables {
  name    = "shop"
  cidr    = "10.20.0.0/16"
  subnets = { a = { cidr = "10.20.1.0/24", az = "sa-east-1a" } }
}

run "cidr_without_a_mask" {
  command = plan

  variables {
    cidr = "10.20.0.0"
  }

  expect_failures = [var.cidr]
}

run "zone_from_another_region" {
  command = plan

  variables {
    subnets = { a = { cidr = "10.20.1.0/24", az = "us-east-1a" } }
  }

  expect_failures = [aws_subnet.this]
}
```

`expect_failures` lists the objects that must fail in this run: a variable, for its `validation`
blocks, or a resource, for its preconditions and postconditions. **The run passes when those
objects fail**, and fails if one of them lets the value through. The file uses
the same mock and override as the unit test, so it needs no AWS either:

```
ana@laptop:~/shop/modules/network$ AWS_ENDPOINT_URL=http://localhost:4567 terraform test -filter=tests/rules.tftest.hcl
tests/rules.tftest.hcl... in progress
  run "cidr_without_a_mask"... pass
  run "zone_from_another_region"... pass
tests/rules.tftest.hcl... tearing down
tests/rules.tftest.hcl... pass

Success! 2 passed, 0 failed.
```

Two passes, each one a refusal that happened where it was supposed to. `cidr_without_a_mask`
stops at the variable, before any resource is planned. `zone_from_another_region` gets as far as
the subnet, whose precondition looks up `us-east-1a` in the overridden list of São Paulo zones and
does not find it.

## When the rule is broken

Rules get loosened the way any code does: somebody needs a value the rule refuses and simplifies
the condition. Here the `cidr` rule is reduced to "digits, dots and slashes", which still sounds
like a range. The edit, in `variables.tf`:

```sh
sed -i 's|condition     = can(cidrnetmask(var.cidr))|condition     = can(regex("^[0-9./]+$", var.cidr))|' variables.tf
```

```
ana@laptop:~/shop/modules/network$ grep -n "condition" variables.tf
11:    condition     = can(regex("^[0-9./]+$", var.cidr))
ana@laptop:~/shop/modules/network$ AWS_ENDPOINT_URL=http://localhost:4567 terraform test -filter=tests/rules.tftest.hcl
tests/rules.tftest.hcl... in progress
  run "cidr_without_a_mask"... fail
╷
│ Error: expected cidr_block to contain a valid Value, got: 10.20.0.0 with err: invalid CIDR address: 10.20.0.0
│ 
│   with aws_vpc.this,
│   on main.tf line 6, in resource "aws_vpc" "this":
│    6:   cidr_block           = var.cidr
│ 
╵
╷
│ Error: Missing expected failure
│ 
│   on tests/rules.tftest.hcl line 23, in run "cidr_without_a_mask":
│   23:   expect_failures = [var.cidr]
│ 
│ The checkable object, var.cidr, was expected to report an error but did
│ not.
╵
  run "zone_from_another_region"... skip
tests/rules.tftest.hcl... tearing down
tests/rules.tftest.hcl... fail

Failure! 0 passed, 1 failed, 1 skipped.
```

Read the two errors in order, because the first one is a trap. **`10.20.0.0` was still refused,
just not by Ana's rule**: the AWS provider's own check on `cidr_block` caught it, and that check
runs under a mock too, because it belongs to the provider's schema rather than to its API. A test
that only asked "did this run fail?" would have passed and reported the rule healthy.

`expect_failures` asked a narrower question, did `var.cidr` fail, and the answer was no. So the
run fails with `Missing expected failure`, naming the object that let the value through. The
difference matters beyond this module: a rule exists to fail early, at the variable, with the
sentence you wrote for the person who typed the value. The provider's message arrives later and
says something about `cidr_block` that the person calling the module never wrote.

**The run after a failed run is skipped**, as `zone_from_another_region` was here. Runs in a file
go in order and share one state, and Terraform does not carry on past a failure, so one broken
rule can hide whether the next one still works until the first is fixed. Ana puts the rule back
as it was:

```sh
sed -i 's|condition     = can(regex("^\[0-9./\]+$", var.cidr))|condition     = can(cidrnetmask(var.cidr))|' variables.tf
```

## What to test this way

Every `validation`, `precondition` and `postcondition` in a module deserves one run with a value
it must refuse. Pick the value a real person would plausibly type, as `10.20.0.0` is, rather than
something absurd: a rule that refuses nonsense and accepts the near miss is the common way these
rules fail. One bad value per run, as in this file, keeps every refusal attributable to a single rule. A
`check` block is different: it only warns, as lesson 3 showed, so its failure never stops a plan
and is a poor thing to build a test around.
