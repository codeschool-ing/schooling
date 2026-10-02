---
title: When a data source is read
version: 1
---

Every data source so far was read at the start of the plan, before Terraform worked out anything
else. That is the normal case, and it is why the VPC's id appeared in the plan as a real value.
**But a data source can only be read once everything it is given is known**, and inside a
configuration that also creates things, that is not always at the start.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"One run of terraform apply, left to right. During the plan, Terraform reads every data source whose arguments are known: the caller identity and the VPC. Then it builds the plan. During the apply, it creates the subnet, and only then reads the availability zone, whose argument comes from the subnet, and a data source with depends_on.\"><defs><marker id=\"tm-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"300\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"35.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">plan</text><rect x=\"400\" y=\"20\" width=\"300\" height=\"230\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"415.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">apply</text><rect x=\"40\" y=\"60\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;= data.aws_caller_identity</text><rect x=\"40\" y=\"115\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;= data.aws_vpc.shop</text><text x=\"170.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">arguments known: read now,</text><text x=\"170.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">values shown in the plan</text><rect x=\"420\" y=\"60\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">+ aws_subnet.app</text><rect x=\"420\" y=\"125\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">&lt;= data.aws_availability_zone.app</text><rect x=\"420\" y=\"180\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&lt;= data.aws_subnets.app</text><path d=\"M550 101 L550 123\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tm-ah-amber)\"></path><path d=\"M322 135 L398 135\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tm-ah-paper-dim)\"></path><text x=\"360.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">then</text></svg>", "caption": "When each data source is read: at plan time if everything it is given is known, during the apply if it waits for a resource."}
```

Ana adds a subnet of her own to the shared VPC, for the application tier, and wants to know the
**zone id** of the zone it lands in. Zone names like `sa-east-1a` are shuffled per account, so two
accounts mean different buildings by the same name; zone ids name the same one everywhere, which is
what you compare across accounts. She also wants a by-tag lookup of every subnet in the `app` tier:

```hcl
resource "aws_subnet" "app" {
  vpc_id            = data.aws_vpc.shop.id
  cidr_block        = "10.20.3.0/24"
  availability_zone = "sa-east-1a"
  tags = {
    Name = "shop-app-a"
    Tier = "app"
  }
}

data "aws_availability_zone" "app" {
  name = aws_subnet.app.availability_zone
}

data "aws_subnets" "app" {
  tags = {
    Tier = "app"
  }
}

output "app_zone_id" {
  value = data.aws_availability_zone.app.zone_id
}

output "app_subnets" {
  value = data.aws_subnets.app.ids
}
```

The plan treats the two lookups differently:

```
Terraform used the selected providers to generate the following execution
plan. Resource actions are indicated with the following symbols:
  + create
 <= read (data resources)

Terraform will perform the following actions:

  # data.aws_availability_zone.app will be read during apply
  # (depends on a resource or a module with changes pending)
 <= data "aws_availability_zone" "app" {
      + group_long_name      = (known after apply)
      + group_name           = (known after apply)
      + id                   = (known after apply)
      + name                 = "sa-east-1a"
      + name_suffix          = (known after apply)
      + network_border_group = (known after apply)
      + opt_in_status        = (known after apply)
      + parent_zone_id       = (known after apply)
      + parent_zone_name     = (known after apply)
      + region               = (known after apply)
      + state                = (known after apply)
      + zone_id              = (known after apply)
      + zone_type            = (known after apply)
    }
```
```
Plan: 1 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + app_subnets    = []
  + app_zone_id    = (known after apply)
```

`<=` is the symbol for a read, and `will be read during apply` says when. The zone's `name` is
already known (it is written in the subnet's block), and the read is deferred anyway, for the reason
on the second comment line: **it refers to a resource with changes pending**, and Terraform will not
read anything that depends on a resource before that resource is in its final state. So the zone id
is `(known after apply)`, like an attribute of something not yet created. The other reason you will
see on that line is `config refers to values not yet known`, which the next section produces.

The tag lookup has no reference to the subnet, so nothing told Terraform to wait. It was read at the
start, before the subnet existed, and found nothing: `app_subnets = []`. The apply shows both
consequences in order:

```
aws_subnet.app: Creating...
aws_subnet.app: Creation complete after 0s [id=subnet-79bc1d30d383e583f]
data.aws_availability_zone.app: Reading...
data.aws_availability_zone.app: Read complete after 0s [id=sa-east-1a]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

account_id = "123456789012"
app_subnets = tolist([])
app_zone_id = "sae1-az1"
```

The subnet is created, then the zone is read, and its id comes out as `sae1-az1`. **And the tag
lookup still says the list is empty**, because it was answered during the plan and an apply carries
out the plan it was given. The answer is only wrong until the next run, which reads it again:

```

Changes to Outputs:
  ~ app_subnets    = [
      + "subnet-79bc1d30d383e583f",
    ]
```

That is the trap in a lookup that finds something the same configuration creates. Nothing failed;
for one apply the output was a confident and false empty list, and anything built from it would have
been built on nothing. The fix is to say what the lookup waits for, with **`depends_on`**:

```hcl
resource "aws_subnet" "app" {
  vpc_id            = data.aws_vpc.shop.id
  cidr_block        = "10.20.3.0/24"
  availability_zone = "sa-east-1a"
  tags = {
    Name  = "shop-app-a"
    Tier  = "app"
    Owner = "ana"
  }
}

data "aws_availability_zone" "app" {
  name = aws_subnet.app.availability_zone
}

data "aws_subnets" "app" {
  tags = {
    Tier = "app"
  }
  depends_on = [aws_subnet.app]
}

output "app_zone_id" {
  value = data.aws_availability_zone.app.zone_id
}

output "app_subnets" {
  value = data.aws_subnets.app.ids
}
```

`depends_on` on a data source has a cost, and it shows up as soon as the subnet has any change at
all. Here Ana also added an `Owner` tag, which is an in-place update, and the lookup is deferred
again, taking the output with it:

```
  # data.aws_subnets.app will be read during apply
  # (depends on a resource or a module with changes pending)
 <= data "aws_subnets" "app" {
      + id     = (known after apply)
      + ids    = (known after apply)
      + region = (known after apply)
      + tags   = {
          + "Tier" = "app"
        }
    }
```
```
Plan: 0 to add, 1 to change, 0 to destroy.

Changes to Outputs:
  ~ app_subnets    = [
      - "subnet-79bc1d30d383e583f",
    ] -> (known after apply)
  ~ app_zone_id    = "sae1-az1" -> (known after apply)
```

**A deferred read makes everything built from it unknown in the plan.** For an output that costs
nothing. For an argument that forces replacement, an unknown value in the plan is a planned
replacement, so `depends_on` on a data source belongs where the dependency is real, and nowhere as a
precaution. Most of the time the better answer is the one the zone lookup already had: refer to the
resource's own attributes, and the ordering comes with the reference.
