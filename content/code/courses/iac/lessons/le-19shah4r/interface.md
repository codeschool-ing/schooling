---
title: The interface, and what stays inside
version: 1
---

A module has two audiences: whoever writes its insides and whoever calls it. The caller should be
able to use it from its variables and outputs alone, without opening `main.tf`. **The variables and
outputs are the module's interface**, and the decisions about them matter more than anything in the
resources, because the resources can change later and the interface, once somebody depends on it,
mostly cannot.

## Outputs are the only way out

A caller who wants the VPC's range might try to read it from the resource inside the module:

```
ana@laptop:~/shop$ tail -n 3 outputs.tf
output "shop_vpc_cidr" {
  value = module.shop.aws_vpc.this.cidr_block
}
ana@laptop:~/shop$ terraform plan
╷
│ Error: Unsupported attribute
│ 
│   on outputs.tf line 10, in output "shop_vpc_cidr":
│   10:   value = module.shop.aws_vpc.this.cidr_block
│     ├────────────────
│     │ module.shop is object with 2 attributes
│ 
│ This object does not have an attribute named "aws_vpc".
╵
```

`module.shop is object with 2 attributes` is the whole answer. **From outside, a module call is
an object whose attributes are its outputs**, `vpc_id` and `subnet_ids`, and nothing else. The resource
`aws_vpc.this` exists, it is in the state, and the root still cannot name it. That is deliberate: if
callers could reach in, the module's author could never rename a resource without breaking them.
The fix is an output in the module, written on purpose, which then becomes part of the interface.

So publish what callers need, and an id rather than a whole object when the id is enough: an object
exported "just in case" turns every attribute of it into a promise.

## Variables that refuse bad input early

A validation rule written in the module reports at the caller's line. The analytics range with a typo
in its prefix length:

```
ana@laptop:~/shop$ grep -n "10.30.0.0" analytics.tf
5:  cidr = "10.30.0.0/33"
ana@laptop:~/shop$ terraform plan
╷
│ Error: Invalid value for variable
│ 
│   on analytics.tf line 5, in module "analytics":
│    5:   cidr = "10.30.0.0/33"
│     ├────────────────
│     │ var.cidr is "10.30.0.0/33"
│ 
│ The cidr must be an IPv4 range such as 10.20.0.0/16.
│ 
│ This was checked by the validation rule at
│ modules/network/variables.tf:10,3-13.
╵
```

**The error points at `analytics.tf`, where the mistake is, and names the rule in the module that
caught it.** Without the rule the bad range would reach AWS during the apply and come back as an
API error with no line number at all. Lesson 3 taught `validation`; in a module it is worth more,
because the person who makes the mistake is not the person who wrote the code.

A good variable has a `type` as narrow as the value allows, a `description` that says what it is
for, and a `default` only when one answer is right for most callers. A variable whose default is
wrong for half of them is a trap with documentation.

## Two shapes to avoid

**Do not wrap a single resource.** A module around one `aws_s3_bucket`, with a variable for each of
its arguments, gives the caller the same resource behind a second name, and every argument the
provider adds later is missing until somebody adds a variable for it. A module earns its place
when it puts several resources together with decisions made: a VPC *and* its subnets *and* their
tags, the way this network does.

**Do not configure providers inside a module.** Look at what `modules/network` lacks: there is no
`provider "aws"` block in it. It uses the provider configuration of whoever calls it, so the same
module works in `sa-east-1` and anywhere else. An older style put the `provider` block inside, and
Terraform now limits what such a module can do. Here is one that does it, called once per bucket:

```hcl
provider "aws" {
  region = "sa-east-1"
}

resource "aws_s3_bucket" "this" {
  bucket = var.name
}

variable "name" {
  type = string
}
```

```hcl
module "assets" {
  source   = "./modules/bucket"
  for_each = toset(["shop-assets-123456789012", "shop-logs-123456789012"])
  name     = each.key
}
```

```
ana@laptop:~/legacy$ terraform init
Initializing the backend...

Initializing modules...
- assets in modules/bucket
╷
│ Error: Module is incompatible with count, for_each, and depends_on
│ 
│   on main.tf line 3, in module "assets":
│    3:   for_each = toset(["shop-assets-123456789012", "shop-logs-123456789012"])
│ 
│ The module at module.assets is a legacy module which contains its own local
│ provider configurations, and so calls to it may not use the count,
│ for_each, or depends_on arguments.
│ 
│ If you also control the module "./modules/bucket", consider updating this
│ module to instead expect provider configurations to be passed by its
│ caller.
╵
```

Called without `for_each`, it works until the day the call is removed. With one bucket applied
and the `module` block deleted, the bucket has to be destroyed, and the configuration that knew how
to reach AWS for it was inside the block that is now gone:

```
ana@laptop:~/legacy$ terraform apply -auto-approve | tail -n 1
Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
ana@laptop:~/legacy$ terraform plan
╷
│ Error: Provider configuration not present
│ 
│ To work with module.assets.aws_s3_bucket.this (orphan) its original
│ provider configuration at
│ module.assets.provider["registry.terraform.io/hashicorp/aws"] is required,
│ but it has been removed. This occurs when a provider configuration is
│ removed while objects created by that provider still exist in the state.
│ Re-add the provider configuration to destroy
│ module.assets.aws_s3_bucket.this (orphan), after which you can remove the
│ provider configuration again.
╵
```

**The provider went away with the module, and the bucket is stuck in the state.** The way out is
the one the message gives: put the configuration back, destroy, remove it again. A module that
leaves providers to its caller never reaches this state. When a caller needs a module to use a
different provider configuration, such as a second region, it passes one in with
`providers = { aws = aws.us }`, using an alias from lesson 4.
