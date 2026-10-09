---
title: An end-to-end run, against moto
version: 2
---

Everything so far asked Terraform what it would do. **An end-to-end test does it**: it applies the
module, asks AWS what now exists, and destroys it all again. It is the slowest rung and the only
one that can find out whether AWS agrees with the plan. Terraform's own help says plainly what the
command is for:

```
ana@laptop:~/shop/modules/network$ terraform test -h
Usage: terraform [global options] test [options]

  Executes automated integration tests against the current Terraform
  configuration.

  Terraform will search for .tftest.hcl files within the current configuration
  and testing directories. Terraform will then execute the testing run blocks
  within any testing files in order, and verify conditional checks and
  assertions against the created infrastructure.

  This command creates real infrastructure and will attempt to clean up the
  testing infrastructure on completion. Monitor the output carefully to ensure
  this cleanup process is successful.
```

In this course "real infrastructure" is moto, so nothing below was billed. On a real account
every run of this file creates a VPC and two subnets, and costs what they cost while they exist.

## Build, then ask AWS

The test file is `tests/e2e.tftest.hcl`:

```hcl
provider "aws" {
  region = "sa-east-1"
}

variables {
  name = "shop-e2e"
  cidr = "10.20.0.0/16"
  subnets = {
    a = { cidr = "10.20.1.0/24", az = "sa-east-1a" }
    c = { cidr = "10.20.2.0/24", az = "sa-east-1c" }
  }
}

run "build" {
  command = apply

  assert {
    condition     = alltrue([for s in aws_subnet.this : s.vpc_id == aws_vpc.this.id])
    error_message = "A subnet landed outside the module's VPC."
  }
}

run "aws_agrees" {
  module {
    source = "./tests/aws"
  }

  variables {
    vpc_id = run.build.vpc_id
  }

  assert {
    condition     = data.aws_vpc.built.cidr_block == "10.20.0.0/16"
    error_message = "AWS reports the VPC as ${data.aws_vpc.built.cidr_block}."
  }

  assert {
    condition     = length(data.aws_subnets.built.ids) == 2
    error_message = "AWS reports ${length(data.aws_subnets.built.ids)} subnets in the VPC."
  }
}
```

`build` applies the module and checks that every subnet sits in the module's VPC, the assertion
that failed in a plan, now evaluated against ids AWS actually returned. But that is still Terraform
grading its own homework, since the values come from what Terraform recorded. **`aws_agrees` asks
AWS instead**, through a helper module: a run's `module` block swaps the module under test for
another one, here a directory of data sources that read the VPC back by id,
`tests/aws/main.tf`:

```hcl
# A helper module for the tests: it reads the VPC back from AWS.
variable "vpc_id" {
  type = string
}

data "aws_vpc" "built" {
  id = var.vpc_id
}

data "aws_subnets" "built" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}
```

The id travels between runs as `run.build.vpc_id`, the output of an earlier run, which is how one
run hands a value to the next. A helper module is a module like any other, so `terraform init`
has to install it before the test can use it:

```
ana@laptop:~/shop/modules/network$ terraform init
Initializing the backend...

Initializing modules...
- test.tests.e2e.aws_agrees in tests/aws

Initializing provider plugins...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Using previously-installed hashicorp/aws v6.67.0

```

```
ana@laptop:~/shop/modules/network$ terraform test -filter=tests/e2e.tftest.hcl
tests/e2e.tftest.hcl... in progress
  run "build"... pass
  run "aws_agrees"... pass
tests/e2e.tftest.hcl... tearing down
tests/e2e.tftest.hcl... pass

Success! 2 passed, 0 failed.
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"One end-to-end test file, left to right. The run called build applies the module and creates a VPC and two subnets in AWS, here moto. The run called aws_agrees uses a helper module whose data sources read the VPC and its subnets back from AWS. Then the test tears down and destroys what build created.\"><defs><marker id=\"ee-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"ee-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"ee-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"30\" y=\"30\" width=\"190\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">run \"build\"</text><text x=\"125.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">applies the module</text><rect x=\"265\" y=\"30\" width=\"190\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">run \"aws_agrees\"</text><text x=\"360.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a helper module reads</text><rect x=\"500\" y=\"30\" width=\"190\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"595.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">tearing down</text><text x=\"595.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">destroys in reverse</text><path d=\"M222 65 L262 65\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ee-ah-wire)\"></path><path d=\"M457 65 L497 65\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ee-ah-wire)\"></path><rect x=\"30\" y=\"180\" width=\"660\" height=\"50\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">AWS (in the lab, moto)</text><path d=\"M125 102 L125 177\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ee-ah-phosphor)\"></path><text x=\"135.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">creates a VPC, two subnets</text><path d=\"M360 177 L360 102\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ee-ah-phosphor)\"></path><text x=\"370.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">reads them back</text><path d=\"M595 102 L595 177\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ee-ah-amber)\"></path><text x=\"585.0\" y=\"140.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">destroys them</text></svg>", "caption": "An end-to-end test builds the real thing, asks AWS about it, and removes it."}
```

`tearing down` is where Terraform destroyed the file's resources, in reverse order of creation. After
the run, AWS holds only the default VPC moto creates in every region, as AWS does:

```
ana@laptop:~/shop/modules/network$ aws ec2 describe-vpcs --query "Vpcs[].[CidrBlock,IsDefault]" --output text
172.31.0.0/16	True
```

## What only an apply finds

Here is the case the earlier rungs could not catch. A subnet of `10.30.1.0/24` in a VPC of
`10.20.0.0/16` is a valid range, in a real zone, of the right type. `validate` has no values to
look at, the plan has no reason to object, and a mock accepts anything. AWS refuses it, as
`tests/range.tftest.hcl` shows:

```hcl
provider "aws" {
  region = "sa-east-1"
}

variables {
  name    = "shop-range"
  cidr    = "10.20.0.0/16"
  subnets = { b = { cidr = "10.30.1.0/24", az = "sa-east-1a" } }
}

run "plan_accepts_it" {
  command = plan
}

run "apply_refuses_it" {
  command = apply
}
```

```
ana@laptop:~/shop/modules/network$ terraform test -filter=tests/range.tftest.hcl
tests/range.tftest.hcl... in progress
  run "plan_accepts_it"... pass
  run "apply_refuses_it"... fail
╷
│ Error: creating EC2 Subnet: operation error EC2: CreateSubnet, https response error StatusCode: 400, RequestID: qEQGGh8HNnVprVhob3z5gwJyohxQIqEXuYWJ29WOm5bUT5WKwxJp, api error InvalidSubnet.Range: The CIDR '10.30.1.0/24' is invalid.
│ 
│   with aws_subnet.this["b"],
│   on main.tf line 11, in resource "aws_subnet" "this":
│   11: resource "aws_subnet" "this" {
│ 
╵
tests/range.tftest.hcl... tearing down
tests/range.tftest.hcl... fail

Failure! 1 passed, 1 failed.
ana@laptop:~/shop/modules/network$ aws ec2 describe-vpcs --query "Vpcs[].[CidrBlock,IsDefault]" --output text
172.31.0.0/16	True
```

**The plan passed, and the apply of the same values failed**, with the API's own error code,
`InvalidSubnet.Range`. During the teardown, Terraform destroyed the VPC the run had already created, and
`describe-vpcs` shows nothing left over. That cleanup is what the help text tells you to watch: on a real
account, whatever a failed teardown leaves behind stays, and is billed, until somebody removes it.

An end-to-end failure is expensive to find, so the right response is to move the knowledge up the
ladder. Ana adds a rule to `subnets` that compares each subnet's network with the VPC's; it needs
Terraform 1.9, because the condition reads a second variable. Then she adds a run to
`rules.tftest.hcl` that expects the rule to refuse. In `variables.tf` the new block goes inside
`variable "subnets"`, after its `description` and a blank line, and the run goes at the end of the
test file, after a blank line:

```
ana@laptop:~/shop/modules/network$ tail -n 10 variables.tf
  validation {
    # The subnet's first address, cut to the VPC's prefix, is the VPC's own
    # network address. If var.cidr is itself broken, its rule says so.
    condition = try(alltrue([
      for s in values(var.subnets) :
      cidrhost("${split("/", s.cidr)[0]}/${split("/", var.cidr)[1]}", 0) == cidrhost(var.cidr, 0)
    ]), true)
    error_message = "Every subnet must lie inside the VPC's range, ${var.cidr}."
  }
}
ana@laptop:~/shop/modules/network$ tail -n 9 tests/rules.tftest.hcl
run "subnet_outside_the_vpc" {
  command = plan

  variables {
    subnets = { b = { cidr = "10.30.1.0/24", az = "sa-east-1a" } }
  }

  expect_failures = [var.subnets]
}
```

```
ana@laptop:~/shop/modules/network$ rm tests/range.tftest.hcl
ana@laptop:~/shop/modules/network$ AWS_ENDPOINT_URL=http://localhost:4567 terraform test -filter=tests/rules.tftest.hcl
tests/rules.tftest.hcl... in progress
  run "cidr_without_a_mask"... pass
  run "zone_from_another_region"... pass
  run "subnet_outside_the_vpc"... pass
tests/rules.tftest.hcl... tearing down
tests/rules.tftest.hcl... pass

Success! 3 passed, 0 failed.
```

The range file has done its job and goes. The same mistake now fails at the variable, with Ana's
sentence, in a test that needs no AWS. The whole suite, with the end-to-end file still in it:

```
ana@laptop:~/shop/modules/network$ terraform test
tests/e2e.tftest.hcl... in progress
  run "build"... pass
  run "aws_agrees"... pass
tests/e2e.tftest.hcl... tearing down
tests/e2e.tftest.hcl... pass
tests/plan.tftest.hcl... in progress
  run "one_subnet_per_entry"... pass
  run "names_carry_the_prefix"... pass
tests/plan.tftest.hcl... tearing down
tests/plan.tftest.hcl... pass
tests/rules.tftest.hcl... in progress
  run "cidr_without_a_mask"... pass
  run "zone_from_another_region"... pass
  run "subnet_outside_the_vpc"... pass
tests/rules.tftest.hcl... tearing down
tests/rules.tftest.hcl... pass
tests/unit.tftest.hcl... in progress
  run "subnet_is_in_the_vpc"... pass
tests/unit.tftest.hcl... tearing down
tests/unit.tftest.hcl... pass

Success! 8 passed, 0 failed.
```

## Terratest, and how often to run this

The other common way to write these tests is **Terratest**, a Go library from Gruntwork: a Go
test runs `terraform apply`, calls the cloud's own SDK to inspect the result, and runs `terraform
destroy` in a deferred function. It reaches further than a helper module can, for instance making
an HTTP request to a server it just created, at the price of a second language. It is named here
and was not run for this lesson, because it needs Go, which this course does not install.

Whichever you use, run end-to-end tests less often than the rest: on a pull request that changes
the module, or nightly, in an account of their own that holds nothing else. Lesson 15 puts the
cheap rungs on every commit.
