---
title: Environments that expire
version: 1
---

A preview environment is a copy of the application built for one pull request, so a reviewer can
click through the change instead of imagining it. The pipeline from lesson 15 creates it when the pull
request opens and destroys it when it merges. **What goes wrong is the destroy
that never ran**: the job failed on a Friday, the pull request was closed instead of merged,
the branch was renamed. The environment keeps running, and from then on it is an orphan with good
tags.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two timelines. pr-21's environment is created when its pull request opens and destroyed when it merges. pr-17's is created the same way, its destroy never runs, and it keeps running and being billed past the merge and past its Expires date, until expired.sh lists it.\"><defs><marker id=\"eph-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"120.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">pull request opens</text><text x=\"300.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">merged</text><path d=\"M120 52 L120 70\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M300 52 L300 70\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"40.0\" y=\"90.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pr-21</text><rect x=\"120\" y=\"78\" width=\"180\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"210.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">running</text><text x=\"312.0\" y=\"90.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">destroyed on merge</text><text x=\"40.0\" y=\"180.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">pr-17</text><rect x=\"120\" y=\"168\" width=\"180\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"210.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">running</text><rect x=\"300\" y=\"168\" width=\"380\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"490.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">destroy never ran: still billed by the hour</text><path d=\"M400 146 L400 164\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"400.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">Expires</text><text x=\"640.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">sh expired.sh</text><path d=\"M640 205 L640 196\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#eph-ah-amber)\"></path></svg>", "caption": "A preview environment costs a few days when its destroy runs, and every hour after that when it does not."}
```

## An expiry date on everything

The defence is to make every preview environment say when it may be removed, on every resource, in
the one place a search can read without the state: a tag. Ana's preview configuration is a workspace
per pull request, the arrangement lesson 11 describes, with the expiry passed in by the pipeline:

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

variable "expires" {
  description = "The day after which this environment may be destroyed, YYYY-MM-DD. Set by the pipeline."
  type        = string
}

provider "aws" {
  region = "sa-east-1"

  default_tags {
    tags = {
      Owner       = "ana"
      Project     = "shop"
      Environment = terraform.workspace # pr-17, pr-21, …
      CostCenter  = "cc-4410"
      Expires     = var.expires
    }
  }
}

resource "aws_instance" "web" {
  ami           = "ami-1e749f67"
  instance_type = "t3.medium"

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }
}

resource "aws_eip" "web" {
  domain   = "vpc"
  instance = aws_instance.web.id
}
```

`Environment` is the workspace's name, and `Expires` is a variable. **The pipeline computes the date
and passes it in.** Computing it in the configuration with `timestamp()` looks tidier and fails,
because that function returns a new value on every run. Every later plan would want to change every
tag, and the date would move forward each time anybody touched the environment. Pull request 21 gets
its workspace and a week:

```
ana@laptop:~/shop-preview$ terraform workspace new pr-21
Created and switched to workspace "pr-21"!

You're now on a new, empty workspace. Workspaces isolate their state,
so if you run "terraform plan" Terraform will not see any existing state
for this configuration.
```

```
ana@laptop:~/shop-preview$ terraform plan -no-color -var "expires=$(date -d +7days +%F)" -out tfplan | grep -E "will be created|Expires|Plan:"
  # aws_eip.web will be created
          + "Expires"     = "2026-10-09"
  # aws_instance.web will be created
          + "Expires"     = "2026-10-09"
Plan: 2 to add, 0 to change, 0 to destroy.
```

And the price of one environment, with `price.py` from earlier in this lesson:

```
ana@laptop:~/shop-preview$ terraform show -json tfplan | python3 price.py
aws_eip.web            create       0.00 ->     3.65
aws_instance.web       create       0.00 ->    52.10
change per month, USD                       +55.75
```

**55.75 USD a month for one machine and its address**, cheap enough that nobody worries about one.
Forgetting them is what adds up: ten preview environments left
running for a quarter is 10 × 3 × 55.75, or 1,672.50 USD, for review copies of pull requests that
merged months before.

## Finding the ones that outlived their date

Pull request 17's environment was created ten days ago, and its date has passed. The search for it
uses the tagging API, which works here because these resources have tags; it lists everything whose
`Expires` is before today:

```sh
#!/bin/sh
# Every resource whose Expires tag is a day before today.
aws resourcegroupstaggingapi get-resources --tag-filters Key=Expires --output json |
  jq -r --arg today "$(date +%F)" '
    .ResourceTagMappingList[]
    | (.Tags | from_entries) as $t
    | select($t.Expires < $today)
    | [$t.Environment, $t.Expires, (.ResourceARN | split(":")[5])]
    | @tsv'
```

```
ana@laptop:~/shop-preview$ sh expired.sh
pr-17	2026-09-29	instance/i-b7dea59a329376031
pr-17	2026-09-29	volume/vol-8f1ade36dd8709d4b
```

Two of pr-17's resources: the instance, and its disk, which was tagged because the defaults existed
when it was created. The address pr-17 also holds is missing, and that is the lab: moto's tagging API
does not return Elastic IP addresses, so in this lab `describe-addresses` is where they are found.

The state for pr-17 still exists, so the right tool is Terraform. The variable is passed because the
configuration declares it without a default; its value plays no part in what is destroyed:

```
ana@laptop:~/shop-preview$ terraform workspace select pr-17
Switched to workspace "pr-17".
ana@laptop:~/shop-preview$ terraform destroy -auto-approve -var expires=$(date +%F) | tail -1
Destroy complete! Resources: 2 destroyed.
```

Then the check, run again:

```
ana@laptop:~/shop-preview$ sh expired.sh
pr-17	2026-09-29	instance/i-b7dea59a329376031
ana@laptop:~/shop-preview$ aws ec2 describe-instances --filters Name=tag:Environment,Values=pr-17 --query "Reservations[].Instances[].State.Name" --output text
terminated
```

**The instance is still listed, and it is terminated.** A terminated instance stays visible for a
while after it ends, in AWS as in moto, and the tagging API does not say what state anything is in.
A list like this is a lead, not a verdict: it names what to look at, and the service that owns each
resource says whether it is still costing anything.
