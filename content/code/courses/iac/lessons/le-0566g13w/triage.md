---
title: Triage, and what should fail the build
version: 2
---

A scanner's report is a list of facts about the text, and the list is long. Ana first deletes the
plan files of section 07, `rm -f tfplan tfplan.json`, so that a scan of the directory reads the
configuration and not a leftover plan. After the suppressions and the variable, here is where the
three stand:

```
ana@laptop:~/shop$ checkov -d . --skip-download --quiet --compact | sed -n 3p
Passed checks: 23, Failed checks: 9, Skipped checks: 3
ana@laptop:~/shop$ trivy config --skip-check-update -q . | grep "^Failures"
Failures: 10 (UNKNOWN: 0, LOW: 3, MEDIUM: 2, HIGH: 5, CRITICAL: 0)
ana@laptop:~/shop$ tfsec --no-colour . 2> /dev/null | tail -n 2
  3 passed, 12 potential problem(s) detected.
```

Nine, ten and twelve findings on a VPC, a subnet, a security group, a bucket and a volume. A
pipeline that fails on any finding fails on every pull request, and a check that always fails is
switched off within a week. **Triage is deciding which findings stop a merge**, and the scanner
cannot do it for you, because the one thing it does not know is your system.

## Severity is not exposure

Look at two lines from Trivy's list in the trivy section. `AWS-0107`, SSH open to any address, is
`HIGH`. `AWS-0132`, a bucket not encrypted with a key the shop manages itself, is also `HIGH`. The
first is a port that answers anybody on the internet, on every server that will ever join the
group. The second is a choice of key for photos that the shop's website shows to every visitor
anyway.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" aria-label=\"A chart with two axes. Across, the severity the rule assigns: LOW, MEDIUM, HIGH. Up, the exposure of the resource. Six of Trivy's findings on the shop are placed on it. AWS-0107, SSH open to any address, is HIGH and at the top. AWS-0086, no public access block, is HIGH and in the middle. AWS-0132, no customer-managed key on a bucket of product photos, is also HIGH and near the bottom. AWS-0090, no versioning, and AWS-0178, no flow logs, are MEDIUM and low. AWS-0089, no access logging, is LOW and at the bottom.\"><defs><marker id=\"tg-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><path d=\"M110 262 L110 24\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tg-ah-wire)\"></path><path d=\"M110 262 L700 262\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tg-ah-wire)\"></path><text x=\"122.0\" y=\"24.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">exposure</text><text x=\"100.0\" y=\"62.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">high</text><text x=\"100.0\" y=\"236.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">low</text><text x=\"220.0\" y=\"276.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">LOW</text><text x=\"400.0\" y=\"276.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">MEDIUM</text><text x=\"580.0\" y=\"276.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">HIGH</text><text x=\"400.0\" y=\"296.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">the severity the rule assigns</text><rect x=\"505\" y=\"43\" width=\"150\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"580.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">AWS-0107</text><text x=\"580.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">SSH from any address</text><rect x=\"505\" y=\"121\" width=\"150\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"580.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">AWS-0086</text><text x=\"580.0\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no public access block</text><rect x=\"505\" y=\"199\" width=\"150\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"580.0\" y=\"211.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">AWS-0132</text><text x=\"580.0\" y=\"227.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no customer key, photos</text><rect x=\"325\" y=\"157\" width=\"150\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">AWS-0090</text><text x=\"400.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no versioning</text><rect x=\"325\" y=\"209\" width=\"150\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"400.0\" y=\"221.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">AWS-0178</text><text x=\"400.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no flow logs</text><rect x=\"145\" y=\"209\" width=\"150\" height=\"38\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"220.0\" y=\"221.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">AWS-0089</text><text x=\"220.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no access logging</text></svg>", "caption": "Severity is the rule author's estimate for any resource of that type. Exposure is what you know about this one, and two HIGH findings can sit at opposite ends of it."}
```

**Severity is the rule author's estimate for any resource of that type**, written before your
resource existed. **Exposure is what you know about this one**: whether it can be reached from the
internet, what it holds, what an attacker gains from it. A finding that is high on both axes is the
one to fix before merging. One that is high on severity and low on exposure is a decision to record,
which is what the suppressions in section 06 were.

## When a rule is simply wrong

One of tfsec's results says *Bucket does not have encryption enabled*. Checkov's check for the same
property passes the bucket:

```
ana@laptop:~/shop$ checkov -d . --skip-download --compact --check CKV_AWS_19 | grep -A1 assets
	PASSED for resource: aws_s3_bucket.assets
	File: /main.tf:45-49
```

and Trivy still carries the check, but only as a deprecated one, reported when asked for:

```
ana@laptop:~/shop$ trivy config --skip-check-update -q --include-deprecated-checks . | grep -E "^AWS-008[89]"
AWS-0088 (HIGH): Bucket does not have encryption enabled
AWS-0089 (LOW): Bucket has logging disabled
```

Since January 2023, S3 has encrypted every new object by default, so a bucket with no encryption
settings is encrypted anyway. The rule describes an older AWS. **That is the commonest false
positive**: a rule that was true when it was written, scanned against a platform that moved.

## The gate

A gate is a command that exits non-zero. Trivy takes a list of severities and an exit code, and its
answer depends entirely on where you draw the line:

```
ana@laptop:~/shop$ trivy config --skip-check-update -q --severity CRITICAL --exit-code 1 . > /dev/null; echo "exit $?"
exit 0
ana@laptop:~/shop$ trivy config --skip-check-update -q --severity HIGH,CRITICAL --exit-code 1 . > /dev/null; echo "exit $?"
exit 1
```

A gate at `CRITICAL` passes this configuration, open bucket settings and all, because Trivy rates
nothing here `CRITICAL`. A gate at `HIGH,CRITICAL` fails it. Checkov has the same idea in
`--hard-fail-on`, and without a Prisma Cloud account it has a trap in it:

```
ana@laptop:~/shop$ checkov -d . --skip-download --quiet --compact --hard-fail-on HIGH > /dev/null; echo "exit $?"
exit 0
ana@laptop:~/shop$ checkov -d . --skip-download --quiet --compact --hard-fail-on CKV_AWS_24,CKV2_AWS_6 > /dev/null; echo "exit $?"
exit 1
```

**`--hard-fail-on HIGH` exits 0.** Checkov's severities come only to a run signed in with a Prisma
Cloud API key (section 03), so here no finding is `HIGH`, nothing matches, and the gate passes
everything, quietly. A list of check ids has no such dependency and fails as it should. If your
Checkov runs without the platform, gate it on ids.

## Starting from where you are

The last piece is how to switch a gate on in a repository that already has findings. Fixing all of
them first means the gate never arrives. A **baseline** records today's findings as known, and
from then on only new ones fail:

```
ana@laptop:~/shop$ checkov -d . --skip-download --quiet --compact --create-baseline | tail -n 1
Created a checkov baseline file at /home/ana/shop/.checkov.baseline
```

Then somebody adds a backups bucket in `backups.tf`, with every gap the photo bucket had:

```hcl
resource "aws_s3_bucket" "backups" {
  bucket = "shop-backups-123456789012"
}
```

```
ana@laptop:~/shop$ checkov -d . --skip-download --quiet --compact --baseline .checkov.baseline; echo "exit $?"
terraform scan results:

Passed checks: 0, Failed checks: 7, Skipped checks: 0

Check: CKV2_AWS_6: "Ensure that S3 bucket has a Public Access block"
	FAILED for resource: aws_s3_bucket.backups
	File: /backups.tf:1-3
Check: CKV2_AWS_62: "Ensure S3 buckets should have event notifications enabled"
	FAILED for resource: aws_s3_bucket.backups
	File: /backups.tf:1-3
Check: CKV_AWS_18: "Ensure the S3 bucket has access logging enabled"
	FAILED for resource: aws_s3_bucket.backups
	File: /backups.tf:1-3
Check: CKV2_AWS_61: "Ensure that an S3 bucket has a lifecycle configuration"
	FAILED for resource: aws_s3_bucket.backups
	File: /backups.tf:1-3
Check: CKV_AWS_144: "Ensure that S3 bucket has cross-region replication enabled"
	FAILED for resource: aws_s3_bucket.backups
	File: /backups.tf:1-3
Check: CKV_AWS_145: "Ensure that S3 buckets are encrypted with KMS by default"
	FAILED for resource: aws_s3_bucket.backups
	File: /backups.tf:1-3
Check: CKV_AWS_21: "Ensure all data stored in the S3 bucket have versioning enabled"
	FAILED for resource: aws_s3_bucket.backups
	File: /backups.tf:1-3
Baseline analysis report using .checkov.baseline - only new failed checks with respect to the baseline are reported
exit 1
```

The nine old findings on the other resources are not in the report. The seven on the new bucket
are, and the exit code is 1. **New code meets the rules; old code is a list you work down**,
removing entries from the baseline as you fix them.

Put together, a gate Ana can defend is short. Fail on the findings that are high on both axes,
named by id, plus `HIGH` and `CRITICAL` from the scanner that has severities. Record every
exception inline, with a reason and, where it is a promise, a date. Baseline the rest and keep the
report visible. Lesson 15 puts this gate in a pipeline, next to the plan it protects.
