---
title: The accident, step by step
version: 1
---

The state file is Terraform's memory of what it made. **Losing it does not delete anything in the
cloud; it makes Terraform forget that it made it**, and a Terraform that has forgotten will try to make
everything again. This lesson stages the accident on purpose, so the way out is something you have
done once before you need it.

The shop's configuration holds four resources, with its state in the bucket lesson 6 built:

```hcl
# shop/main.tf
terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "6.67.0" }
  }
  backend "s3" {
    bucket         = "shop-tfstate-123456789012"
    key            = "shop/terraform.tfstate"
    region         = "sa-east-1"
    encrypt        = true
    use_path_style = true
    use_lockfile   = true
  }
}

provider "aws" {
  region            = "sa-east-1"
  s3_use_path_style = true
}

resource "aws_sns_topic" "alerts" {
  name = "shop-alerts"
}

resource "aws_dynamodb_table" "orders" {
  name         = "shop-orders"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"
  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_cloudwatch_log_group" "web" {
  name              = "/shop/web"
  retention_in_days = 14
}

resource "aws_s3_bucket" "uploads" {
  bucket = "shop-uploads-123456789012"
}
```

```
ana@laptop:~/aws/tf7/shop$ terraform apply -auto-approve -input=false -no-color | grep -E '^(Apply|Outputs)'
Apply complete! Resources: 4 added, 0 changed, 0 destroyed.
ana@laptop:~/aws/tf7/shop$ terraform state list
aws_cloudwatch_log_group.web
aws_dynamodb_table.orders
aws_s3_bucket.uploads
aws_sns_topic.alerts
```

## The accident

Somebody tidying the state bucket deletes what looks like an old file:

```
ana@laptop:~/aws/tf7/shop$ aws s3 rm s3://shop-tfstate-123456789012/shop/terraform.tfstate
delete: s3://shop-tfstate-123456789012/shop/terraform.tfstate
```

Nothing in the account changed: the topic, the table, the log group and the bucket are all still
there, serving traffic. Ask Terraform:

```
ana@laptop:~/aws/tf7/shop$ terraform plan -no-color | grep -E '^  # |^Plan:'
  # aws_cloudwatch_log_group.web will be created
  # aws_dynamodb_table.orders will be created
  # aws_s3_bucket.uploads will be created
  # aws_sns_topic.alerts will be created
Plan: 4 to add, 0 to change, 0 to destroy.
```

**Four to add.** Terraform reads its state, finds nothing, and concludes that none of the four exist.
The plan is calm and wrong, and it looks exactly like the plan for an empty account.

## What applying it would do

The next person to run the pipeline does not read the plan carefully:

```
ana@laptop:~/aws/tf7/shop$ terraform apply -auto-approve -input=false -no-color 2>&1 | grep -E '^(aws_.*(complete|Creating)|Error:)' 
aws_cloudwatch_log_group.web: Creating...
aws_s3_bucket.uploads: Creating...
aws_sns_topic.alerts: Creating...
aws_dynamodb_table.orders: Creating...
aws_sns_topic.alerts: Creation complete after 0s [id=arn:aws:sns:sa-east-1:123456789012:shop-alerts]
Error: creating AWS DynamoDB Table (shop-orders): operation error DynamoDB: CreateTable, https response error StatusCode: 400, RequestID: raRO4kfrfB1RajNvqFMUbADigUh7KFbS44GgTeSPdFoHvsSeTL4Q, ResourceInUseException: Table already exists: shop-orders
Error: creating CloudWatch Logs Log Group (/shop/web): operation error CloudWatch Logs: CreateLogGroup, https response error StatusCode: 400, RequestID: I8QTPzPT6LB55jXymliGEgaNyEJJlPvTsbp8BuUXU1SguhqEyLi0, ResourceAlreadyExistsException: The specified log group already exists
Error: creating S3 Bucket (shop-uploads-123456789012): operation error S3: CreateBucket, https response error StatusCode: 409, RequestID: NRhyDYuqLlymd5pVI5DIf9jKdsG6mgDYZnahjzLCarzHSBf8wTL7, HostID: 9Gjjt1m+cjU4OPvX9O9/8RuvnG41MRb/18Oux2o5H5MY7ISNTlXN+Dz9IG62/ILVxhAGI0qyPfg=, BucketAlreadyOwnedByYou: Your previous request to create the named bucket succeeded and you already own it.
ana@laptop:~/aws/tf7/shop$ terraform state list
aws_sns_topic.alerts
```

Read the results one by one, because they differ, and the difference is the danger:

- **the topic was adopted in silence**: creating an SNS topic with a name that exists returns the
  existing topic, so Terraform recorded it as made, and nothing is visibly wrong;
- **the table, the log group and the bucket failed**, each with its service's own "already exists".

The state now holds one resource out of four. Every later plan will try to create three things that
exist, and fail the same way, until somebody repairs the record. A worse version of the same accident
happens with a resource that has **no name**, such as a security group rule or an EC2 instance: the
create succeeds, and the account now holds two of it, one that Terraform manages and one nobody does.

**The rule is short: when a plan wants to create something you know exists, stop.** It is never
telling you that the resource is missing. It is telling you that the state is.
