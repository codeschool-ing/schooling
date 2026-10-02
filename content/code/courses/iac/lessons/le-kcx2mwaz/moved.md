---
title: Changing an address without replacing anything
version: 1
---

The scratch directory proved that `for_each` is the better shape. The shop's real network,
though, was built with `count`, and its state knows the subnets as `aws_subnet.app[0]`, `[1]` and
`[2]`. Switching the block to `for_each` changes every one of those addresses, and **an address
is the only thing Terraform matches on**. It does not look at the ranges and conclude that
`app[0]` and `app["web"]` are the same subnet. As far as it can tell, three resources left the
file and three new ones arrived.

Here is Ana's `main.tf` with the subnets rewritten as a map, the same one the scratch directory
used:

```hcl
variable "subnets" {
  type = map(string)
  default = {
    web = "10.20.1.0/24"
    app = "10.20.2.0/24"
    db  = "10.20.3.0/24"
  }
}

variable "public" {
  type    = bool
  default = true
}

resource "aws_vpc" "shop" {
  cidr_block = "10.20.0.0/16"
  tags       = { Name = "shop" }
}

resource "aws_subnet" "app" {
  for_each = var.subnets

  vpc_id     = aws_vpc.shop.id
  cidr_block = each.value
  tags       = { Project = "shop" }
}

resource "aws_internet_gateway" "shop" {
  count = var.public ? 1 : 0

  vpc_id = aws_vpc.shop.id
}
```

And here is the plan, filtered down to its headings with `grep` so the decision fits on one
screen:

```
ana@laptop:~/shop/network$ terraform plan -no-color | grep -E "^  # |^Plan"
  # aws_subnet.app[0] will be destroyed
  # (because resource does not use count)
  # aws_subnet.app[1] will be destroyed
  # (because resource does not use count)
  # aws_subnet.app[2] will be destroyed
  # (because resource does not use count)
  # aws_subnet.app["app"] will be created
  # aws_subnet.app["db"] will be created
  # aws_subnet.app["web"] will be created
Plan: 3 to add, 0 to change, 3 to destroy.
```

**Three subnets destroyed and three created, to end up with exactly what exists now.** The reason
on each destroy, `resource does not use count`, is Terraform saying that the old addresses have
nowhere to go. In a real account this plan would empty the subnets of everything in them, for a
change that was meant to be cosmetic.

## Telling Terraform where each one went

A `moved` block says that the resource known by one address is now known by another. Ana writes
one per subnet, in a file of its own, pairing each old index with the key for the same range:

```hcl
moved {
  from = aws_subnet.app[0]
  to   = aws_subnet.app["web"]
}

moved {
  from = aws_subnet.app[1]
  to   = aws_subnet.app["app"]
}

moved {
  from = aws_subnet.app[2]
  to   = aws_subnet.app["db"]
}
```

The plan changes completely:

```
Terraform will perform the following actions:

  # aws_subnet.app[1] has moved to aws_subnet.app["app"]
    resource "aws_subnet" "app" {
        id                                             = "subnet-a4a6adb3ebc89f9b9"
        tags                                           = {
            "Project" = "shop"
        }
        # (21 unchanged attributes hidden)
    }

  # aws_subnet.app[2] has moved to aws_subnet.app["db"]
    resource "aws_subnet" "app" {
        id                                             = "subnet-151a62e4e9c8c6cb4"
        tags                                           = {
            "Project" = "shop"
        }
        # (21 unchanged attributes hidden)
    }

  # aws_subnet.app[0] has moved to aws_subnet.app["web"]
    resource "aws_subnet" "app" {
        id                                             = "subnet-9485478c607d4a202"
        tags                                           = {
            "Project" = "shop"
        }
        # (21 unchanged attributes hidden)
    }

Plan: 0 to add, 0 to change, 0 to destroy.
```

Every line now says **has moved to**, and the summary is `0 to add, 0 to change, 0 to destroy`.
The ids are the ones the first apply printed for the same ranges: the same subnets, filed
under new names. Applying writes the new addresses into the state and calls nothing in AWS:

```
Plan: 0 to add, 0 to change, 0 to destroy.

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

gateway = "igw-d64e0925c422c6e13"
ana@laptop:~/shop/network$ terraform state list
aws_internet_gateway.shop[0]
aws_subnet.app["app"]
aws_subnet.app["db"]
aws_subnet.app["web"]
aws_vpc.shop
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Three columns. The state before has app[0], app[1] and app[2]. Each moves to a new address in the state after: app[\"web\"], app[\"app\"] and app[\"db\"]. Both point at the same three subnets in AWS, whose ranges and ids do not change.\"><defs><marker id=\"mv-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"95.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">state, before</text><text x=\"345.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">state, after</text><text x=\"615.0\" y=\"26.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">in AWS</text><rect x=\"10\" y=\"50\" width=\"170\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"95.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">aws_subnet.app[0]</text><path d=\"M182 70 L248 70\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mv-ah-phosphor)\"></path><text x=\"215.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--phosphor)\">moved</text><rect x=\"250\" y=\"50\" width=\"190\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"345.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">aws_subnet.app[\"web\"]</text><path d=\"M442 70 L528 70\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"530\" y=\"50\" width=\"170\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">subnet</text><text x=\"615.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.20.1.0/24</text><rect x=\"10\" y=\"112\" width=\"170\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"95.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">aws_subnet.app[1]</text><path d=\"M182 132 L248 132\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mv-ah-phosphor)\"></path><text x=\"215.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--phosphor)\">moved</text><rect x=\"250\" y=\"112\" width=\"190\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"345.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">aws_subnet.app[\"app\"]</text><path d=\"M442 132 L528 132\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"530\" y=\"112\" width=\"170\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">subnet</text><text x=\"615.0\" y=\"141.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.20.2.0/24</text><rect x=\"10\" y=\"174\" width=\"170\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"95.0\" y=\"194.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">aws_subnet.app[2]</text><path d=\"M182 194 L248 194\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mv-ah-phosphor)\"></path><text x=\"215.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--phosphor)\">moved</text><rect x=\"250\" y=\"174\" width=\"190\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"345.0\" y=\"194.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">aws_subnet.app[\"db\"]</text><path d=\"M442 194 L528 194\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"530\" y=\"174\" width=\"170\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">subnet</text><text x=\"615.0\" y=\"203.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.20.3.0/24</text><text x=\"360.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">Only the names in the state change. Nothing in AWS is created or destroyed.</text></svg>", "caption": "A moved block renames an entry in the state. The resource it points at stays where it is, with the same id."}
```

**Check the pairing in the plan, not in your head.** Had Ana paired `app[0]` with `"app"` by
mistake, Terraform would have moved it there and then found that the range in the file is
`10.20.2.0/24` while the subnet holds `10.20.1.0/24`. The plan would have shown a replacement
under the move. A move that is right is a plan with nothing to add, change or destroy.

## Why a block in a file, and how long it stays

`moved` arrived in Terraform 1.1. Before it, the only way was to edit the state from the command
line with `terraform state mv`, which lesson 7 shows and which still works. The block has two
advantages over the command. It is part of the change, so a reviewer reads it in the same pull
request as the rewritten resource. And it applies wherever the configuration is applied: every
environment that keeps its own state, and every person using a module you published, gets the
same move on their next plan without anybody running a command for them.

The same block renames a resource as well, from `aws_subnet.app` to `aws_subnet.private` for
instance, which is otherwise the same three-destroys-three-creates plan.

Once every state that used the old addresses has been applied, the `moved` blocks have nothing
left to do and can be deleted. In a module other people call, you cannot know when that is, so
they stay; lesson 10 comes back to this when it talks about breaking changes.
