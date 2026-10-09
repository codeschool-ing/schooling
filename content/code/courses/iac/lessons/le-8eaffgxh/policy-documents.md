---
title: Documents built by a data source
version: 2
---

Not every data source asks a cloud anything. Some compute their answer on the laptop, from what you
give them, and the most used of those builds **IAM policy documents**: the JSON that says who may do
what to which resource. A policy can be written as a string of JSON inside the configuration, and it
works. It is also a block of text Terraform cannot check, where a missing comma is found by AWS at
apply time and a bucket name typed into an ARN is not updated when the bucket is renamed.

`data "aws_iam_policy_document"` writes the JSON for you from HCL blocks, so references, functions
and Terraform's own syntax checks all apply to it. Ana's bucket for the shop's images gets two
statements. The first refuses every request that does not use TLS, which is a common baseline for
buckets. The second lets the account read objects, but only from the office's addresses, which the
security team keeps in a file in the repository, `office-cidrs.txt`:

```
203.0.113.0/28
198.51.100.32/29
```

The bucket, the document and the policy that joins them go in `bucket.tf`:

```hcl
resource "aws_s3_bucket" "assets" {
  bucket = "shop-assets-${data.aws_caller_identity.current.account_id}"
}

data "aws_iam_policy_document" "assets" {
  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.assets.arn, "${aws_s3_bucket.assets.arn}/*"]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid       = "OfficeReadsObjects"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.assets.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    condition {
      test     = "IpAddress"
      variable = "aws:SourceIp"
      values   = split("\n", trimspace(data.local_file.office.content))
    }
  }
}

data "local_file" "office" {
  filename = "${path.module}/office-cidrs.txt"
}

resource "aws_s3_bucket_policy" "assets" {
  bucket = aws_s3_bucket.assets.id
  policy = data.aws_iam_policy_document.assets.json
}
```

Three data sources meet in that file. **`data.aws_caller_identity`** from the first section gives
the bucket a name unique to the account and names the account in the second statement. **`data
"local_file"`** reads the office list; it comes from the `hashicorp/local` provider, and it reads a
file on the machine running Terraform rather than anything in AWS. And the policy document turns the
statements into JSON.

`local` is a provider this directory has not used before, so Ana runs `terraform init` again, and it
installs `hashicorp/local` beside `aws`. The plan then shows two different timings again:

```
ana@laptop:~/shop/app$ terraform plan
data.local_file.office: Reading...
data.local_file.office: Read complete after 0s [id=d31eb9db97a1f63a12b9d3ed7b67d80fde5b4ab8]
```
```
  # data.aws_iam_policy_document.assets will be read during apply
  # (config refers to values not yet known)
 <= data "aws_iam_policy_document" "assets" {
      + id            = (known after apply)
      + json          = (known after apply)
      + minified_json = (known after apply)

      + statement {
          + actions   = [
              + "s3:*",
            ]
          + effect    = "Deny"
          + resources = [
              + (known after apply),
              + (known after apply),
            ]
          + sid       = "DenyInsecureTransport"
```

The file was read first, at plan time, because its `filename` is known from the start, and so its
two ranges are already plain values further down the same document:

```
          + condition {
              + test     = "IpAddress"
              + values   = [
                  + "203.0.113.0/28",
                  + "198.51.100.32/29",
                ]
              + variable = "aws:SourceIp"
            }
```

The policy document is deferred, and this time for
the other reason: **its `resources` refer to the bucket's ARN, a value that does not exist until AWS
has made the bucket**, so the config refers to values not yet known. During the apply the order is
exactly what that implies:

```
Plan: 2 to add, 0 to change, 0 to destroy.
aws_s3_bucket.assets: Creating...
aws_s3_bucket.assets: Creation complete after 0s [id=shop-assets-123456789012]
data.aws_iam_policy_document.assets: Reading...
data.aws_iam_policy_document.assets: Read complete after 0s [id=2993801947]
aws_s3_bucket_policy.assets: Creating...
aws_s3_bucket_policy.assets: Creation complete after 0s [id=shop-assets-123456789012]

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```

The bucket, then the document, then the policy that needed both. What reached AWS is ordinary JSON,
read back here from the bucket itself:

```
ana@laptop:~/shop/app$ aws s3api get-bucket-policy --bucket shop-assets-123456789012 --query Policy --output text | jq .
{
  "Statement": [
    {
      "Action": "s3:*",
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      },
      "Effect": "Deny",
      "Principal": "*",
      "Resource": [
        "arn:aws:s3:::shop-assets-123456789012/*",
        "arn:aws:s3:::shop-assets-123456789012"
      ],
      "Sid": "DenyInsecureTransport"
    },
    {
      "Action": "s3:GetObject",
      "Condition": {
        "IpAddress": {
          "aws:SourceIp": [
            "203.0.113.0/28",
            "198.51.100.32/29"
          ]
        }
      },
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:root"
      },
      "Resource": "arn:aws:s3:::shop-assets-123456789012/*",
      "Sid": "OfficeReadsObjects"
    }
  ],
  "Version": "2012-10-17"
}
```

Two details in it came from the data source rather than from Ana. The `"Version": "2012-10-17"`
line, which every IAM policy should carry and which is easy to forget by hand, is added for you. And
the `Principal` of the first statement is the bare `"*"`, which is how AWS spells "anybody" when
written as `type = "*"`.

**A file read by a data source is part of the configuration's inputs, the same as a variable.**
Editing `office-cidrs.txt` changes the next plan, and the review of that pull request is where
somebody should ask why a new range appeared. For a file that exists before the plan, the `file()`
function reads it just as well; the data source earns its place when the file is
written by something else in the same run, and its read then waits like any other.
