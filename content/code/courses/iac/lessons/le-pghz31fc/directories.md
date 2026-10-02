---
title: One directory per environment
version: 1
---

The other common layout moves the choice of environment out of a hidden file and into the path.
**Each environment is a directory of its own, a small root configuration with its own backend
key, and both call the same modules.** Ana tears the workspaces down, destroying each before
deleting it, and starts a repository laid out this way:

```
ana@laptop:~/shop-infra$ tree --noreport
.
├── envs
│   ├── dev
│   │   ├── backend.tf
│   │   └── main.tf
│   └── prod
│       ├── backend.tf
│       └── main.tf
└── modules
    ├── network
    │   └── main.tf
    └── web
        └── main.tf
```

The two modules hold what `main.tf` held before, split in two: `network` is the VPC and its
subnets, and `web` is the security group. Writing modules, their inputs and outputs, is lesson 10;
here they only need to exist. The network module is the earlier configuration with its variables
and an output for the VPC's id:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

variable "environment" {
  type = string
}

variable "cidr" {
  type = string
}

variable "azs" {
  type = list(string)
}

locals {
  name = "shop-${var.environment}"
  tags = { Project = "shop", Environment = var.environment }
}

resource "aws_vpc" "shop" {
  cidr_block = var.cidr
  tags       = merge(local.tags, { Name = local.name })
}

resource "aws_subnet" "public" {
  for_each          = { for i, az in var.azs : az => i }
  vpc_id            = aws_vpc.shop.id
  cidr_block        = cidrsubnet(var.cidr, 8, each.value + 1)
  availability_zone = each.key
  tags              = merge(local.tags, { Name = "${local.name}-${each.key}" })
}

output "vpc_id" {
  value = aws_vpc.shop.id
}
```

An environment's directory is a backend block and a file calling the modules with that
environment's values:

```hcl
terraform {
  backend "s3" {
    bucket       = "shop-tfstate-123456789012"
    key          = "envs/prod/terraform.tfstate"
    region       = "sa-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

```hcl
provider "aws" {
  region = "sa-east-1"
}

module "network" {
  source      = "../../modules/network"
  environment = "prod"
  cidr        = "10.20.0.0/16"
  azs         = ["sa-east-1a", "sa-east-1c"]
}

module "web" {
  source      = "../../modules/web"
  environment = "prod"
  vpc_id      = module.network.vpc_id
}
```

The values are written straight into the module calls, so there is no `.tfvars` file to pass and
no flag to forget. **The directory is the environment**: to plan prod you stand in `envs/prod`, and
the prompt says so. This is what the two directories actually differ in:

```
ana@laptop:~/shop-infra$ diff -r envs/dev envs/prod
diff -r envs/dev/backend.tf envs/prod/backend.tf
4c4
<     key          = "envs/dev/terraform.tfstate"
---
>     key          = "envs/prod/terraform.tfstate"
diff -r envs/dev/main.tf envs/prod/main.tf
7,9c7,9
<   environment = "dev"
<   cidr        = "10.21.0.0/16"
<   azs         = ["sa-east-1a"]
---
>   environment = "prod"
>   cidr        = "10.20.0.0/16"
>   azs         = ["sa-east-1a", "sa-east-1c"]
14c14
<   environment = "dev"
---
>   environment = "prod"
```

Six lines of values, and the backend key. The key has to be written out in each copy, because, as
lesson 7 showed, a backend block cannot use variables. Each directory is initialised and applied on
its own, with no arguments at all:

```
ana@laptop:~/shop-infra/envs/dev$ terraform apply -auto-approve | tail -n 1
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
ana@laptop:~/shop-infra/envs/prod$ terraform apply -auto-approve | tail -n 1
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.
ana@laptop:~/shop-infra/envs/prod$ aws s3 ls --recursive s3://shop-tfstate-123456789012
2026-10-02 07:33:12       6446 envs/dev/terraform.tfstate
2026-10-02 07:33:19       8588 envs/prod/terraform.tfstate
2026-10-02 07:32:15        181 shop/terraform.tfstate
```

Two state objects, each under a key that says what it is, and each environment's plan reads only
its own. The prompt in that capture is the only place the environment appears, and it is enough.
If prod lives in another AWS account, the directory is also a natural place to say which
credentials to use, through the provider block or the pipeline that runs in it; a workspace has
nowhere to hang that.

## What the copies cost

**Everything the two directories share is written twice**: the provider block, the backend block
apart from its key, the module calls apart from their values. Two environments make that tolerable.
Five environments in three regions, each with a network, a database and an application in separate
states, is forty-five backend blocks differing in one string, and the day somebody changes the
bucket's name, forty-five edits.

The shared modules are the other half, and they cut both ways. A change to `modules/network`
reaches every environment at once. Ana adds an `Owner` tag to the module's tags and plans both:

```
ana@laptop:~/shop-infra$ sed -i 's/tags = { Project = "shop", Environment = var.environment }/tags = { Project = "shop", Environment = var.environment, Owner = "ana" }/' modules/network/main.tf
ana@laptop:~/shop-infra/envs/dev$ terraform plan -no-color | grep -E "^(No changes|Plan:)"
Plan: 0 to add, 2 to change, 0 to destroy.
ana@laptop:~/shop-infra/envs/prod$ terraform plan -no-color | grep -E "^(No changes|Plan:)"
Plan: 0 to add, 3 to change, 0 to destroy.
```

Dev would change two resources and prod three, from one edit. That is what you want for a fix, and
not for a change you meant to try in dev for a week first. The usual way to hold prod back is to
give it the module by version rather than by path, `?ref=v1.2.0` on a git source, and move each
environment to the new version when it is ready; lesson 10 covers module sources and versions.

**The copies can also drift on purpose**, and that is sometimes the point. Prod's directory can
carry a resource dev does not have, a backup vault for instance, without a single `count` or
conditional in the shared code. With workspaces, every difference between environments has to be
expressed through the values of one configuration.

The repetition is what the next section is about. Terragrunt exists mainly to remove it.
