---
title: The state bucket, which has to exist first
version: 1
---

A remote backend keeps the state in a bucket, and `iac` lesson 7 put it there. Two questions it did
not have to answer come first on a real account: **who creates the bucket**, and **what the bucket
has to guarantee**, given that it holds the only record of what Terraform manages and often secrets
in plain text inside that record.

## Chicken and egg

The bucket cannot be created by the configuration whose state it will hold: that configuration needs
the bucket before its first `init`. The usual answers are a small separate configuration with a
**local** state, applied once and rarely touched, or a CloudFormation stack made by whoever sets up the
account. The shop uses the first:

```hcl
# bootstrap/main.tf
terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "6.67.0" }
  }
}

provider "aws" {
  region            = "sa-east-1"
  s3_use_path_style = true
}

resource "aws_s3_bucket" "state" {
  bucket = "shop-tfstate-123456789012"
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "locks" {
  name         = "shop-tflocks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}
```

Each resource is one guarantee:

- **versioning** keeps every earlier state as an older version of the same object, which is what
  makes lesson 7's accident survivable;
- **encryption with a KMS key** (lesson 18) means reading the object needs permission on the key as
  well as on the bucket, a second door in front of whatever secrets the state holds;
- **the public access block** makes a public bucket policy or ACL impossible to apply by mistake;
- **`prevent_destroy`** makes Terraform refuse any plan that would delete the bucket, including a
  `terraform destroy` run in the wrong directory.

The table is for the lock in the next section. Applied:

```
ana@laptop:~/aws/tf/bootstrap$ terraform apply -auto-approve -input=false -no-color | grep -E '^(aws_|Apply)'
aws_s3_bucket.state: Creating...
aws_dynamodb_table.locks: Creating...
aws_s3_bucket.state: Creation complete after 0s [id=shop-tfstate-123456789012]
aws_s3_bucket_versioning.state: Creating...
aws_s3_bucket_public_access_block.state: Creating...
aws_s3_bucket_server_side_encryption_configuration.state: Creating...
aws_s3_bucket_public_access_block.state: Creation complete after 0s [id=shop-tfstate-123456789012]
aws_s3_bucket_server_side_encryption_configuration.state: Creation complete after 0s [id=shop-tfstate-123456789012]
aws_s3_bucket_versioning.state: Creation complete after 1s [id=shop-tfstate-123456789012]
aws_dynamodb_table.locks: Creation complete after 6s [id=shop-tflocks]
Apply complete! Resources: 5 added, 0 changed, 0 destroyed.
ana@laptop:~/aws/tf/bootstrap$ aws s3api get-bucket-versioning --bucket shop-tfstate-123456789012
{
    "Status": "Enabled"
}
ana@laptop:~/aws/tf/bootstrap$ aws s3api get-public-access-block --bucket shop-tfstate-123456789012 --query PublicAccessBlockConfiguration
{
    "BlockPublicAcls": true,
    "IgnorePublicAcls": true,
    "BlockPublicPolicy": true,
    "RestrictPublicBuckets": true
}
```

The local `terraform.tfstate` of this small configuration is the one state file that lives outside
the bucket. Commit nothing of it, keep a copy somewhere safe, and expect to touch it about once a year.

## Who may read it

The bucket's permissions decide who can read every value Terraform stored, including any database
password a resource returned. **Read access to the state bucket is read access to production's
secrets**, so it belongs to the pipeline's role and to the few people who run Terraform by hand, and a
bucket policy refusing anything that does not come over TLS, as the CDK wrote in lesson 5, belongs on
it too. `iac` lesson 12 is about keeping secrets out of the state in the first place, which is the
better half of the answer.
