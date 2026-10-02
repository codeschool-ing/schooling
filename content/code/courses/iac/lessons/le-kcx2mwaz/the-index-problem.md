---
title: The index problem
version: 1
---

**A `count` address is a position, not a name.** `aws_subnet.app[1]` does not mean "the subnet
for 10.20.2.0/24"; it means "whatever is second in the list". Remove something from the middle of
the list and every element after it moves down one place. Terraform matches the file to the state
by address, so it does not see one subnet removed. It sees copies whose arguments changed.

Ana decides the shop no longer needs the middle subnet. She does not touch `main.tf`; she sets
the variable in a `terraform.tfvars` beside it, which lesson 2 showed overrides the default:

```hcl
subnets = ["10.20.1.0/24", "10.20.3.0/24"]
```

What she means is "one subnet fewer". Here is what the plan says, with the middle cut down to the
part that matters:

```
Terraform will perform the following actions:

  # aws_subnet.app[1] must be replaced
-/+ resource "aws_subnet" "app" {
      ~ arn                                            = "arn:aws:ec2:sa-east-1:123456789012:subnet/subnet-d8ac29fa3f1f0aab7" -> (known after apply)
      ~ availability_zone                              = "sa-east-1b" -> (known after apply)
      ~ availability_zone_id                           = "sae1-az2" -> (known after apply)
      ~ cidr_block                                     = "10.20.2.0/24" -> "10.20.3.0/24" # forces replacement
      - enable_lni_at_device_index                     = 0 -> null
      ~ id                                             = "subnet-d8ac29fa3f1f0aab7" -> (known after apply)
      + ipv6_cidr_block                                = (known after apply)
      + ipv6_cidr_block_association_id                 = (known after apply)
      - map_customer_owned_ip_on_launch                = false -> null
      ~ owner_id                                       = "123456789012" -> (known after apply)
      ~ private_dns_hostname_type_on_launch            = "ip-name" -> (known after apply)
        tags                                           = {
            "Project" = "shop"
        }
        # (11 unchanged attributes hidden)
    }

  # aws_subnet.app[2] will be destroyed
  # (because index [2] is out of range for count)
```
```
Plan: 1 to add, 0 to change, 2 to destroy.
```

Two resources are touched for a change that was meant to touch one. Copy `[1]` used to be
`10.20.2.0/24` and its argument is now the third range, `10.20.3.0/24`. A subnet's range cannot
be edited in place, so the plan marks that line `# forces replacement` and the whole subnet is
destroyed and created again. Copy `[2]` no longer has an element to come from, and the plan says
so in as many words: **out of range for count**. It is destroyed.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Two panels. On the left, count: before, app[0], app[1] and app[2] hold 10.20.1.0/24, 10.20.2.0/24 and 10.20.3.0/24. After the middle range is removed, app[0] is kept, app[1] now has to hold 10.20.3.0/24 and is replaced, and app[2] is destroyed. On the right, for_each: web, app and db hold the same three ranges; after removing app, web and db are kept and only app is destroyed.\"><defs><marker id=\"ix-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"ix-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"8\" width=\"340\" height=\"254\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"24.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">count</text><text x=\"69.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">an address is a position</text><text x=\"24.0\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">before</text><text x=\"24.0\" y=\"250.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">after removing 10.20.2.0/24</text><rect x=\"20\" y=\"60\" width=\"100\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"70.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">app[0]</text><text x=\"70.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.20.1.0/24</text><path d=\"M70 108 L70 158\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ix-ah-phosphor)\"></path><rect x=\"20\" y=\"162\" width=\"100\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"70.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">app[0]</text><text x=\"70.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.20.1.0/24</text><text x=\"70.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">kept</text><rect x=\"130\" y=\"60\" width=\"100\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"180.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">app[1]</text><text x=\"180.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.20.2.0/24</text><path d=\"M180 108 L180 158\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ix-ah-amber)\"></path><rect x=\"130\" y=\"162\" width=\"100\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"180.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">app[1]</text><text x=\"180.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.20.3.0/24</text><text x=\"180.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">replaced</text><rect x=\"240\" y=\"60\" width=\"100\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"290.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">app[2]</text><text x=\"290.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.20.3.0/24</text><path d=\"M290 108 L290 158\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#ix-ah-amber)\"></path><rect x=\"240\" y=\"162\" width=\"100\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"290.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">app[2]</text><text x=\"290.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">destroyed</text><rect x=\"370\" y=\"8\" width=\"340\" height=\"254\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"384.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">for_each</text><text x=\"450.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">an address is a key</text><text x=\"384.0\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">before</text><text x=\"384.0\" y=\"250.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">after removing 10.20.2.0/24</text><rect x=\"380\" y=\"60\" width=\"100\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"430.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">app[\"web\"]</text><text x=\"430.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.20.1.0/24</text><path d=\"M430 108 L430 158\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ix-ah-phosphor)\"></path><rect x=\"380\" y=\"162\" width=\"100\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"430.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">app[\"web\"]</text><text x=\"430.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.20.1.0/24</text><text x=\"430.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">kept</text><rect x=\"490\" y=\"60\" width=\"100\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"540.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">app[\"app\"]</text><text x=\"540.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.20.2.0/24</text><path d=\"M540 108 L540 158\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#ix-ah-amber)\"></path><rect x=\"490\" y=\"162\" width=\"100\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"540.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">app[\"app\"]</text><text x=\"540.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">destroyed</text><rect x=\"600\" y=\"60\" width=\"100\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"650.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">app[\"db\"]</text><text x=\"650.0\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.20.3.0/24</text><path d=\"M650 108 L650 158\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ix-ah-phosphor)\"></path><rect x=\"600\" y=\"162\" width=\"100\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"650.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">app[\"db\"]</text><text x=\"650.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10.20.3.0/24</text><text x=\"650.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">kept</text></svg>", "caption": "Removing the middle range. With count, the copies after it shift down a place; with for_each, only the copy named app goes."}
```

Follow the third range through it. Before, `10.20.3.0/24` was a subnet with an id AWS gave it on
the first apply. After, `10.20.3.0/24` is still there, but it is a different subnet with a new id,
and the old one is gone. In this lab the subnets are empty, because moto runs no machines. In a
real account, whatever was placed in that subnet, a machine or a database, was placed there by
id, and the plan has just destroyed the subnet under it.

**The plan is honest; the change request was not.** Nothing here is a Terraform bug. The tool
does exactly what the addresses say, and it prints every line of it. The danger is the person
reading the plan: a change described as "remove one subnet" whose summary says
`1 to add, 2 to destroy` is the line to stop at, and lesson 9 turns that into a habit.

Where the problem bites and where it does not is worth knowing exactly:

- **Adding at the end** of the list only adds a copy, because no existing index moves.
- **Removing the last element** only removes one.
- **Inserting at the front, removing from the middle, or sorting the list** shifts every element
  after the change. Each shifted copy is replaced if the argument that moved forces replacement.
- If the argument that moves can be changed in place, such as a tag, the plan shows updates
  instead of replacements. Each resource quietly takes over its neighbour's name, which is
  harder to notice and just as wrong.

You could live with `count` by promising never to edit the list anywhere but its end. That is a
rule somebody will break on a busy afternoon, and the cost lands on whatever lives in the
subnets. The fix is to stop identifying the copies by position, which is what `for_each` does.

Ana does not apply this plan. She deletes `terraform.tfvars`, and the network stays as it was.
