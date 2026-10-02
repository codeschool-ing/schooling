---
title: What a scanner sees, and what it cannot
version: 1
---

A security scanner for infrastructure code sounds like something that looks at your cloud. **It
looks at your files.** It parses the Terraform configuration, takes each resource with its
arguments, and holds it against a catalogue of rules, each of which is a small function: *does this
security group let port 22 in from `0.0.0.0/0`?*, *does this bucket have a public access block?*,
*is this volume encrypted?* It needs no credentials, calls no API and never opens the state. Lesson
13 placed it on the ladder of checks between `terraform validate` and a test run, and that is the
right place: as cheap as a linter, and able to answer only what the text can answer.

Ana's configuration for this lesson is the shop's network from earlier lessons, plus a bucket for
product photos and a data volume. One difference from lesson 7 is deliberate: each security group
rule is a resource of its own, `aws_vpc_security_group_ingress_rule`, which is the form the AWS
provider's documentation recommends and what lets a rule arrive in a file of its own.

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "sa-east-1"
}

resource "aws_vpc" "shop" {
  cidr_block = "10.20.0.0/16"
  tags       = { Name = "shop" }
}

resource "aws_subnet" "a" {
  vpc_id            = aws_vpc.shop.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = "sa-east-1a"
  tags              = { Name = "shop-a" }
}

resource "aws_security_group" "web" {
  name        = "web"
  description = "web servers"
  vpc_id      = aws_vpc.shop.id
  tags        = { Name = "web" }
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.web.id
  description       = "HTTPS from anywhere"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_s3_bucket" "assets" {
  bucket = "shop-assets-123456789012"
}

resource "aws_ebs_volume" "data" {
  availability_zone = "sa-east-1a"
  size              = 20
  tags              = { Name = "shop-data" }
}
```

```
ana@laptop:~/shop$ terraform apply -auto-approve | tail -n 1
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.
```

## The change a person approves

Lesson 7 ended with two ways out of drift, and the second was to let the world win: write the rule
into the configuration, *reviewed like any other change*. A colleague does exactly that and opens a
pull request with one new file:

```hcl
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.web.id
  description       = "SSH for maintenance"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = "0.0.0.0/0"
}
```

It is eight lines, the description says *maintenance*, and a reviewer on a busy afternoon approves
it. **A rule does not have a busy afternoon.** Asked about this one check, Checkov names the resource
and the file:

```
ana@laptop:~/shop$ checkov -d . --skip-download --quiet --compact --check CKV_AWS_24
terraform scan results:

Passed checks: 2, Failed checks: 1, Skipped checks: 0

Check: CKV_AWS_24: "Ensure no security groups allow ingress from 0.0.0.0:0 to port 22"
	FAILED for resource: aws_vpc_security_group_ingress_rule.ssh
	File: /ssh.tf:1-8
```

`CKV_AWS_24` is one rule out of the hundreds Checkov carries for AWS, and the next three sections
read the whole report. Because the rules are code, they behave like code: they live in a version
someone chose, they run on every change, and they give the same verdict to the senior engineer and
to the intern. That is what *policy as code* means here. The policy (no SSH from the internet) stops
being a paragraph in a wiki and becomes a check that fails.

## What it cannot see

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Inside a dashed boundary, what a configuration scan reads: the files main.tf and ssh.tf and the scanner's rules. An arrow leads to the scanner, which needs no credentials and no API, and on to a finding that names ssh.tf, lines 1 to 8. Below the boundary, three things the scan never reads: the AWS account, where a rule typed by hand lives; the state, which records what was applied; and the values given at plan time with -var-file.\"><defs><marker id=\"sv-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"330\" height=\"170\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"35.0\" y=\"46.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">what a scanner reads</text><rect x=\"40\" y=\"70\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">main.tf</text><rect x=\"40\" y=\"130\" width=\"130\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ssh.tf</text><rect x=\"195\" y=\"70\" width=\"135\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"262.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">rules</text><text x=\"262.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">CKV_AWS_24</text><text x=\"262.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">AWS-0107</text><text x=\"262.0\" y=\"151.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">…</text><path d=\"M352 115 L388 115\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sv-ah-phosphor)\"></path><rect x=\"390\" y=\"80\" width=\"130\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"455.0\" y=\"99.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">scanner</text><text x=\"455.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no credentials</text><text x=\"455.0\" y=\"131.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no API</text><path d=\"M522 115 L558 115\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sv-ah-phosphor)\"></path><rect x=\"560\" y=\"80\" width=\"140\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a finding</text><text x=\"630.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">ssh.tf:1-8</text><text x=\"20.0\" y=\"222.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">never read by a scan of the configuration</text><rect x=\"20\" y=\"236\" width=\"210\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"125.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the AWS account</text><text x=\"125.0\" y=\"270.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a rule typed by hand</text><rect x=\"255\" y=\"236\" width=\"210\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360.0\" y=\"254.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the state</text><text x=\"360.0\" y=\"270.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what was applied</text><rect x=\"490\" y=\"236\" width=\"210\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"595.0\" y=\"252.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">values given at plan time</text><text x=\"595.0\" y=\"271.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">-var-file=maintenance.tfvars</text></svg>", "caption": "A scan of the configuration reads files and rules. The account, the state and the values that arrive at plan time are outside what it reads."}
```

Take the file away and put the same rule where lesson 1 put it, typed by hand from another machine.
AWS now has port 22 open:

```
ana@laptop:~/shop$ aws ec2 describe-security-groups --filters Name=group-name,Values=web --query "SecurityGroups[0].IpPermissions[].[IpProtocol,FromPort,IpRanges[0].CidrIp]" --output text
tcp	443	0.0.0.0/0
tcp	22	0.0.0.0/0
```

and the scanner, asked the same question about the same directory, finds nothing wrong:

```
ana@laptop:~/shop$ checkov -d . --skip-download --compact --check CKV_AWS_24

       _               _
   ___| |__   ___  ___| | _______   __
  / __| '_ \ / _ \/ __| |/ / _ \ \ / /
 | (__| | | |  __/ (__|   < (_) \ V /
  \___|_| |_|\___|\___|_|\_\___/ \_/

By Prisma Cloud | version: 3.3.22 

terraform scan results:

Passed checks: 2, Failed checks: 0, Skipped checks: 0

Check: CKV_AWS_24: "Ensure no security groups allow ingress from 0.0.0.0:0 to port 22"
	PASSED for resource: aws_security_group.web
	File: /main.tf:26-31
Check: CKV_AWS_24: "Ensure no security groups allow ingress from 0.0.0.0:0 to port 22"
	PASSED for resource: aws_vpc_security_group_ingress_rule.https
	File: /main.tf:33-40
```

**Both results are correct.** Neither file mentions port 22, so every resource the scanner can read
passes. The open port exists only in the account, and the account is the one place a configuration
scan never looks. Finding that is a job for a plan, which reads the real resources back (lesson 7
did exactly that), or for a tool that audits the live account. A scanner and a plan answer different
questions, and you need both.

The same blindness reaches further than drift. A scan cannot know a value that arrives at plan time
from a `.tfvars` file or an environment variable (section 07 of this lesson closes that gap). It
cannot know whether port 22 is reachable at all, which depends on routes and subnets it may not
see. And it cannot know whether anybody needs the rule. A finding is a fact about the text. Whether
it matters is still a judgement, and section 08 is about making it.
