---
title: The flow, from a pull request to an applied plan
version: 2
---

A pipeline for Terraform has two lanes, and most of its design is deciding what happens in each.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Two lanes. On a pull request: check (fmt and validate, no credentials), scan (no credentials), plan with a read-only role, and review, where people read the diff and the plan; then merge. On main after the merge: plan saved to a file with the read-only role, the file kept as an artifact for three days, an approval in which a person reads the saved plan, and apply of exactly that file with the role that can write.\"><defs><marker id=\"fl-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"20.0\" y=\"34.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">on a pull request</text><rect x=\"20\" y=\"50\" width=\"130\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">check</text><text x=\"85.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fmt, validate</text><text x=\"85.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no credentials</text><rect x=\"180\" y=\"50\" width=\"120\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"240.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">scan</text><text x=\"240.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a scanner</text><text x=\"240.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no credentials</text><rect x=\"330\" y=\"50\" width=\"130\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"395.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">plan</text><text x=\"395.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">not saved</text><text x=\"395.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">read-only role</text><rect x=\"490\" y=\"50\" width=\"120\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"550.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">review</text><text x=\"550.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the diff</text><text x=\"550.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">and the plan</text><rect x=\"640\" y=\"50\" width=\"70\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"675.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">merge</text><path d=\"M150 82.0 L178 82.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fl-ah-phosphor)\"></path><path d=\"M300 82.0 L328 82.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fl-ah-phosphor)\"></path><path d=\"M460 82.0 L488 82.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fl-ah-phosphor)\"></path><path d=\"M610 82.0 L638 82.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fl-ah-phosphor)\"></path><path d=\"M675 114 L675 150 L85 150 L85 188\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fl-ah-phosphor)\"></path><rect x=\"20\" y=\"190\" width=\"130\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">plan, saved</text><text x=\"85.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">to a file</text><text x=\"85.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">read-only role</text><rect x=\"190\" y=\"190\" width=\"130\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"255.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">artifact</text><text x=\"255.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the file, kept</text><text x=\"255.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">for three days</text><rect x=\"360\" y=\"190\" width=\"140\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"430.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">approval</text><text x=\"430.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a person reads</text><text x=\"430.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the saved plan</text><rect x=\"540\" y=\"190\" width=\"160\" height=\"64\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">apply</text><text x=\"620.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">exactly that file</text><text x=\"620.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">role that can write</text><path d=\"M150 222.0 L188 222.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fl-ah-phosphor)\"></path><path d=\"M320 222.0 L358 222.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fl-ah-phosphor)\"></path><path d=\"M500 222.0 L538 222.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#fl-ah-phosphor)\"></path><text x=\"20.0\" y=\"280.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">on main, after the merge</text></svg>", "caption": "The pipeline in two lanes. A pull request gets a plan nobody applies; main gets a plan that is saved, read, approved and applied as it is."}
```

**On a pull request, nothing is applied.** The change is checked, scanned and planned, and the plan
is posted where the reviewers read the diff. **On `main`, after the merge, the plan is made again,
saved to a file, read by a person, and that file is applied.** The two plans are there for
different reasons, and the end of this section says what they are.

## Cheap gates first, credentials last

The steps are ordered by what they cost and by what they need:

| step | catches | needs |
| --- | --- | --- |
| `fmt -check`, `validate` | formatting, syntax, a wrong type, a reference to nothing | no cloud, no credentials |
| a scanner | an open port, an unencrypted bucket: lesson 14 | no cloud, no credentials |
| `plan` | what the change does to what exists | read access to the cloud and the state |
| `apply` | nothing: it does the thing | write access |

A failure early is a failure in seconds, before any credential has been handed to the job. The
first two steps run with `terraform init -backend=false`, which installs the providers and never
touches the state, so a pull request that cannot even format itself never reaches a plan.

Here is the scan doing its job. A pull request opens SSH on the `web` group to the whole internet,
the change that lesson 1 watched a colleague make by hand. This time it arrives as a file in a
branch, `ssh.tf`:

```hcl
resource "aws_security_group_rule" "ssh" {
  type              = "ingress"
  description       = "SSH"
  security_group_id = aws_security_group.web.id
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}
```

The pipeline runs on that branch. This run was recorded near the end of the lesson, and section 08
ends with the commands that put the same branch in your remote:

```
ana@laptop:~$ git clone -q -b ssh git/shop.git ci/pr-ssh
ana@laptop:~/ci/pr-ssh$ ./ci.sh check 2>&1 | tail -n 2
Success! The configuration is valid.

ana@laptop:~/ci/pr-ssh$ ./ci.sh scan; echo "exit $?"
+ export TF_IN_AUTOMATION=1
+ trivy config --quiet --skip-check-update --severity HIGH,CRITICAL --exit-code 1 .
```

`check` passed: the file is valid HCL. `scan` did not:

```
ssh.tf (terraform)
==================
Tests: 1 (SUCCESSES: 0, FAILURES: 1)
Failures: 1 (HIGH: 1, CRITICAL: 0)

AWS-0107 (HIGH): Security group rule allows unrestricted ingress from any IP address.
```

```
exit 1
```

**The exit code is what stops the pipeline.** `--exit-code 1` makes Trivy fail when it finds
anything at the severities listed, and every CI system treats a step that exits non-zero as a
failed job. The plan never ran, nobody got credentials, and the conversation about port 22 happens
on the pull request, before anything exists, instead of a week later in the console. How to read
the finding, and how to suppress one with a reason, is lesson 14.

## Why the pull request's plan is not the one applied

The plan on a pull request answers a question: *what would this change do if it were applied
now?* It is the best review aid there is, and it goes out of date as soon as anything else lands
on `main`. Two pull requests approved on the same morning were each planned against a state that
the other one is about to change.

So the plan that gets applied is made after the merge, from `main` as it really is, and saved with
`-out`. A person reads that one before it runs. If it says what the pull request's plan said, the
approval takes a minute. **If the two disagree, that disagreement is the news**: something else
changed in between, and somebody should know what before pressing the button.

Some tools turn this around and apply from the pull request before merging; the last section of
this lesson names them. The shape here is the one both GitHub Actions and GitLab CI can express
with nothing but their own features, and the next two sections write it for each.
