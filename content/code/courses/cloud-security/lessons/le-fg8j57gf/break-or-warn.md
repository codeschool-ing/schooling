---
title: What breaks the build, and what only warns
version: 1
---

**A gate that blocks on every finding gets switched off, and a gate that blocks on nothing is a
report nobody reads. The useful line runs between findings that expose something or grant everything,
which block, and findings about hygiene, which are printed and let the change through.** The list at
the top of `gate.sh` is where the clinic drew that line, and it is short on purpose.

## The seven that block

| check | what it catches | why it blocks |
|---|---|---|
| `CKV_AWS_70` | a bucket policy allowing an action to any principal | lesson 1's mistake: data readable by anybody |
| `CKV_AWS_20`, `CKV_AWS_57` | a bucket ACL granting public read or public write | the same exposure by the older route lesson 9 describes |
| `CKV2_AWS_6` | a bucket with no public access block | the guardrail that would refuse both of the above |
| `CKV_AWS_24` | a security group open to the internet on port 22 | a login prompt offered to the whole internet, lesson 3's example |
| `CKV_AWS_62` | an IAM policy allowing every action on every resource | administrator rights handed out in a pull request |
| `CKV_SECRET_2` | an AWS access key in the code | lesson 12's leak, caught before the push is accepted |

Each one is a finding where the harm happens the moment the change is applied, and where no reading
of the circumstances makes it acceptable for the clinic. That is the test for adding a check to the
list: **would you stop a release for it at five on a Friday?** If the honest answer is "it depends",
it belongs among the warnings, where a reviewer weighs it.

## A change that warns

caio tries again. This time the tablet gets a bucket of its own, private, with a public access block,
and nothing else. Save it as `tablet.tf`:

```hcl
# A bucket of its own for the file the reception's tablet reads.
resource "aws_s3_bucket" "tablet" {
  bucket = "clinic-tablet"
}

resource "aws_s3_bucket_public_access_block" "tablet" {
  bucket                  = aws_s3_bucket.tablet.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}
```

```
ana@laptop:~/aws/clinic$ bash gate.sh; echo "exit status $?"
== format
== validate
== scan
terraform scan results:

Passed checks: 20, Failed checks: 6, Skipped checks: 5

Check: CKV2_AWS_62: "Ensure S3 buckets should have event notifications enabled"
	FAILED for resource: aws_s3_bucket.tablet
	File: /tablet.tf:2-4
Check: CKV_AWS_18: "Ensure the S3 bucket has access logging enabled"
	FAILED for resource: aws_s3_bucket.tablet
	File: /tablet.tf:2-4
Check: CKV2_AWS_61: "Ensure that an S3 bucket has a lifecycle configuration"
	FAILED for resource: aws_s3_bucket.tablet
	File: /tablet.tf:2-4
Check: CKV_AWS_144: "Ensure that S3 bucket has cross-region replication enabled"
	FAILED for resource: aws_s3_bucket.tablet
	File: /tablet.tf:2-4
Check: CKV_AWS_145: "Ensure that S3 buckets are encrypted with KMS by default"
	FAILED for resource: aws_s3_bucket.tablet
	File: /tablet.tf:2-4
Check: CKV_AWS_21: "Ensure all data stored in the S3 bucket have versioning enabled"
	FAILED for resource: aws_s3_bucket.tablet
	File: /tablet.tf:2-4

== plan
Plan: 2 to add, 0 to change, 0 to destroy.
plan.bin waits for a reviewer
exit status 0
```

Six findings, all printed, none on the list: no logging, no event notifications, no lifecycle, no
replication, no versioning, no KMS key. The gate goes on to the plan, and **the six warnings go to the
reviewer** with it. Some deserve an answer before approval: a bucket the tablet reads every day
probably wants a lifecycle rule, so yesterday's file does not stay forever. Others get a skip with a
reason, as lesson 12's bucket did. Either way a person decides, with the finding in front of them.

## Exceptions, and their expiry

Sooner or later a blocking finding has a reason. A vendor's integration needs, for one month, a bucket
it can read without signing. The wrong answer is to delete `CKV_AWS_70` from the list, which turns the
check off for every future change too. The right one is an exception **for that resource, with a
reason, an owner and an end date**:

```hcl
resource "aws_s3_bucket_policy" "vendor_import" {
  #checkov:skip=CKV_AWS_70:vendor import, approved by ana until 2026-11-30, ticket SEC-114
  bucket = aws_s3_bucket.vendor.id
  policy = data.aws_iam_policy_document.vendor_import.json
}
```

Checkov reads the comment as a skip, so the gate passes. Checkov does not read the date. **An
exception with an end date is only as good as whatever looks at the date**: a calendar reminder for
the owner, a line in the team's list of exceptions that is read every month, or a check of its own.
The block above was not run: it names a bucket and a policy document this lab does not have.

## Who moves the line

The list in `gate.sh` is code, so it changes the way code changes: in a pull request, reviewed by
somebody other than the person asking. A gate whose blocking list can be edited in the same pull
request it is judging guards nothing. Pipelines protect the file with a rule that changes to it need
an approval from the security owner. GitHub calls such a rule a code owner, and GitLab has the same
idea under the same name.

::: track devsecops
The `secure-pipeline` course's lesson 7 drew this line for application findings, with severities and
budgets. The difference here is that an infrastructure finding is a configuration, so the harm
arrives with the apply rather than with an attacker's later effort, and the blocking list is shorter
and stricter for it.
:::

::: track *
The same question, when to break the build and when to warn, comes up for findings in application
code, where severity scores and agreed budgets usually decide it. An infrastructure finding is
different in one way: it is a configuration, so the harm arrives with the apply, and the blocking list
can be short and strict.
:::

Remove `tablet.tf` before the next section, or keep it to apply later; nothing else in this lesson
depends on it.
