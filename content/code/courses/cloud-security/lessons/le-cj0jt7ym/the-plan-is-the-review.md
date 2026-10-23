---
title: The plan is where the review happens
version: 1
---

**A pull request that changes infrastructure shows two things: the code, and the plan that code
produces. The plan is the one that says what will actually happen, and it is only as useful as what
it can see.** This section writes lesson 1's mistake in Terraform and watches the plan hide it, then
show it, then a query find it.

The wrong habit is reading the diff of the `.tf` files and skimming the plan as noise. The diff shows
what somebody typed. The plan shows what AWS will be asked to do, after variables, defaults and
references are resolved, and a reviewer approving the code without the plan has approved a change
they never saw.

## The export bucket, as code

caio moves the export bucket into Terraform, tablet policy included. Start moto empty, then make a
directory for the configuration:

```sh
mkdir -p ~/aws/clinic && cd ~/aws/clinic
```

Save this as `main.tf` there:

```hcl
terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "6.67.0" }
  }
}

provider "aws" {
  region            = "sa-east-1"
  s3_use_path_style = true
}

locals {
  bucket = "clinic-exports"
}

resource "aws_s3_bucket" "exports" {
  bucket = local.bucket
}

# The reception's tablet reads the day's export.
resource "aws_s3_bucket_policy" "tablet" {
  bucket = aws_s3_bucket.exports.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.exports.arn}/*"
    }]
  })
}
```

The policy is lesson 1's, word for word: `s3:GetObject` to `"Principal": "*"`. Run `terraform init`
once in the directory, then ask for the plan. The full plan lists every attribute of the bucket, so
`sed` cuts out the part about the policy:

```
ana@laptop:~/aws/clinic$ terraform plan -no-color | sed -n '/tablet will be created/,/^    }/p'
  # aws_s3_bucket_policy.tablet will be created
  + resource "aws_s3_bucket_policy" "tablet" {
      + bucket = (known after apply)
      + id     = (known after apply)
      + policy = (known after apply)
      + region = "sa-east-1"
    }
```

**The policy the review exists to catch is not in the plan.** It reads `(known after apply)`, because
the `Resource` line uses the bucket's ARN, an attribute Terraform treats as unknown until the bucket
has been created. A reviewer reading this plan sees a policy being attached and nothing of what it
says. The code still shows it, three screens away in a diff, and that is exactly where it gets
missed.

## Making it knowable

The ARN of a bucket is not a mystery: it is `arn:aws:s3:::` followed by the name, and the name is in
`local.bucket`. Change the `Resource` line so it is built from the name instead:

```hcl
      Resource  = "arn:aws:s3:::${local.bucket}/*"
```

```
ana@laptop:~/aws/clinic$ terraform plan -no-color | sed -n '/tablet will be created/,/^    }/p'
  # aws_s3_bucket_policy.tablet will be created
  + resource "aws_s3_bucket_policy" "tablet" {
      + bucket = (known after apply)
      + id     = (known after apply)
      + policy = jsonencode(
            {
              + Statement = [
                  + {
                      + Action    = "s3:GetObject"
                      + Effect    = "Allow"
                      + Principal = "*"
                      + Resource  = "arn:aws:s3:::clinic-exports/*"
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + region = "sa-east-1"
    }
```

Now the plan says it: `Principal = "*"`, `Action = "s3:GetObject"`. **Writing configuration so that
the plan can show its values is a security habit, not a style point**, because the plan is the
document a reviewer actually reads.

## A question instead of a reading

A person reading plans gets tired by the fortieth resource. A plan saved to a file can be turned into
JSON and asked a question, the same one every time: which statement, in any policy this change
writes, allows something to everybody?

```
ana@laptop:~/aws/clinic$ terraform plan -out=plan.bin -no-color > /dev/null
ana@laptop:~/aws/clinic$ terraform show -json plan.bin | jq -r '.resource_changes[] | select(.change.after.policy != null) | .address as $a | .change.after.policy | fromjson | .Statement[] | select(.Principal == "*") | "\($a)  \(.Effect)  \(.Action)"'
aws_s3_bucket_policy.tablet  Allow  s3:GetObject
```

One line per offending statement, naming the resource. The query has a blind spot, and it is the one
the first plan showed: **a policy that is still unknown at plan time has no value to query**, so it
passes in silence. A query like this one is a second reader, and it is only as good as the first fix,
which was making the value knowable.

Nothing has been applied, and nothing will be: the review happens before. The next section hands the
same file to a scanner that knows hundreds of questions like this one.
