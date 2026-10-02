---
title: Checkov, and how to read a finding
version: 1
---

Checkov is a Python program, published by Prisma Cloud (part of Palo Alto Networks), and it reads
far more than Terraform: CloudFormation, Kubernetes manifests, Dockerfiles, GitHub Actions
workflows. You point it at a directory with `-d` and it works out which of its frameworks apply.
The lab has this version:

```
ana@laptop:~/shop$ checkov --version
3.3.22
```

## It wants the network, and works without it

The first thing Checkov does on every run is ask Prisma Cloud's API for its *guidelines*, a mapping
from each check to a severity and a page of documentation. The lab has no network, so the request
fails, and Checkov says so with a warning and then a long Python traceback:

```
ana@laptop:~/shop$ checkov -d . 2>&1 | head -n 2
2026-10-02 07:40:56,627 [MainThread  ] [WARNI]  Failed to get the checkov mappings and guidelines from https://api0.prismacloud.io/bridgecrew/api/v2/guidelines. Skips using BC_* IDs will not work.
Traceback (most recent call last):
```

**The scan carries on after the traceback**, and its results are the same. What is lost is the
download itself, and `--skip-download` is Checkov's own switch for not trying. Every run in this
lesson from here on passes it. Two things go missing with the download, and both matter later:
**severities**, because Checkov's checks carry none of their own, and the `Guide:` line that a
connected run prints under each finding with a link to the rule's documentation page. Keep the
first one in mind for the triage section.

## The whole report

Two flags make the report readable: `--quiet` prints only what failed, and `--compact` leaves out the
code of each resource.

```
ana@laptop:~/shop$ checkov -d . --skip-download --quiet --compact
terraform scan results:

Passed checks: 22, Failed checks: 13, Skipped checks: 0

Check: CKV_AWS_189: "Ensure EBS Volume is encrypted by KMS using a customer managed Key (CMK)"
	FAILED for resource: aws_ebs_volume.data
	File: /main.tf:46-50
Check: CKV_AWS_3: "Ensure all data stored in the EBS is securely encrypted"
	FAILED for resource: aws_ebs_volume.data
	File: /main.tf:46-50
Check: CKV_AWS_24: "Ensure no security groups allow ingress from 0.0.0.0:0 to port 22"
	FAILED for resource: aws_vpc_security_group_ingress_rule.ssh
	File: /ssh.tf:1-8
Check: CKV_AWS_18: "Ensure the S3 bucket has access logging enabled"
	FAILED for resource: aws_s3_bucket.assets
	File: /main.tf:42-44
Check: CKV2_AWS_6: "Ensure that S3 bucket has a Public Access block"
	FAILED for resource: aws_s3_bucket.assets
	File: /main.tf:42-44
Check: CKV2_AWS_62: "Ensure S3 buckets should have event notifications enabled"
	FAILED for resource: aws_s3_bucket.assets
	File: /main.tf:42-44
Check: CKV2_AWS_11: "Ensure VPC flow logging is enabled in all VPCs"
	FAILED for resource: aws_vpc.shop
	File: /main.tf:14-17
Check: CKV2_AWS_5: "Ensure that Security Groups are attached to another resource"
	FAILED for resource: aws_security_group.web
	File: /main.tf:26-31
Check: CKV2_AWS_12: "Ensure the default security group of every VPC restricts all traffic"
	FAILED for resource: aws_vpc.shop
	File: /main.tf:14-17
Check: CKV2_AWS_61: "Ensure that an S3 bucket has a lifecycle configuration"
	FAILED for resource: aws_s3_bucket.assets
	File: /main.tf:42-44
Check: CKV_AWS_144: "Ensure that S3 bucket has cross-region replication enabled"
	FAILED for resource: aws_s3_bucket.assets
	File: /main.tf:42-44
Check: CKV_AWS_21: "Ensure all data stored in the S3 bucket have versioning enabled"
	FAILED for resource: aws_s3_bucket.assets
	File: /main.tf:42-44
Check: CKV_AWS_145: "Ensure that S3 buckets are encrypted with KMS by default"
	FAILED for resource: aws_s3_bucket.assets
	File: /main.tf:42-44
```

Thirteen of 35 checks failed, and only one of them is the SSH rule from the pull request. The other
twelve were there before it, and say, among other things, that the bucket has no public access block, no versioning, no access
logging, no lifecycle rules and no copy in a second region; the volume is not encrypted; the VPC
has no flow logs. Checkov runs its checks in parallel, so the order of the list is not stable from
one run to the next. Sort or filter it before comparing two reports.

## Reading one finding

```
ana@laptop:~/shop$ checkov -d . --skip-download --quiet --check CKV_AWS_24
terraform scan results:

Passed checks: 2, Failed checks: 1, Skipped checks: 0

Check: CKV_AWS_24: "Ensure no security groups allow ingress from 0.0.0.0:0 to port 22"
	FAILED for resource: aws_vpc_security_group_ingress_rule.ssh
	File: /ssh.tf:1-8

		1 | resource "aws_vpc_security_group_ingress_rule" "ssh" {
		2 |   security_group_id = aws_security_group.web.id
		3 |   description       = "SSH for maintenance"
		4 |   ip_protocol       = "tcp"
		5 |   from_port         = 22
		6 |   to_port           = 22
		7 |   cidr_ipv4         = "0.0.0.0/0"
		8 | }
```

**Each finding has the same four parts**, and each answers a different question:

| part | here | what it tells you |
|---|---|---|
| the check | `CKV_AWS_24` and its title | which rule, and the id you will quote to skip it |
| the resource | `aws_vpc_security_group_ingress_rule.ssh` | the address, exactly as Terraform writes it |
| the place | `/ssh.tf:1-8` | the file and lines, relative to the directory scanned |
| the code | the eight numbered lines | what the rule looked at |

The id has a pattern. `CKV_AWS_` checks look at one resource on its own. `CKV2_AWS_` checks look at
the connections between resources, which is how `CKV2_AWS_6` can say the bucket has no public access
block: it searched the configuration for an `aws_s3_bucket_public_access_block` pointing at this
bucket and found none.

## A rule of your own

The catalogue knows nothing about the shop. Ana's company allows SSH only from the office, whose
range is `203.0.113.0/24`, and no built-in rule can know that number. Checkov reads extra checks from
a directory, and a check can be a few lines of YAML:

```yaml
metadata:
  id: "CKV2_SHOP_1"
  name: "SSH is only allowed from the office range"
  category: "NETWORKING"
definition:
  or:
    - cond_type: "attribute"
      resource_types: ["aws_vpc_security_group_ingress_rule"]
      attribute: "from_port"
      operator: "not_equals"
      value: 22
    - cond_type: "attribute"
      resource_types: ["aws_vpc_security_group_ingress_rule"]
      attribute: "cidr_ipv4"
      operator: "equals"
      value: "203.0.113.0/24"
```

It passes an ingress rule that is not for port 22, or one that comes from the office, and fails
anything else:

```
ana@laptop:~/shop$ checkov -d . --skip-download --quiet --compact --external-checks-dir ~/policies --check CKV2_SHOP_1
terraform scan results:

Passed checks: 1, Failed checks: 1, Skipped checks: 0

Check: CKV2_SHOP_1: "SSH is only allowed from the office range"
	FAILED for resource: aws_vpc_security_group_ingress_rule.ssh
	File: /ssh.tf:1-8
```

The HTTPS rule passed, because it is not port 22; the SSH rule failed. This is the most useful kind
of policy as code: a decision your organisation made, written where every change meets it.
