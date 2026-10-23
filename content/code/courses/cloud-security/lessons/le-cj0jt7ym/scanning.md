---
title: A scanner reads it too
version: 1
---

**A scanner such as Checkov reads infrastructure code and checks every resource against a library of
rules, each with an id, before anything is planned or applied.** It needs no account and no
credentials, so it runs on a laptop, in a pull request, anywhere. What it cannot do is decide which
of its findings matter to you, and most of this section is about that.

Run it on the directory, as the previous section left it. `--framework terraform` limits it to the
`.tf` files, `--compact` leaves out the code it would otherwise quote under every finding,
`--quiet` lists only failures, and `--skip-download` stops it fetching extra guidance from its
vendor's servers, so it works offline. The `echo` after it prints the exit status Checkov left behind:

```
ana@laptop:~/aws/clinic$ checkov -d . --framework terraform --compact --quiet --skip-download; echo "exit status $?"
terraform scan results:

Passed checks: 6, Failed checks: 8, Skipped checks: 0

Check: CKV_AWS_70: "Ensure S3 bucket does not allow an action with any Principal"
	FAILED for resource: aws_s3_bucket_policy.tablet
	File: /main.tf:21-32
Check: CKV2_AWS_6: "Ensure that S3 bucket has a Public Access block"
	FAILED for resource: aws_s3_bucket.exports
	File: /main.tf:16-18
Check: CKV2_AWS_62: "Ensure S3 buckets should have event notifications enabled"
	FAILED for resource: aws_s3_bucket.exports
	File: /main.tf:16-18
Check: CKV_AWS_18: "Ensure the S3 bucket has access logging enabled"
	FAILED for resource: aws_s3_bucket.exports
	File: /main.tf:16-18
Check: CKV_AWS_144: "Ensure that S3 bucket has cross-region replication enabled"
	FAILED for resource: aws_s3_bucket.exports
	File: /main.tf:16-18
Check: CKV2_AWS_61: "Ensure that an S3 bucket has a lifecycle configuration"
	FAILED for resource: aws_s3_bucket.exports
	File: /main.tf:16-18
Check: CKV_AWS_21: "Ensure all data stored in the S3 bucket have versioning enabled"
	FAILED for resource: aws_s3_bucket.exports
	File: /main.tf:16-18
Check: CKV_AWS_145: "Ensure that S3 buckets are encrypted with KMS by default"
	FAILED for resource: aws_s3_bucket.exports
	File: /main.tf:16-18

exit status 1
```

Eight failed checks and an exit status of `1`, and the eight are not of one kind:

| check | what it says | for this bucket |
|---|---|---|
| `CKV_AWS_70` | a policy allows an action to any principal | **the defect**: the tablet policy |
| `CKV2_AWS_6` | the bucket has no public access block | **the missing guardrail** that would have refused the policy |
| `CKV_AWS_21` | versioning is off | worth having: an overwritten or deleted export comes back |
| `CKV_AWS_144`, `CKV2_AWS_62`, `CKV2_AWS_61`, `CKV_AWS_18`, `CKV_AWS_145` | no replication, event notifications, lifecycle, access logging or KMS key | decisions, each with an answer that depends on the bucket |

**The two at the top are the finding; the five at the bottom are questions.** A scanner applies the
same rules to a bucket of patient exports and to a bucket of public images, and it cannot know which
it is looking at. Fixing all eight because the tool said so is how a team ends up with replication
nobody needed. Ignoring all eight because five were noise is how the policy ships.

## The fixed file

The tablet does not need a public bucket. It needs one file a day, and lesson 10 shows how to hand a
device a single object for a limited time without making anything public. So the policy goes, a
public access block and versioning arrive, and each of the five questions is answered **in the file,
with a reason**, as a skip comment Checkov reads. Replace `main.tf` with this:

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
  #checkov:skip=CKV_AWS_144:a daily export the application can rebuild needs no second region
  #checkov:skip=CKV2_AWS_62:nothing consumes events from this bucket
  #checkov:skip=CKV2_AWS_61:the application deletes each export after 30 days
  #checkov:skip=CKV_AWS_18:access logging is decided for every bucket at once, in lesson 15
  #checkov:skip=CKV_AWS_145:the default SSE-S3 encryption stays until lesson 11 decides on a key
  bucket = local.bucket
}

resource "aws_s3_bucket_public_access_block" "exports" {
  bucket                  = aws_s3_bucket.exports.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "exports" {
  bucket = aws_s3_bucket.exports.id
  versioning_configuration {
    status = "Enabled"
  }
}
```

```
ana@laptop:~/aws/clinic$ checkov -d . --framework terraform --compact --quiet --skip-download; echo "exit status $?"
terraform scan results:

Passed checks: 11, Failed checks: 0, Skipped checks: 5


exit status 0
```

No failures, eleven passes, five skipped, and an exit status of `0`. **That exit status is what a
pipeline reads**, and lesson 14 builds a gate on it. The skips are not hidden: they are counted in
every run, and each one carries a sentence somebody can disagree with in a review. A skip with no
reason is a finding switched off; a skip with a reason is a decision on the record.

The plan agrees with the scanner. Ask the previous section's question again:

```
ana@laptop:~/aws/clinic$ terraform plan -out=plan.bin -no-color > /dev/null
ana@laptop:~/aws/clinic$ terraform show -json plan.bin | jq -r '[.resource_changes[].address] | .[]'
aws_s3_bucket.exports
aws_s3_bucket_public_access_block.exports
aws_s3_bucket_versioning.exports
```

Three resources, and no policy among them.

## What a scanner does not see

Checkov reads the files, so it knows what the code asks for and nothing about the account the code
will meet. A bucket made public by hand in the console, a policy attached by another configuration, a
setting changed after the last apply: none of them is in these files. Reading the account as it is,
rather than as the code describes it, is lesson 16's subject. The two are complementary, and neither
replaces the other.
