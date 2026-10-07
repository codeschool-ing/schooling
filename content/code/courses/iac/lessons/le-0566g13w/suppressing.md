---
title: Suppressing a finding, with a reason and a date
version: 2
---

Every scanner lets you silence a finding, and the wrong idea about that is that silencing is how you
make the build green. **A suppression is a decision**, written beside the resource it is about, and
it is worth exactly as much as the reason written with it. Thirteen findings is a normal first
report. Some are real problems, some are choices the shop has made on purpose, and some are the
scanner being wrong about this configuration. The second and third kinds are what suppressions are
for. The SSH rule is the first kind, and a comment would not make port 22 any less open.

Ana works through Checkov's list and writes two suppressions with a reason, one Trivy ignore, and
one Checkov skip with no reason at all, on purpose, to show what the report makes of it. Here they
are as the reviewer sees them, and as you make them in your own `main.tf`:

```
ana@laptop:~/shop$ git diff
diff --git a/main.tf b/main.tf
index de74f0b..ec8b8f0 100644
--- a/main.tf
+++ b/main.tf
@@ -24,6 +24,7 @@ resource "aws_subnet" "a" {
 }
 
 resource "aws_security_group" "web" {
+  #checkov:skip=CKV2_AWS_5:attached by the instances in the app configuration, not here
   name        = "web"
   description = "web servers"
   vpc_id      = aws_vpc.shop.id
@@ -39,7 +40,11 @@ resource "aws_vpc_security_group_ingress_rule" "https" {
   cidr_ipv4         = "0.0.0.0/0"
 }
 
+# SSE-S3 is enough for product photos; revisit when the shop has a KMS key
+#trivy:ignore:AWS-0132:exp:2027-03-31
 resource "aws_s3_bucket" "assets" {
+  #checkov:skip=CKV_AWS_144:the photos are rebuilt from the repository, a second region is not worth paying for
+  #checkov:skip=CKV2_AWS_62
   bucket = "shop-assets-123456789012"
 }
```

Each comment is the scanner's own syntax, and each sits in a precise place:

- `#checkov:skip=ID:reason` goes **inside** the resource block. The text after the second colon is
  the reason, and Checkov keeps it.
- `#trivy:ignore:ID` goes on the line **above** the block. Trivy's syntax has no reason field, so the
  reason is an ordinary comment on the line before it. `:exp:2027-03-31` gives it an expiry date.
- tfsec has `#tfsec:ignore:ID` in the same position as Trivy's. It reads neither of the other two,
  which is why its count does not move in this lesson.

The two Checkov reasons are different kinds of claim. `CKV2_AWS_5` wants the security group attached
to something, and in this configuration it is not, because the instances that use it live in the
app's configuration (lesson 8 split the state that way). The check is right about the file and wrong
about the system, which is what a false positive is. `CKV_AWS_144` asks for a copy of the bucket in a
second region, and the shop has decided the photos are not worth it: they are rebuilt from the
repository. Nothing is wrong there; a cost was weighed.

## What the report says afterwards

```
ana@laptop:~/shop$ checkov -d . --skip-download --compact --check CKV_AWS_144,CKV2_AWS_5,CKV2_AWS_62

       _               _
   ___| |__   ___  ___| | _______   __
  / __| '_ \ / _ \/ __| |/ / _ \ \ / /
 | (__| | | |  __/ (__|   < (_) \ V /
  \___|_| |_|\___|\___|_|\_\___/ \_/

By Prisma Cloud | version: 3.3.22 

terraform scan results:

Passed checks: 0, Failed checks: 0, Skipped checks: 3

Check: CKV2_AWS_62: "Ensure S3 buckets should have event notifications enabled"
	SKIPPED for resource: aws_s3_bucket.assets
	Suppress comment: No comment provided
	File: /main.tf:45-49
Check: CKV2_AWS_5: "Ensure that Security Groups are attached to another resource"
	SKIPPED for resource: aws_security_group.web
	Suppress comment: attached by the instances in the app configuration, not here
	File: /main.tf:26-32
Check: CKV_AWS_144: "Ensure that S3 bucket has cross-region replication enabled"
	SKIPPED for resource: aws_s3_bucket.assets
	Suppress comment: the photos are rebuilt from the repository, a second region is not worth paying for
	File: /main.tf:45-49
```

Three `SKIPPED`, and the reason travels with each one into the report. **The third says `No comment
provided`**, and that is what a reason-less skip looks like a year later: identical to a skip
somebody added at six in the evening to make a build pass. Nobody can argue with it, so nobody
removes it. A reviewer can push back on *the photos are rebuilt from the repository* if it stops
being true. Checkov does not refuse a skip without a reason, so the habit has to come from the
review.

Trivy's ignore removed one finding from `main.tf`:

```
ana@laptop:~/shop$ trivy config --skip-check-update -q . | grep -E "^(AWS-0132|Failures)"
Failures: 10 (UNKNOWN: 0, LOW: 3, MEDIUM: 2, HIGH: 5, CRITICAL: 0)
Failures: 1 (UNKNOWN: 0, LOW: 0, MEDIUM: 0, HIGH: 1, CRITICAL: 0)
```

## An expiry turns "later" into a date

*Revisit when the shop has a KMS key* is the kind of promise nobody keeps unprompted, and the expiry is what does the
prompting. To see it work, Ana moves the date into the past for one run:

```
ana@laptop:~/shop$ sed -i "s/exp:2027-03-31/exp:2026-03-31/" main.tf
ana@laptop:~/shop$ trivy config --skip-check-update -q . | grep -E "^(AWS-0132|Failures)"
Failures: 11 (UNKNOWN: 0, LOW: 3, MEDIUM: 2, HIGH: 6, CRITICAL: 0)
AWS-0132 (HIGH): Bucket does not encrypt data with a customer managed key.
Failures: 1 (UNKNOWN: 0, LOW: 0, MEDIUM: 0, HIGH: 1, CRITICAL: 0)
```

The finding is back, and the count with it. When the real date passes, the build fails on that
finding again and somebody has to decide once more, with whatever they now know. Checkov's inline
skip has no expiry field; the same effect there comes from a ticket, or from the baseline in section
08.

Ana puts the date back with the same `sed`, the two dates swapped,
`sed -i "s/exp:2026-03-31/exp:2027-03-31/" main.tf`, and commits the three suppressions as *suppress
three findings*. If you are reading this after 31 March 2027, that date has passed for you too and
the finding shows in both runs; a later date shows the difference.

## Where not to suppress

Scanners also take skips on the command line (`checkov --skip-check CKV2_AWS_5`) and in their
configuration files. Those silence a rule **for every resource**, including the one somebody adds
next month, and they live away from the code they affect, so a reviewer of the bucket never sees
them. An inline comment covers one resource and arrives in the same diff as the change it excuses.
Keep the global form for rules the whole organisation has decided not to run at all.
