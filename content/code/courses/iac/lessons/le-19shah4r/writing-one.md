---
title: Writing the network module
version: 1
---

A module is written exactly like the configurations of the earlier lessons, with one difference in
attitude: **every value that might differ between two callers becomes a variable**, and every value
a caller might need afterwards becomes an output. The resources go in `main.tf`:

```hcl
resource "aws_vpc" "this" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  tags                 = { Name = var.name }
}

resource "aws_subnet" "this" {
  for_each = var.subnets

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az
  tags              = { Name = "${var.name}-${each.key}" }
}
```

Nothing in it is new. The subnets use `for_each` over a map, as lesson 4 taught, so a caller can
ask for one subnet or five and each one is addressed by its key. The resources are called `this`,
a common convention for "the one resource of this type in the module": inside the module there is
no second VPC to tell it apart from, and the caller supplies the meaningful name.

The values come in through `variables.tf`:

```hcl
variable "name" {
  type        = string
  description = "Name tag of the VPC, and the prefix of every subnet's Name."
}

variable "cidr" {
  type        = string
  description = "The VPC's address range, such as 10.20.0.0/16."

  validation {
    condition     = can(cidrhost(var.cidr, 0))
    error_message = "The cidr must be an IPv4 range such as 10.20.0.0/16."
  }
}

variable "subnets" {
  type = map(object({
    az   = string
    cidr = string
  }))
  description = "The subnets to create, keyed by a short name such as \"a\"."
}
```

**Not one of the three has a default.** A VPC's range has no sensible value that suits every caller,
and a default here would let somebody forget the argument and get a network that collides with
another. The `subnets` type is an object per key, so a caller who misspells `az` is told at plan
time rather than discovering a subnet in the wrong zone. "interface" comes back to the validation
rule.

And the values go out through `outputs.tf`:

```hcl
output "vpc_id" {
  description = "The id of the VPC."
  value       = aws_vpc.this.id
}

output "subnet_ids" {
  description = "The id of each subnet, keyed like var.subnets."
  value       = { for k, s in aws_subnet.this : k => s.id }
}
```

`subnet_ids` is a map built with a `for` expression from lesson 3, keyed exactly like the input, so
a caller who asked for subnet `a` finds its id under `a`.

## Two calls, one directory

With one call, the plan shows the resources under the call's name:

```
ana@laptop:~/shop$ terraform plan -no-color | grep -E "^  #|^Plan"
  # module.shop.aws_subnet.this["a"] will be created
  # module.shop.aws_subnet.this["c"] will be created
  # module.shop.aws_vpc.this will be created
Plan: 3 to add, 0 to change, 0 to destroy.
```

**The address is the module's name, then the resource's.** `module.shop.aws_subnet.this["a"]` is how
the state will remember that subnet, and the `shop` in it comes from the label of the `module` block
in the root, not from anything in the module's directory.

Now the second network. Ana adds three files to the root: another call to the same directory, a
security group that needs the shop's VPC, and two outputs. Terraform reads every `.tf` file in the
root directory as one configuration, so how she splits them is for the reader's sake:

```hcl
module "analytics" {
  source = "./modules/network"

  name = "analytics"
  cidr = "10.30.0.0/16"
  subnets = {
    a = { az = "sa-east-1a", cidr = "10.30.1.0/24" }
  }
}
```

```hcl
resource "aws_security_group" "web" {
  name        = "web"
  description = "web servers"
  vpc_id      = module.shop.vpc_id
}
```

```hcl
output "shop_vpc_id" {
  value = module.shop.vpc_id
}

output "shop_subnet_ids" {
  value = module.shop.subnet_ids
}
```

`module.shop.vpc_id` is how a value comes out of a call: `module.`, the call's name, the output's
name. It also makes the dependency visible to Terraform, which creates the VPC before the security
group exactly as it would with a direct reference. A new `module` block is a new installation, even
from a directory already installed under another name, so `init` runs again:

```
ana@laptop:~/shop$ terraform init | grep -A3 "Initializing modules"
Initializing modules...
- analytics in modules/network

Initializing provider plugins...
```

```
ana@laptop:~/shop$ terraform apply -auto-approve | tail -n 8

Outputs:

shop_subnet_ids = {
  "a" = "subnet-1c6d0ef9160885f9f"
  "c" = "subnet-3ac6009e35ad91b30"
}
shop_vpc_id = "vpc-e73ad3e5038785a73"
```

```
ana@laptop:~/shop$ terraform state list
aws_security_group.web
module.analytics.aws_subnet.this["a"]
module.analytics.aws_vpc.this
module.shop.aws_subnet.this["a"]
module.shop.aws_subnet.this["c"]
module.shop.aws_vpc.this
```

**Two copies of the same three lines of HCL, kept apart by their prefix.** `module.shop` has two
subnets and `module.analytics` has one, because each call passed its own map. The two never
collide in the state because their addresses differ, and they never collide in AWS because the
caller chose different ranges.

The root's outputs pass the module's on, which is how a value reaches somebody outside the
configuration:

```
ana@laptop:~/shop$ terraform output
shop_subnet_ids = {
  "a" = "subnet-1c6d0ef9160885f9f"
  "c" = "subnet-3ac6009e35ad91b30"
}
shop_vpc_id = "vpc-e73ad3e5038785a73"
```

When the calls differ only in their values, `for_each` works on a `module` block too, and one block
with a map of networks replaces the two. Two separate blocks are easier to read when there are two;
the map earns its place when the list of networks is itself data. That is the choice lesson 4 made
for resources, and it holds for modules unchanged.
