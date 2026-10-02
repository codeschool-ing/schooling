---
title: for expressions and splats
version: 1
---

A `for` expression builds one collection out of another. It is the nearest thing HCL has to a
loop, and it is not a loop in the sense of a statement that runs: **it is an expression, and its
whole result is a value**, computed at once. It is how a list of zones becomes a list of names, or
a map of zone to range.

The brackets around it decide what comes out. **Square brackets make a list; braces make a map**,
and the map form needs a `=>` between the key and the value:

```
ana@laptop:~/shop$ echo '[for az in var.network.azs : "${local.name}-${az}"]' | terraform console
[
  "shop-dev-sa-east-1a",
  "shop-dev-sa-east-1c",
]
ana@laptop:~/shop$ echo '{ for i, az in var.network.azs : az => cidrsubnet(var.network.cidr, 8, i + 1) }' | terraform console
{
  "sa-east-1a" = "10.20.1.0/24"
  "sa-east-1c" = "10.20.2.0/24"
}
ana@laptop:~/shop$ echo '[for az in var.network.azs : az if endswith(az, "c")]' | terraform console
[
  "sa-east-1c",
]
```

The first line turned each zone into a name. The second took two names before the `in`, the
position and the element, and used the position for the `netnum` that `cidrsubnet` wants, which
is the arithmetic of the functions section done once per zone. The third added an `if`, which
keeps only the elements for which the condition is true.

That second result, a map from zone to range, is worth looking at twice. It is exactly the shape
that `for_each` in lesson 4 takes to create one subnet per entry, and building it with a `for`
expression is how a list someone typed becomes resources keyed by something meaningful.

## Two items, one key

A map cannot hold the same key twice, and a `for` that produces one is an error rather than a
quiet overwrite:

```
ana@laptop:~/shop$ echo '{ for az in var.network.azs : substr(az, 0, 9) => az }' | terraform console
╷
│ Error: Duplicate object key
│ 
│   on <console-input> line 1:
│   (source code not available)
│ 
│ Two different items produced the key "sa-east-1" in this 'for' expression.
│ If duplicates are expected, use the ellipsis (...) after the value
│ expression to enable grouping by key.
╵

ana@laptop:~/shop$ echo '{ for az in var.network.azs : substr(az, 0, 9) => az... }' | terraform console
{
  "sa-east-1" = [
    "sa-east-1a",
    "sa-east-1c",
  ]
}
```

`substr(az, 0, 9)` cut both zones down to the region, `sa-east-1`, so both items claimed the same
key. **The error suggests the fix, and the fix is a different expression, not a different
spelling**: an ellipsis after the value groups every item with that key into a list. Whether you
want the grouping or the error depends on whether two items sharing a key is a fact of the data
or a mistake in it.

## Splats

The commonest `for` reads one attribute from every element of a list, and it has a short form,
the **splat** `[*]`:

```
ana@laptop:~/shop$ echo '[aws_subnet.a, aws_subnet.c][*].cidr_block' | terraform console
[
  "10.20.1.0/24",
  "10.20.2.0/24",
]
```

`[aws_subnet.a, aws_subnet.c][*].cidr_block` is the same as
`[for s in [aws_subnet.a, aws_subnet.c] : s.cidr_block]`. The subnets exist now, so the console
read their ranges from the state. Splats are seen most on resources created with `count`, where
`aws_subnet.private[*].id` reads every id at once; that is lesson 4.

## A for expression in an output

The same expression works anywhere an expression does. Ana adds an output that says which range
each subnet got:

```hcl
output "subnet_cidrs" {
  value = {
    for s in [aws_subnet.a, aws_subnet.c] : s.tags["Name"] => s.cidr_block
  }
}
```

```
ana@laptop:~/shop$ terraform apply -auto-approve
aws_vpc.shop: Refreshing state... [id=vpc-1421f4c581e114d46]
aws_subnet.a: Refreshing state... [id=subnet-e30146a6aa7865aaf]
aws_subnet.c: Refreshing state... [id=subnet-719532a052c2db8ea]

Changes to Outputs:
  + subnet_cidrs = {
      + shop-dev-a = "10.20.1.0/24"
      + shop-dev-c = "10.20.2.0/24"
    }

You can apply this plan to save these new output values to the Terraform
state, without changing any real infrastructure.

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

subnet_cidrs = {
  "shop-dev-a" = "10.20.1.0/24"
  "shop-dev-c" = "10.20.2.0/24"
}
ana@laptop:~/shop$ terraform output subnet_cidrs
{
  "shop-dev-a" = "10.20.1.0/24"
  "shop-dev-c" = "10.20.2.0/24"
}
```

**Nothing in AWS changed**, and the apply says so: zero added, changed or destroyed. Only the
output was new, and Terraform wrote it into the state. Keying it by the `Name` tag rather than by
the zone is a choice with a reason: two subnets may one day share a zone, and the next section
shows a plan where they would have.
