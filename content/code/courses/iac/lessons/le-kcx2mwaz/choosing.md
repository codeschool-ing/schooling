---
title: Choosing between count and for_each
version: 1
---

Both arguments make copies, and either can be bent to do the other's job. The question that
decides between them is **what identifies a copy**. If nothing does, because the copies are
interchangeable or there is at most one, `count` is the simpler tool. If each copy is a particular
thing that something else depends on, it needs a name, and that is `for_each`.

| situation | use | why |
| --- | --- | --- |
| a resource that exists or not, by a flag | `count = var.x ? 1 : 0` | zero or one copy; read it with `one(...[*])` |
| a fixed number of copies nobody refers to one by one | `count` | the index is never an identity |
| copies that each have a role: subnets, buckets, users | `for_each` over a map | removing one touches one |
| a list of unique, stable strings | `for_each = toset(...)` | the strings become the keys |
| blocks repeated inside one resource | `dynamic` | only when no separate resource exists |
| the same resource in another region or account | `provider` with an alias | or `region`, for the region alone |

`count` and `for_each` cannot both appear in the same block, and a `count` over a list of things
with names is the case to distrust: it is the index problem waiting for someone to edit the list.

## The keys have to be known while planning

There is one rule the table cannot show, and it catches everybody once. **Terraform builds the
addresses during the plan, so the keys of a `for_each`, and the number in a `count`, must be
known before anything is created.** In `~/shop/routes`, Ana attaches each subnet to a route table,
and keys the associations by the subnets' ids:

```hcl
provider "aws" {
  region = "sa-east-1"
}

resource "aws_vpc" "routes" {
  cidr_block = "10.40.0.0/16"
}

resource "aws_subnet" "app" {
  for_each = { web = "10.40.1.0/24", db = "10.40.3.0/24" }

  vpc_id     = aws_vpc.routes.id
  cidr_block = each.value
}

resource "aws_route_table" "app" {
  vpc_id = aws_vpc.routes.id
}

resource "aws_route_table_association" "app" {
  for_each = toset(values(aws_subnet.app)[*].id)

  subnet_id      = each.value
  route_table_id = aws_route_table.app.id
}
```

```
Plan: 4 to add, 0 to change, 0 to destroy.
╷
│ Error: Invalid for_each argument
│ 
│   on main.tf line 21, in resource "aws_route_table_association" "app":
│   21:   for_each = toset(values(aws_subnet.app)[*].id)
│     ├────────────────
│     │ aws_subnet.app is object with 2 attributes
│ 
│ The "for_each" set includes values derived from resource attributes that
│ cannot be determined until apply, and so Terraform cannot determine the
│ full set of keys that will identify the instances of this resource.
│ 
│ When working with unknown values in for_each, it's better to use a map
│ value where the keys are defined statically in your configuration and where
│ only the values contain apply-time results.
│ 
│ Alternatively, you could use the -target planning option to first apply
│ only the resources that the for_each value depends on, and then apply a
│ second time to fully converge.
╵
```

The plan got as far as the VPC, the subnets and the route table, and stopped at the associations.
A subnet's id is invented by AWS when the subnet is created, so during this plan it is unknown,
and a set of unknown strings cannot name anything. Notice that the problem is not the value: the
association needs the id only when it is created, and Terraform is happy to wait for that.
**The problem is using an apply-time value as a key.**

The error's own advice is the fix. Iterate over something whose keys are in the file, and take the
apply-time value out of `each.value`. `aws_subnet.app` is itself a map from the keys Ana wrote,
`web` and `db`, to the subnets:

```hcl
provider "aws" {
  region = "sa-east-1"
}

resource "aws_vpc" "routes" {
  cidr_block = "10.40.0.0/16"
}

resource "aws_subnet" "app" {
  for_each = { web = "10.40.1.0/24", db = "10.40.3.0/24" }

  vpc_id     = aws_vpc.routes.id
  cidr_block = each.value
}

resource "aws_route_table" "app" {
  vpc_id = aws_vpc.routes.id
}

resource "aws_route_table_association" "app" {
  for_each = aws_subnet.app

  subnet_id      = each.value.id
  route_table_id = aws_route_table.app.id
}
```

```
ana@laptop:~/shop/routes$ terraform plan -no-color | grep -E "^  # |^Plan"
  # aws_route_table.app will be created
  # aws_route_table_association.app["db"] will be created
  # aws_route_table_association.app["web"] will be created
  # aws_subnet.app["db"] will be created
  # aws_subnet.app["web"] will be created
  # aws_vpc.routes will be created
Plan: 6 to add, 0 to change, 0 to destroy.
/home/user/schooling/content/code/courses/iac/lab.sh: line 220: name: unbound variable
```

The associations are now `["db"]` and `["web"]`, named after subnets she chose rather than ids
nobody has seen yet. The other way out that the error mentions, `-target`, applies part of the
configuration first; lesson 9 explains why it is an emergency tool and not a design.

## The meta-arguments this lesson did not use

`count`, `for_each` and `provider` are three of the arguments Terraform reads on every resource,
whatever its type. Two more belong to the same family. `depends_on` adds an ordering that the
references do not show, and `lifecycle` changes how a resource is replaced, protected or allowed
to drift. Both decide what happens to a resource over time rather than how many there are, and
lesson 6 is about them.
