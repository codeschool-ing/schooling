---
title: A gate is an exit status
version: 1
---

**A quality gate is a check whose exit status decides whether the change goes on. Zero lets it through; anything else stops it.** That is all a pipeline understands, and it is why every tool in
lesson 12 was run with an `echo` of its exit status after it. This section writes the gates into one
script, runs it on the clinic's configuration, and then watches it stop a change.

Work in `~/aws/clinic`, the directory lesson 12 left, with the fixed `main.tf` from that lesson's
section on scanning: the export bucket, its public access block, its versioning and five skips with
reasons. Terraform and Checkov are the ones lesson 12 installed. Start moto empty.

## The script

Save this as `gate.sh` in that directory:

```schooling-example
{"language": "bash", "file": "gate.sh", "parts": [
 {"code": "#!/usr/bin/env bash\n# gate.sh: the checks a change to the clinic's infrastructure passes before anybody applies it.\n# Run it in the Terraform directory. It stops at the first gate that fails.\nset -uo pipefail\n\n", "note": "A plain shell script, so the same file runs on a laptop and in any pipeline. Each gate either passes or ends the script with a non-zero exit status, and that status is the whole contract with whatever runs it."},
 {"code": "# The findings that stop a change. Every other finding is printed and lets it through.\nBLOCKING=CKV_AWS_70,CKV_AWS_20,CKV_AWS_57,CKV2_AWS_6,CKV_AWS_24,CKV_AWS_62,CKV_SECRET_2\n\n", "note": "The list of findings that block, written at the top where a reviewer of the script sees it. The next section says why these seven and not the scanner's full catalogue."},
 {"code": "gate() { printf '== %s\\n' \"$1\"; }\n\n", "note": "A heading before each gate, so that a log read the next morning says which gate stopped the change."},
 {"code": "gate format\nterraform fmt -check || exit 1\n\ngate validate\nterraform validate -no-color > /dev/null || exit 1\n\n", "note": "The cheapest gates first. `fmt -check` changes nothing and fails if any file is not in Terraform's standard layout; `validate` fails if the configuration does not make sense to Terraform at all."},
 {"code": "gate scan\ncheckov -d . --compact --quiet --skip-download --hard-fail-on \"$BLOCKING\" || exit 1\n\n", "note": "Lesson 12's scan, now over every framework Checkov knows, secrets included. `--hard-fail-on` makes only the listed checks decide the exit status; every other failure is still printed."},
 {"code": "gate plan\nterraform plan -input=false -no-color -detailed-exitcode -out=plan.bin > plan.txt\ncase $? in\n  0) echo \"no changes: nothing to approve\" ;;\n  2) grep '^Plan:' plan.txt; echo \"plan.bin waits for a reviewer\" ;;\n  *) cat plan.txt; exit 1 ;;\nesac\n", "note": "`-detailed-exitcode` gives the plan three answers instead of two: 0 for no changes, 2 for changes, 1 for an error. The plan is saved, because the apply must use the plan the reviewer read."}
]}
```

A real pipeline runs the same steps, one job each, and shows each gate as a row that turns green or
red. Writing it as one script first has a use beyond this lab: **the gate a developer can run on
their own laptop is the gate they run before pushing**, so the pipeline seldom finds anything new.

## A change that passes

```
ana@laptop:~/aws/clinic$ bash gate.sh; echo "exit status $?"
== format
== validate
== scan
terraform scan results:

Passed checks: 11, Failed checks: 0, Skipped checks: 5


== plan
Plan: 3 to add, 0 to change, 0 to destroy.
plan.bin waits for a reviewer
exit status 0
```

Four headings, no failures and five skips from lesson 12, and a plan of three resources waiting for a
reviewer. When the reviewer approves, the apply uses **the saved plan**, so what is created is
exactly what was read:

```
ana@laptop:~/aws/clinic$ terraform apply -no-color plan.bin | tail -1
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
ana@laptop:~/aws/clinic$ bash gate.sh; echo "exit status $?"
== format
== validate
== scan
terraform scan results:

Passed checks: 11, Failed checks: 0, Skipped checks: 5


== plan
no changes: nothing to approve
exit status 0
```

If the apply stops with `lookup 123456789012.localhost` and `no such host`, your machine does not
resolve names under `localhost` by itself, which Ubuntu does and WSL may not. The provider reaches
moto at that name when it reads a bucket's tags, and one line in `/etc/hosts` fixes it:
`echo '127.0.0.1 123456789012.localhost' | sudo tee -a /etc/hosts`.

Run again with nothing changed, the plan answers `0`, and the gate says there is nothing to approve.
**That second run is also the cheapest drift check there is**: had somebody changed the bucket in the
console since the apply, the plan would show the change needed to put it back.

## A change that stops

caio's pull request brings the tablet back the quick way, in a file of its own. Save it as
`tablet.tf`, beside `main.tf`:

```hcl
# The reception's tablet reads the day's export.
resource "aws_s3_bucket_policy" "tablet" {
  bucket = aws_s3_bucket.exports.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "arn:aws:s3:::${local.bucket}/*"
    }]
  })
}
```

```
ana@laptop:~/aws/clinic$ bash gate.sh; echo "exit status $?"
== format
== validate
== scan
terraform scan results:

Passed checks: 12, Failed checks: 1, Skipped checks: 5

Check: CKV_AWS_70: "Ensure S3 bucket does not allow an action with any Principal"
	FAILED for resource: aws_s3_bucket_policy.tablet
	File: /tablet.tf:2-13

exit status 1
```

The scan names the policy, the script stops, and **the plan never runs**, so nobody is asked to review
a change a machine has already refused. The pull request shows a red row and the reason in its log.

On a real account the apply would have failed too, later and more confusingly: the bucket's public
access block, with `block_public_policy` on, makes AWS refuse a public policy. moto does not enforce
that block, as lesson 9 shows, so the lab cannot show that refusal and the claim comes from AWS's
documentation. A gate that catches it in seconds, with the rule's name, is a better place to learn of
it than an error during an apply.

Remove the file before the next section:

```sh
rm tablet.tf
```
