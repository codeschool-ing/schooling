---
title: terraform test, and a run that only plans
version: 2
---

`terraform test` is built into Terraform since 1.6. **It reads files ending in `.tftest.hcl`,
written in the same HCL as the module, and runs each `run` block as a plan or an apply against a
state of its own**, never the state of a real deployment. Each `run` carries assertions, and the
command reports which ones held. There is nothing to install and no second language to learn.

Ana's first test file, `tests/plan.tftest.hcl`, plans the module with the shop's real values and
asks two questions:

```hcl
provider "aws" {
  region = "sa-east-1"
}

variables {
  name = "shop"
  cidr = "10.20.0.0/16"
  subnets = {
    a = { cidr = "10.20.1.0/24", az = "sa-east-1a" }
    c = { cidr = "10.20.2.0/24", az = "sa-east-1c" }
  }
}

run "one_subnet_per_entry" {
  command = plan

  assert {
    condition     = length(aws_subnet.this) == 2
    error_message = "Expected one subnet per entry in var.subnets."
  }

  assert {
    condition     = aws_subnet.this["c"].availability_zone == "sa-east-1c"
    error_message = "Subnet c is not in sa-east-1c."
  }
}

run "names_carry_the_prefix" {
  command = plan

  variables {
    name = "shop-dev"
  }

  assert {
    condition     = aws_subnet.this["a"].tags.Name == "shop-dev-a"
    error_message = "Subnet a is called ${aws_subnet.this["a"].tags.Name}."
  }
}
```

Read it from the top. **The `provider` block configures AWS for the test**, because a module
leaves that to whoever calls it, and in a test the caller is the file. **The `variables` block
gives every run the same inputs**, and a `variables` block inside a `run` overrides them for that
run only, which is how `names_carry_the_prefix` tries a second name without repeating the subnets.
**`command = plan` stops each run after the plan**: nothing is created, and the assertions are
evaluated against the plan Terraform would make.

An `assert` is a `condition` and an `error_message`, the same pair as a validation rule. Inside
it you refer to the module's resources by their addresses, `aws_subnet.this["c"]`, and to its
outputs as `output.vpc_id`. The message is a template, so it can say what it found:

```
ana@laptop:~/shop/modules/network$ terraform test
tests/plan.tftest.hcl... in progress
  run "one_subnet_per_entry"... pass
  run "names_carry_the_prefix"... pass
tests/plan.tftest.hcl... tearing down
tests/plan.tftest.hcl... pass

Success! 2 passed, 0 failed.
```

Each file is set up, its runs go in order, and the file is torn down. For a file that only
planned there is nothing to destroy, but the line appears all the same.

## A test earning its keep

A month later a colleague decides the subnets should say what they are, and changes one tag in
`main.tf`. The change is reasonable, and it renames every subnet the module has ever created. The
colleague's command was:

```sh
sed -i 's/Name = "${var.name}-${each.key}"/Name = "${var.name}-subnet-${each.key}"/' main.tf
```

The test notices:

```
ana@laptop:~/shop/modules/network$ grep -n "Name =" main.tf
8:  tags                 = { Name = var.name }
17:  tags              = { Name = "${var.name}-subnet-${each.key}" }
ana@laptop:~/shop/modules/network$ terraform test
tests/plan.tftest.hcl... in progress
  run "one_subnet_per_entry"... pass
  run "names_carry_the_prefix"... fail
╷
│ Error: Test assertion failed
│ 
│   on tests/plan.tftest.hcl line 36, in run "names_carry_the_prefix":
│   36:     condition     = aws_subnet.this["a"].tags.Name == "shop-dev-a"
│     ├────────────────
│     │ Diff:
│     │ --- actual
│     │ +++ expected
│     │ - "shop-dev-subnet-a"
│     │ + "shop-dev-a"
│ 
│ 
│ Subnet a is called shop-dev-subnet-a.
╵
tests/plan.tftest.hcl... tearing down
tests/plan.tftest.hcl... fail

Failure! 1 passed, 1 failed.
```

**The failure names the run, the file, the line and the condition**, then shows a diff of the two
sides, then prints Ana's message with the real name in it. Anything that finds subnets by their
`Name` tag, as lesson 5's data sources do, would have stopped finding them, and nobody had to
remember that; the test did. Whether the change is right is
still a decision for a person. The test made sure it is a decision and not an accident.

Until that decision is made, Ana puts the tag back as it was:

```sh
sed -i 's/Name = "${var.name}-subnet-${each.key}"/Name = "${var.name}-${each.key}"/' main.tf
```

## What a plan cannot answer

A plan knows what you wrote and what AWS already has. It does not know the ids AWS will invent.
Ana tries to assert, in a plan, that a subnet lands in the module's own VPC, in a file of its own,
`tests/link.tftest.hcl`:

```hcl
provider "aws" {
  region = "sa-east-1"
}

variables {
  name    = "shop"
  cidr    = "10.20.0.0/16"
  subnets = { a = { cidr = "10.20.1.0/24", az = "sa-east-1a" } }
}

run "subnet_is_in_the_vpc" {
  command = plan

  assert {
    condition     = aws_subnet.this["a"].vpc_id == aws_vpc.this.id
    error_message = "Subnet a is not in the module's VPC."
  }
}
```

```
ana@laptop:~/shop/modules/network$ terraform test -filter=tests/link.tftest.hcl
tests/link.tftest.hcl... in progress
  run "subnet_is_in_the_vpc"... fail
╷
│ Error: Unknown condition value
│ 
│   on tests/link.tftest.hcl line 15, in run "subnet_is_in_the_vpc":
│   15:     condition     = aws_subnet.this["a"].vpc_id == aws_vpc.this.id
│     ├────────────────
│     │ aws_subnet.this["a"].vpc_id is a string
│     │ aws_vpc.this.id is a string
│ 
│ Condition expression could not be evaluated at this time. This means you
│ have executed a `run` block with `command = plan` and one of the values
│ your condition depended on is not known until after the plan has been
│ applied. Either remove this value from your condition, or execute an
│ `apply` command from this `run` block. Alternatively, if there is an
│ override for this value, you can make it available during the plan phase by
│ setting `override_during = plan` in the `override_` block.
╵
tests/link.tftest.hcl... tearing down
tests/link.tftest.hcl... fail

Failure! 0 passed, 1 failed.
```

Both sides are strings Terraform does not know yet, so the condition cannot be evaluated, and
Terraform refuses to call that a pass. The message names the ways out: drop the value, apply the
run, or supply the value yourself with an override. **An assertion in a plan can only be about
what is known at plan time**: the values you passed in, and anything computed from them alone. The
next section answers this one without AWS, and the last section answers it with AWS. The file was
only there to show the error, so Ana deletes it, `rm tests/link.tftest.hcl`.

`terraform test` with no arguments runs every test file in `tests/` and in the module's own
directory, in alphabetical order. `-filter=tests/link.tftest.hcl` runs one file, as above, and
`-verbose` prints the plan or the state of each run as it goes.
