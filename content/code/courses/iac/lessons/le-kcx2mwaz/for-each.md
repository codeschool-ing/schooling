---
title: for_each, and copies with names
version: 1
---

`for_each` makes copies the way `count` does, with one difference that decides everything else:
**each copy is named by a key you chose**, not numbered by its position. Remove one key and only
the copy with that key goes, because no other copy's name depended on it.

Ana tries it in a scratch directory first, with a VPC of its own, so the shop's network is not
part of the experiment. The ranges are now a map from a name to a range:

```hcl
provider "aws" {
  region = "sa-east-1"
}

variable "subnets" {
  type = map(string)
  default = {
    web = "10.20.1.0/24"
    app = "10.20.2.0/24"
    db  = "10.20.3.0/24"
  }
}

resource "aws_vpc" "scratch" {
  cidr_block = "10.20.0.0/16"
  tags       = { Name = "scratch" }
}

resource "aws_subnet" "app" {
  for_each = var.subnets

  vpc_id     = aws_vpc.scratch.id
  cidr_block = each.value
  tags       = { Name = "scratch-${each.key}" }
}
```

`for_each` accepts a **map** or a **set of strings**. For a map, each copy sees two values:
`each.key`, the name on the left, and `each.value`, the range on the right. Here the key goes into
the `Name` tag and the value into `cidr_block`. For a set there is only one thing per element, and
`each.key` and `each.value` are the same string.

The apply creates four resources, and the addresses carry the keys:

```
Plan: 4 to add, 0 to change, 0 to destroy.
aws_vpc.scratch: Creating...
aws_vpc.scratch: Creation complete after 1s [id=vpc-aa3637c237d354dc1]
aws_subnet.app["web"]: Creating...
aws_subnet.app["app"]: Creating...
aws_subnet.app["db"]: Creating...
aws_subnet.app["web"]: Creation complete after 0s [id=subnet-26d3b5fe2878535e6]
aws_subnet.app["app"]: Creation complete after 0s [id=subnet-d8208f30f1c769002]
aws_subnet.app["db"]: Creation complete after 0s [id=subnet-a247c432631647404]

Apply complete! Resources: 4 added, 0 changed, 0 destroyed.
```

The state lists them under those keys. It sorts them alphabetically, which is a hint of how
Terraform thinks of them: a collection looked up by name, with no first or last.

```
ana@laptop:~/shop/scratch$ terraform state list
aws_subnet.app["app"]
aws_subnet.app["db"]
aws_subnet.app["web"]
aws_vpc.scratch
```

## The same removal, again

Now the experiment from the previous section. The middle subnet goes, this time by leaving its key
out of the map:

```hcl
subnets = {
  web = "10.20.1.0/24"
  db  = "10.20.3.0/24"
}
```

```
Terraform will perform the following actions:

  # aws_subnet.app["app"] will be destroyed
  # (because key ["app"] is not in for_each map)
```
```
Plan: 0 to add, 0 to change, 1 to destroy.
```

**One subnet destroyed, nothing else touched.** `web` and `db` keep their addresses, so they keep
their ids, and whatever was placed in them is undisturbed. The reason in the plan is the
`for_each` counterpart of the one `count` gave: the key `"app"` is not in the map any more.
Adding a key later creates one subnet, and the order in which the keys are written in the file
makes no difference at all.

After the plan Ana deletes the `terraform.tfvars` and destroys the scratch copy, which has done its
job.

## A list is not enough

`for_each` refuses a list, even a list of strings, and the reason is the whole point of it. A list
is ordered and can hold the same value twice, so its elements have no name except their position,
and position is what `for_each` exists to avoid. Here is a list written straight into the
argument:

```
ana@laptop:~/shop/try$ terraform plan
╷
│ Error: Invalid for_each argument
│ 
│   on main.tf line 6, in resource "aws_vpc" "try":
│    6:   for_each   = ["10.30.0.0/16", "10.31.0.0/16"]
│ 
│ The given "for_each" argument value is unsuitable: the "for_each" argument
│ must be a map, or set of strings, and you have provided a value of type
│ tuple.
╵
```

The error calls it a tuple, which is what a list written between square brackets is before
Terraform converts it. `toset(...)` around it would be accepted: the strings themselves become the
keys, duplicates collapse into one, and the order is dropped. That is fine when each string is a
stable, unique name, as a range or a bucket name is. When the elements are objects with several
attributes, build a map whose keys are the names you want to see in the addresses; lesson 3's
`for` expressions do that in one line.

A good key is one you would be happy to see in a plan a year from now. `"web"` says what the
subnet is for. A key built from something that changes, such as a description, brings back the
index problem in another form, because changing the key is changing the address.
