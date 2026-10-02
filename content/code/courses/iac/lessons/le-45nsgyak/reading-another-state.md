---
title: Reading another configuration's outputs
version: 1
---

After the split the app finds its VPC with a data source that searches for the tag `Name = shop`.
It works today, and lesson 5 showed the day it stops working: somebody creates a second VPC with
that tag, and the search finds two. **A tag is a guess about another team's resources; an output
is a promise they made.** The network configuration already declares three outputs, and the plan
after the split offered to record them. Ana applies it, which changes no resource and writes the
values into the network's state:

```
ana@laptop:~/shop/network$ terraform apply -auto-approve | tail -n 9

Outputs:

public_subnet_ids = [
  "subnet-2fc7f0dc6fb32b7e4",
  "subnet-0bf2cbc4f593b157b",
]
vpc_cidr = "10.20.0.0/16"
vpc_id = "vpc-644904a24046c8bab"
```

## `terraform_remote_state`

A data source of a special kind reads those values. It is not part of the AWS provider; it is
built into Terraform, and it takes the same settings as a backend block, because what it does is
read another configuration's state from wherever that state is kept:

```hcl
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "shop-tfstate-123456789012"
    key    = "network/terraform.tfstate"
    region = "sa-east-1"
  }
}
```

The app's security group now asks for the output by name, and the tag search goes:

```
ana@laptop:~/shop/app$ git diff main.tf
diff --git a/app/main.tf b/app/main.tf
index d35d71b..72b1aa9 100644
--- a/app/main.tf
+++ b/app/main.tf
@@ -11,14 +11,10 @@ provider "aws" {
   region = "sa-east-1"
 }
 
-data "aws_vpc" "shop" {
-  tags = { Name = "shop" }
-}
-
 resource "aws_security_group" "web" {
   name        = "web"
   description = "web servers"
-  vpc_id      = data.aws_vpc.shop.id
+  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id
   tags        = { Name = "web" }
 
   ingress {
```

```
ana@laptop:~/shop/app$ terraform plan
data.terraform_remote_state.network: Reading...
data.terraform_remote_state.network: Read complete after 1s
aws_s3_bucket.assets: Refreshing state... [id=shop-assets-dev]
aws_s3_bucket.logs: Refreshing state... [id=shop-logs-dev]
aws_security_group.web: Refreshing state... [id=sg-020bb5a164511a5d9]

No changes. Your infrastructure matches the configuration.

Terraform has compared your real infrastructure against your configuration
and found no differences, so no changes are needed.
```

`No changes`: the VPC id the output gives is the one the tag search found, so the security group
stays where it is. The first two lines of the plan are the read: before refreshing anything of its own,
the app fetched `network/terraform.tfstate` from the bucket.

Of the other state, the app sees the `outputs` and nothing else. Once an apply has stored what the
data source read, `terraform console` shows it:

```
ana@laptop:~/shop/app$ terraform apply -auto-approve | tail -n 1
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
ana@laptop:~/shop/app$ echo "data.terraform_remote_state.network.outputs" | terraform console
{
  "public_subnet_ids" = [
    "subnet-2fc7f0dc6fb32b7e4",
    "subnet-0bf2cbc4f593b157b",
  ]
  "vpc_cidr" = "10.20.0.0/16"
  "vpc_id" = "vpc-644904a24046c8bab"
}
```

The resources of the network state are not in that object. Their ids, the route tables, the
subnets' every attribute: none of it can be referenced, only the three values the network chose to
publish.

## An output is a contract

Choosing what to output is choosing what other configurations may depend on, and lesson 2 said so
before there was anybody to depend on it. Here is what happens when the promise is broken. Somebody
tidies the network's names, renames `vpc_id` to `shop_vpc_id`, and applies:

```
ana@laptop:~/shop/network$ git diff outputs.tf
diff --git a/network/outputs.tf b/network/outputs.tf
index 235be31..d152748 100644
--- a/network/outputs.tf
+++ b/network/outputs.tf
@@ -1,4 +1,4 @@
-output "vpc_id" {
+output "shop_vpc_id" {
   description = "The shop's VPC."
   value       = aws_vpc.shop.id
 }
ana@laptop:~/shop/network$ terraform apply -auto-approve | grep -E "^Apply|vpc_id"
  + shop_vpc_id       = "vpc-644904a24046c8bab"
  - vpc_id            = "vpc-644904a24046c8bab" -> null
Apply complete! Resources: 0 added, 0 changed, 0 destroyed.
shop_vpc_id = "vpc-644904a24046c8bab"
```

The network's own plan is perfectly calm about it. **Nothing in the network configuration knows
who reads its outputs**, so removing one is an ordinary change that touches no resource. The app
finds out on its next plan:

```
ana@laptop:~/shop/app$ terraform plan
data.terraform_remote_state.network: Reading...
data.terraform_remote_state.network: Read complete after 0s
aws_security_group.web: Refreshing state... [id=sg-020bb5a164511a5d9]
aws_s3_bucket.logs: Refreshing state... [id=shop-logs-dev]
aws_s3_bucket.assets: Refreshing state... [id=shop-assets-dev]

Planning failed. Terraform encountered an error while generating this plan.

╷
│ Error: Unsupported attribute
│ 
│   on main.tf line 17, in resource "aws_security_group" "web":
│   17:   vpc_id      = data.terraform_remote_state.network.outputs.vpc_id
│     ├────────────────
│     │ data.terraform_remote_state.network.outputs is object with 3 attributes
│ 
│ This object does not have an attribute named "vpc_id".
╵
```

The plan fails before it can do harm, which is the good half. The bad half is that it fails for
the wrong team, maybe weeks later. So an output is treated the way a function's signature is:
adding one is free, while renaming or removing one is a change to announce, with the old name kept
alongside the new until every reader has moved. The network team put `vpc_id` back.

## What reading a state costs

`terraform_remote_state` shows only outputs to the configuration, and that is a restriction in
Terraform, not in S3. To read the outputs, the app has to **download the whole network state**, so
whoever runs the app's plan needs read access to the object, every attribute of every resource in
it included. For a network that is a map of the infrastructure; for a state that holds a database,
lesson 12 shows it also holds the password.

There are two common ways around it, and the right one depends on how much the two teams trust each
other. One is lesson 5's data sources, with the lookup made reliable by agreeing the tags as an
interface: the app needs permission to describe VPCs, nothing more. The other is to have the
network write the few values others need somewhere meant for sharing, such as an SSM parameter,
and the app read that. Both trade the convenience of one reference for a narrower door.
