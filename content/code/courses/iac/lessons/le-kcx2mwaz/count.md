---
title: count, and copies numbered from zero
version: 1
---

The shop's network needs three subnets that differ only in their address range. The first idea
most people have is three `resource` blocks, copied and edited, and it works until the day there
are twelve. **`count` turns one block into as many resources as you ask for.** It is a
**meta-argument**: Terraform reads it itself, before the provider sees anything, so it means the
same thing on an `aws_subnet`, a `random_id` or any other resource type.

Ana's configuration keeps the `terraform` and `provider` blocks from lesson 2 in `versions.tf`.
Everything this section is about is in `main.tf`:

```hcl
variable "subnets" {
  type    = list(string)
  default = ["10.20.1.0/24", "10.20.2.0/24", "10.20.3.0/24"]
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
  count = length(var.subnets)

  vpc_id     = aws_vpc.shop.id
  cidr_block = var.subnets[count.index]
  tags       = { Project = "shop" }
}

resource "aws_internet_gateway" "shop" {
  count = var.public ? 1 : 0

  vpc_id = aws_vpc.shop.id
}
```

`count = length(var.subnets)` asks for three subnets. Inside the block, `count.index` is the
number of the copy being built, **starting at zero**, so `var.subnets[count.index]` hands the
first copy the first range, the second copy the second, and so on. Each copy gets an address of
its own, which is the resource's address with the index in square brackets. You can see them in
the apply as Terraform creates each one:

```
Plan: 5 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + gateway = (known after apply)
aws_vpc.shop: Creating...
aws_vpc.shop: Creation complete after 1s [id=vpc-ef185f8eeea2f754c]
aws_internet_gateway.shop[0]: Creating...
aws_subnet.app[1]: Creating...
aws_subnet.app[0]: Creating...
aws_subnet.app[2]: Creating...
aws_subnet.app[0]: Creation complete after 1s [id=subnet-9485478c607d4a202]
aws_subnet.app[2]: Creation complete after 1s [id=subnet-151a62e4e9c8c6cb4]
aws_subnet.app[1]: Creation complete after 1s [id=subnet-a4a6adb3ebc89f9b9]
aws_internet_gateway.shop[0]: Creation complete after 1s [id=igw-d64e0925c422c6e13]

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.

Outputs:

gateway = "igw-d64e0925c422c6e13"
```

One block, five resources: the VPC, three subnets and the gateway. The state keeps them under
those addresses, and `terraform console`, which lesson 3 uses for expressions, can read any one
of them back:

```
ana@laptop:~/shop/network$ terraform state list
aws_internet_gateway.shop[0]
aws_subnet.app[0]
aws_subnet.app[1]
aws_subnet.app[2]
aws_vpc.shop
ana@laptop:~/shop/network$ echo "aws_subnet.app[1].cidr_block" | terraform console
"10.20.2.0/24"
```

`aws_subnet.app[1]` is one subnet. `aws_subnet.app` on its own is all three, as a list, and that
difference matters as soon as you write a reference.

## count as an on/off switch

The internet gateway uses `count` for a different job. `var.public ? 1 : 0` gives either one copy
or none, which is the usual way to make a resource optional: a public network gets a gateway, a
private one does not. The block stays in the file either way, and a variable decides.

**The catch is everything that points at the optional resource.** `outputs.tf` reads the
gateway's id as `aws_internet_gateway.shop[0].id`, which is fine while there is a copy zero. Ask
for a private network and see what happens:

```
Terraform planned the following actions, but then encountered a problem:

  # aws_internet_gateway.shop[0] will be destroyed
  # (because index [0] is out of range for count)
  - resource "aws_internet_gateway" "shop" {
      - arn      = "arn:aws:ec2:sa-east-1:123456789012:internet-gateway/igw-d64e0925c422c6e13" -> null
      - id       = "igw-d64e0925c422c6e13" -> null
      - owner_id = "123456789012" -> null
      - region   = "sa-east-1" -> null
      - tags     = {} -> null
      - tags_all = {} -> null
      - vpc_id   = "vpc-ef185f8eeea2f754c" -> null
    }

Plan: 0 to add, 0 to change, 1 to destroy.
╷
│ Error: Invalid index
│ 
│   on outputs.tf line 2, in output "gateway":
│    2:   value = aws_internet_gateway.shop[0].id
│     ├────────────────
│     │ aws_internet_gateway.shop is empty tuple
│ 
│ The given key does not identify an element in this collection value: the
│ collection has no elements.
╵
```

Terraform worked out the plan, destroying the gateway, and then failed on the output, because
`aws_internet_gateway.shop` is now an empty list and `[0]` points at nothing. Nothing was changed:
an apply would have stopped at the same error before touching anything. The fix is a reference that copes with zero:

```hcl
output "gateway" {
  value = one(aws_internet_gateway.shop[*].id)
}
```

`[*]` is the splat from lesson 3, a list of every copy's id, with one element or none. `one()`
turns that list into its single element, or into `null` when it is empty, and refuses a list of
two. The same plan now goes through, and says what will happen to the output as well:

```
Plan: 0 to add, 0 to change, 1 to destroy.

Changes to Outputs:
  - gateway = "igw-d64e0925c422c6e13" -> null
```

**Two limits to keep in mind.** `count` has to be a number Terraform knows while it plans, before
anything is created; `choosing`, at the end of this lesson, shows what happens when it is not. And
the index is the copy's identity: `aws_subnet.app[2]` is whatever sits third in the list today.
The next section shows what that costs.
