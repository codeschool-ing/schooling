---
title: Mock providers, and a test that needs no cloud
version: 1
---

A run with `command = plan` creates nothing, and it still talks to AWS. The provider checks its
credentials when it starts and reads every data source during the plan. **So a plan test is only
as available as the API behind it.** Point the lab at a port where nothing listens, and the same
two tests that passed a moment ago do not even start:

```
ana@laptop:~/shop/modules/network$ AWS_ENDPOINT_URL=http://localhost:4567 terraform test
tests/plan.tftest.hcl... in progress
  run "one_subnet_per_entry"... skip
  run "names_carry_the_prefix"... skip
tests/plan.tftest.hcl... tearing down
tests/plan.tftest.hcl... fail
╷
│ Error: Retrieving AWS account details: validating provider credentials: retrieving caller identity from STS: operation error STS: GetCallerIdentity, exceeded maximum number of attempts, 9, https response error StatusCode: 0, RequestID: , request send failed, Post "http://localhost:4567/": dial tcp 127.0.0.1:4567: connect: connection refused
│ 
│ 
╵

Failure! 0 passed, 0 failed, 2 skipped.
```

`skip`, not `fail`: the runs were never attempted, because the provider could not be configured.
On a real account the same thing happens when credentials expire, when a pipeline has none, or
when a contributor has no access to the account at all. A test that depends on any of that is a
test people stop running.

## mock_provider

Since Terraform 1.7, a test file can replace a provider with a mock. **A mock provider keeps the
real provider's schema and never calls its API**: every attribute a real provider would compute,
an id or an ARN, it invents. With the mock, a run can even
`apply`, because applying to a mock creates nothing anywhere. Ana writes the test the previous
section could not, with the endpoint still pointing at nothing:

```hcl
mock_provider "aws" {}

variables {
  name    = "shop"
  cidr    = "10.20.0.0/16"
  subnets = { a = { cidr = "10.20.1.0/24", az = "sa-east-1a" } }
}

run "subnet_is_in_the_vpc" {
  assert {
    condition     = aws_subnet.this["a"].vpc_id == aws_vpc.this.id
    error_message = "Subnet a is not in the module's VPC."
  }
}
```

```
ana@laptop:~/shop/modules/network$ AWS_ENDPOINT_URL=http://localhost:4567 terraform test -filter=tests/unit.tftest.hcl
tests/unit.tftest.hcl... in progress
  run "subnet_is_in_the_vpc"... fail
╷
│ Error: Resource precondition failed
│ 
│   on main.tf line 21, in resource "aws_subnet" "this":
│   21:       condition     = contains(data.aws_availability_zones.here.names, each.value.az)
│     ├────────────────
│     │ data.aws_availability_zones.here.names is empty list of string
│     │ each.value.az is "sa-east-1a"
│ 
│ Zone sa-east-1a is not one this region offers.
╵
tests/unit.tftest.hcl... tearing down
tests/unit.tftest.hcl... fail

Failure! 0 passed, 1 failed.
```

This failure is the most useful thing a mock does on its first day, because it shows the module's
dependency on the outside world. The precondition asks the data source which zones the region
offers, and **a mock answers every list with an empty one**. No zone exists, so no subnet may be
created. The module is right to refuse; the test has to supply the world.

## override_data and override_resource

An override fixes the value of one data source or one resource, for the whole file or inside a
single `run`. Ana gives the zones a real answer and the VPC an id she can assert on:

```hcl
mock_provider "aws" {}

override_data {
  target = data.aws_availability_zones.here
  values = {
    names = ["sa-east-1a", "sa-east-1b", "sa-east-1c"]
  }
}

override_resource {
  target = aws_vpc.this
  values = {
    id = "vpc-0123456789abcdef0"
  }
}

variables {
  name    = "shop"
  cidr    = "10.20.0.0/16"
  subnets = { a = { cidr = "10.20.1.0/24", az = "sa-east-1a" } }
}

run "subnet_is_in_the_vpc" {
  assert {
    condition     = aws_subnet.this["a"].vpc_id == "vpc-0123456789abcdef0"
    error_message = "Subnet a is in ${aws_subnet.this["a"].vpc_id}."
  }

  assert {
    condition     = output.subnet_ids["a"] == aws_subnet.this["a"].id
    error_message = "The output does not carry subnet a's id."
  }
}
```

```
ana@laptop:~/shop/modules/network$ AWS_ENDPOINT_URL=http://localhost:4567 terraform test -filter=tests/unit.tftest.hcl
tests/unit.tftest.hcl... in progress
  run "subnet_is_in_the_vpc"... pass
tests/unit.tftest.hcl... tearing down
tests/unit.tftest.hcl... pass

Success! 1 passed, 0 failed.
```

**One run, no network, and the question from the last section answered**: the subnet's `vpc_id`
is the VPC's id, because the module wires one to the other, and the output carries the subnet's
id. With `-verbose`, the run prints the state the mock produced, and the subnet shows what a mock
is made of:

```
# aws_subnet.this["a"]:
resource "aws_subnet" "this" {
    arn                                 = "jhm1adza"
    availability_zone                   = "sa-east-1a"
    availability_zone_id                = "403cwd9r"
    cidr_block                          = "10.20.1.0/24"
    id                                  = "l0t3iehz"
    ipv6_cidr_block                     = "kugbyqub"
    ipv6_cidr_block_association_id      = "t4n5woph"
    owner_id                            = "cjw54oll"
    private_dns_hostname_type_on_launch = "fpr535ti"
    region                              = "241ub8wp"
    tags                                = {
        "Name" = "shop-a"
    }
    tags_all                            = {}
    vpc_id                              = "vpc-0123456789abcdef0"
}
```

The zone, the range and the tag came from the module. The `vpc_id` came from Ana's override. Every
other computed attribute is eight random characters, the `region` included, and none of them looks
like anything AWS would return. A different run prints different ones.

## What a mock cannot tell you

**A mock proves the module's own logic, and nothing about AWS.** It accepted a subnet without
asking whether the range lies inside the VPC, whether the zone exists or whether the account may
create subnets at all, because none of those questions reach it. The zones in the override are
what Ana believes São Paulo offers; if she is wrong, the mock is wrong with her. That is the trade:
a unit test with a mock runs anywhere, in a pipeline with no credentials and on a laptop with no
network, and the price is that every answer from outside is one you wrote yourself.

`mock_resource` and `mock_data` blocks inside `mock_provider` set defaults for every instance of
a type, where an override aims at one address. An override can also carry `override_during =
plan`, the option the earlier error suggested, which makes its values known during a plan as well
as an apply.
