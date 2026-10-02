---
title: Splitting the shop into network and app
version: 1
---

A split has two halves, and people tend to do only the first. **The files move easily; the state is
what has to move with them.** Copy the network's blocks into a new directory, run `apply` there, and
Terraform sees three resources it has never heard of and creates three more: a second VPC beside the
first, exactly the accident of lesson 7. So the order is: write the new configurations, move the
state entries into them, and prove with a plan in each that nothing will change.

## The two configurations

The network gets a directory of its own with the VPC and the two subnets, copied from `main.tf`
without a character changed, since the addresses have to stay the same:

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

resource "aws_vpc" "shop" {
  cidr_block = "10.20.0.0/16"
  tags       = { Name = "shop" }
}

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = "sa-east-1a"
  tags              = { Name = "shop-a" }
}

resource "aws_subnet" "public_c" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.2.0/24"
  availability_zone = "sa-east-1c"
  tags              = { Name = "shop-c" }
}
```

Its outputs are new. They are what the network offers to the rest of the company, and the next
section is about them:

```hcl
output "vpc_id" {
  description = "The shop's VPC."
  value       = aws_vpc.shop.id
}

output "vpc_cidr" {
  description = "The VPC's address range."
  value       = aws_vpc.shop.cidr_block
}

output "public_subnet_ids" {
  description = "One public subnet per availability zone."
  value       = [aws_subnet.public_a.id, aws_subnet.public_c.id]
}
```

Its backend is lesson 7's bucket under a **new key**:

```hcl
terraform {
  backend "s3" {
    bucket       = "shop-tfstate-123456789012"
    key          = "network/terraform.tfstate"
    region       = "sa-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

The old `main.tf` and `backend.tf` move into `app/`, with git keeping their history. The network's
blocks come out of `main.tf`, and the security group finds the VPC with a data source by its tag,
lesson 5's tool, as a first bridge:

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

data "aws_vpc" "shop" {
  tags = { Name = "shop" }
}

resource "aws_security_group" "web" {
  name        = "web"
  description = "web servers"
  vpc_id      = data.aws_vpc.shop.id
  tags        = { Name = "web" }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_s3_bucket" "assets" {
  bucket = "shop-assets-dev"
}

resource "aws_s3_bucket" "logs" {
  bucket = "shop-logs-dev"
}
```

The app keeps the same bucket and gets a key of its own too:

```
ana@laptop:~/shop/app$ git diff backend.tf
diff --git a/app/backend.tf b/app/backend.tf
index 8a9b10f..9782b2e 100644
--- a/app/backend.tf
+++ b/app/backend.tf
@@ -1,7 +1,7 @@
 terraform {
   backend "s3" {
     bucket       = "shop-tfstate-123456789012"
-    key          = "shop/terraform.tfstate"
+    key          = "app/terraform.tfstate"
     region       = "sa-east-1"
     encrypt      = true
     use_lockfile = true
```

```
ana@laptop:~/shop$ tree --noreport -I .terraform
.
├── app
│   ├── backend.tf
│   └── main.tf
└── network
    ├── backend.tf
    ├── main.tf
    └── outputs.tf
```

## Moving the entries

`terraform state mv` from lesson 7 moves an entry inside one state. With `-state` and `-state-out`
it moves one between two **local files**, and that is the trick: copy the remote state down, cut
it in two on disk, and push each half to its new key. The copy is a plain download of the object:

```
ana@laptop:~/shop$ mkdir split && cd split
ana@laptop:~/shop/split$ aws s3 cp --no-progress s3://shop-tfstate-123456789012/shop/terraform.tfstate shop.tfstate
download: s3://shop-tfstate-123456789012/shop/terraform.tfstate to ./shop.tfstate
```

Then the three network entries go from `shop.tfstate` into a new `network.tfstate`, keeping their
addresses:

```
ana@laptop:~/shop/split$ terraform state mv -state=shop.tfstate -state-out=network.tfstate aws_vpc.shop aws_vpc.shop
Move "aws_vpc.shop" to "aws_vpc.shop"
Successfully moved 1 object(s).
ana@laptop:~/shop/split$ terraform state mv -state=shop.tfstate -state-out=network.tfstate aws_subnet.public_a aws_subnet.public_a
Move "aws_subnet.public_a" to "aws_subnet.public_a"
Successfully moved 1 object(s).
ana@laptop:~/shop/split$ terraform state mv -state=shop.tfstate -state-out=network.tfstate aws_subnet.public_c aws_subnet.public_c
Move "aws_subnet.public_c" to "aws_subnet.public_c"
Successfully moved 1 object(s).
ana@laptop:~/shop/split$ terraform state list -state=shop.tfstate
aws_s3_bucket.assets
aws_s3_bucket.logs
aws_security_group.web
ana@laptop:~/shop/split$ terraform state list -state=network.tfstate
aws_subnet.public_a
aws_subnet.public_c
aws_vpc.shop
```

Each half is pushed to its new key with `terraform state push` from its own directory, and each is
checked with a plan before anything else happens. The network first:

```
ana@laptop:~/shop/network$ terraform state push ../split/network.tfstate
ana@laptop:~/shop/network$ terraform plan
aws_vpc.shop: Refreshing state... [id=vpc-644904a24046c8bab]
aws_subnet.public_c: Refreshing state... [id=subnet-0bf2cbc4f593b157b]
aws_subnet.public_a: Refreshing state... [id=subnet-2fc7f0dc6fb32b7e4]

Changes to Outputs:
  + public_subnet_ids = [
      + "subnet-2fc7f0dc6fb32b7e4",
      + "subnet-0bf2cbc4f593b157b",
    ]
  + vpc_cidr          = "10.20.0.0/16"
  + vpc_id            = "vpc-644904a24046c8bab"

You can apply this plan to save these new output values to the Terraform
```

**No resource changes, only outputs.** The three resources are recognised by their ids, and the
outputs are new to a state that has never had them, so Terraform offers to record them; the next
section applies that. The app:

```
ana@laptop:~/shop/app$ terraform state push ../split/shop.tfstate
ana@laptop:~/shop/app$ terraform plan
data.aws_vpc.shop: Reading...
aws_s3_bucket.assets: Refreshing state... [id=shop-assets-dev]
aws_s3_bucket.logs: Refreshing state... [id=shop-logs-dev]
data.aws_vpc.shop: Read complete after 0s [id=vpc-644904a24046c8bab]
aws_security_group.web: Refreshing state... [id=sg-020bb5a164511a5d9]

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration
and found no differences, so no changes are needed.
```

`No changes`, and three resources refreshed instead of six. The split is done, and the old key goes:

```
ana@laptop:~/shop/app$ aws s3 rm s3://shop-tfstate-123456789012/shop/terraform.tfstate
delete: s3://shop-tfstate-123456789012/shop/terraform.tfstate
ana@laptop:~/shop/app$ aws s3 ls --recursive s3://shop-tfstate-123456789012
2026-10-02 07:09:13       6517 app/terraform.tfstate
2026-10-02 07:09:06       6150 network/terraform.tfstate
ana@laptop:~/shop/app$ rm -r ../split
```

The `split` directory held two complete copies of the state on Ana's disk, so it goes too.

## The old checkout

There is one way left to undo all of this, and it is sitting on a colleague's laptop. A checkout
from before the split still has the big `main.tf` and still points at `shop/terraform.tfstate`,
which is now gone:

```
ana@laptop:~/shop-old$ git log --oneline -1
9089f02 the shop, in one state
ana@laptop:~/shop-old$ terraform plan -no-color | grep -E "^Plan"
Plan: 6 to add, 0 to change, 0 to destroy.
```

**Six to add**: the whole shop again, the duplicate network of lesson 7. The state is empty for
that key, so to the old configuration nothing exists. The bucket's versioning still holds the
deleted object, which is how you would recover from the mistake, but the defence is to prevent it.
Do the split when nobody else is applying, merge it as one change, and tell everybody who runs
Terraform on the shop to pull before they plan.

This was the fast way, and it has a cost: nobody reviewed the `state mv` commands, and nothing in
the repository records that they ran. Two sections on, the same kind of move is done from inside the
configurations, where a pull request shows it.
