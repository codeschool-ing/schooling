---
title: A block that only asks
version: 1
---

Everything in lesson 2's configuration was something to create. A `resource` block says "this
should exist", and Terraform makes it so, keeps it in the state and destroys it when the block goes.
**A `data` block is the other half of the language: it asks a question and keeps the answer.** It
creates nothing, changes nothing and destroys nothing, whatever you write in it.

The common wrong picture is that a data source is a lighter kind of resource, one Terraform
"manages a little". It does not manage it at all. A data source is a query sent through the same
provider, and its result is a set of attributes you can reference like any other. Here are the two
smallest questions the AWS provider can answer, who am I and where am I:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "sa-east-1"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "region" {
  value = data.aws_region.current.region
}
```

The shape is `data "TYPE" "NAME" { … }`, the same as a resource, and the address is
`data.TYPE.NAME`, so `data.aws_caller_identity.current.account_id` reads the account number. The
name `current` is a convention for these two, nothing more. The arguments inside the braces, when a
data source has any, are the **query**; the attributes that come back are the **answer**. Both of
these need no arguments, because the provider already knows its credentials and its region.

An apply of this configuration runs the queries and creates nothing:

```
ana@laptop:~/shop/app$ terraform apply -auto-approve
data.aws_region.current: Reading...
data.aws_caller_identity.current: Reading...
data.aws_region.current: Read complete after 0s [id=sa-east-1]
data.aws_caller_identity.current: Read complete after 0s [id=123456789012]

Changes to Outputs:
  + account_id = "123456789012"
  + region     = "sa-east-1"

You can apply this plan to save these new output values to the Terraform
state, without changing any real infrastructure.

Apply complete! Resources: 0 added, 0 changed, 0 destroyed.

Outputs:

account_id = "123456789012"
region = "sa-east-1"
```

`Reading...` and `Read complete` are the two lines a data source prints, and **`0 added, 0 changed,
0 destroyed`** is the proof that nothing in the account moved. The `id` in brackets is whatever the
provider chose to identify the answer: the account number here, the region name there. In the lab
the account is moto's placeholder, `123456789012`; against a real account it is yours.

The answers are recorded in the state, beside the resources, under their own addresses:

```
ana@laptop:~/shop/app$ terraform state list
data.aws_caller_identity.current
data.aws_region.current
```

**That record is a cache, not a claim of ownership.** On every plan Terraform reads the data sources
again, because the thing being asked about belongs to somebody else and may have changed since. That
is the whole contract of this lesson: a resource is something Terraform is responsible for; a data
source is something it only looks at, every time, and believes.

Why would a configuration want to know its own account number? Because a name that must be unique
can be built from it, and a policy that grants access to "this account" needs to say which one. Both
appear later in this lesson, and neither has to be typed: a configuration that reads its account and
region works unchanged in the next account and the next region.

The provider documentation lists data sources beside the resources, and most resource types have a
matching one: `aws_vpc` and `data "aws_vpc"`, `aws_subnet` and `data "aws_subnet"`. A few exist only
as data sources, like these two, because there is nothing to create: an identity and a region are
facts about the connection. One more is worth knowing by name now: **`terraform_remote_state`**
reads the outputs of another Terraform configuration's state, and lesson 8 uses it to join two
configurations that were split on purpose.
