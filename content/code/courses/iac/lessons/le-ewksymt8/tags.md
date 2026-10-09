---
title: Tags that every resource carries
version: 2
---

Tags look like notes for whoever browses the console. On the bill they are something else: **the
only link between a line of spending and a person who can decide about it.** Lesson 10 of the cloud
course made that case, including the step that is easy to miss: a tag only groups the bill once it
has been activated as a cost allocation tag in the billing settings. What it left to this course is
the enforcement, because a convention people have to remember is followed on the days they remember.

## One set, applied by the provider

Writing `tags = { ... }` on every resource works until somebody adds a resource and forgets.
The AWS provider has a block for exactly this, `default_tags`, which merges a set of tags into every
resource the provider creates. Ana makes the set a variable, so it cannot be left out. `main.tf`
becomes:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

variable "tags" {
  description = "Applied to every resource this configuration creates."
  type        = map(string)

  validation {
    condition = alltrue([
      for k in ["Owner", "Project", "Environment", "CostCenter"] : contains(keys(var.tags), k)
    ])
    error_message = "The tags must include Owner, Project, Environment and CostCenter."
  }
}

provider "aws" {
  region = "sa-east-1"

  default_tags {
    tags = var.tags
  }
}
```

and the values go in `terraform.tfvars`, which Terraform reads without being asked:

```hcl
tags = {
  Owner       = "ana"
  Project     = "shop"
  Environment = "prod"
  CostCenter  = "cc-4410"
}
```

The four keys answer four questions: who to ask, which product, whether it serves customers, and
whose budget pays. `CostCenter` is `cc-4410`, the code the finance team already uses. The plan
touches every resource the configuration has, and replaces none:

```
ana@laptop:~/shop$ terraform plan -no-color | grep -E "will be updated|Plan:"
  # aws_eip.nat will be updated in-place
  # aws_instance.web[0] will be updated in-place
  # aws_instance.web[1] will be updated in-place
  # aws_internet_gateway.shop will be updated in-place
  # aws_nat_gateway.shop will be updated in-place
  # aws_subnet.private_c will be updated in-place
  # aws_subnet.public_a will be updated in-place
  # aws_vpc.shop will be updated in-place
Plan: 0 to add, 8 to change, 0 to destroy.
```

One of them in full shows where the tags go:

```
ana@laptop:~/shop$ terraform plan -no-color | sed -n '/aws_nat_gateway.shop will be updated/,/^$/p'
  # aws_nat_gateway.shop will be updated in-place
  ~ resource "aws_nat_gateway" "shop" {
        id                             = "nat-d01d54b52cd8ba700"
        tags                           = {}
      ~ tags_all                       = {
          + "CostCenter"  = "cc-4410"
          + "Environment" = "prod"
          + "Owner"       = "ana"
          + "Project"     = "shop"
        }
        # (9 unchanged attributes hidden)
    }
```

**`tags` stays empty and `tags_all` gains four.** `tags` is what the resource block says;
`tags_all` is what AWS will hold, the resource's own tags merged over the defaults; where both name
the same key, the resource's value wins. Ana applies the change and commits it as *tag everything
for the bill*. Each web server keeps its `Name` beside the four, as AWS shows after the apply:

```
ana@laptop:~/shop$ aws ec2 describe-instances --filters Name=tag:Name,Values=web-0 --query "Reservations[0].Instances[0].Tags" --output table
----------------------------
|     DescribeInstances    |
+--------------+-----------+
|      Key     |   Value   |
+--------------+-----------+
|  Name        |  web-0    |
|  CostCenter  |  cc-4410  |
|  Environment |  prod     |
|  Owner       |  ana      |
|  Project     |  shop     |
+--------------+-----------+
```

## A missing tag fails the plan

The validation rule in `main.tf` is the kind lesson 3 wrote. It checks the keys, not the values, and
it runs before Terraform has asked AWS anything. Leave out `CostCenter` and nothing is planned:

```
ana@laptop:~/shop$ terraform plan -var 'tags={Owner="ana", Project="shop", Environment="prod"}'

Planning failed. Terraform encountered an error while generating this plan.

╷
│ Error: Invalid value for variable
│ 
│   on main.tf line 10:
│   10: variable "tags" {
│     ├────────────────
│     │ var.tags is map of string with 3 elements
│ 
│ The tags must include Owner, Project, Environment and CostCenter.
│ 
│ This was checked by the validation rule at main.tf:14,3-13.
╵
```

**A cost that cannot be attributed is refused at the cheapest moment there is**, on a laptop, before
review. The same rule can be checked by a scanner in the pipeline, which is how lesson 14's tools
enforce it across configurations that do not share this variable, and the account can check its own
tags against a tag policy, which the cloud course named.

## What the defaults do not reach

`default_tags` tags what this provider creates through this configuration. That is less than it
sounds. **Anything made by hand gets nothing**, and so does anything another configuration made
without the same block. And a default added to resources that already exist reaches only what the
provider updates: the plan above changed the two instances, and their disks, which Terraform created
as part of each instance, are not in it. The next section finds those disks again, untagged, in the
middle of a search for something else.

Tags make ownership visible for whatever carries them. The expensive cases are the ones that carry
nothing, and finding those needs a different question.
