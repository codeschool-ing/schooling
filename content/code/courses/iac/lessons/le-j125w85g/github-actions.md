---
title: GitHub Actions, and the one script it calls
version: 2
---

**This workflow was not run for this lesson.** Running it needs a GitHub account, which this course
never asks for. So the file below, `.github/workflows/terraform.yml` in `~/shop`, is written as it
would be committed and checked only as far as a YAML parser can check it, in section 05. Every step
in it calls `ci.sh`, and `ci.sh` is run for real further down. If you have an account and want to
try it, GitHub's free plan runs workflows; the AWS half then needs a real account, as lesson 1
describes, and the roles of section 06.

```yaml
# Illustrative: written for lesson 15 and never run by it. Every step calls
# ci.sh, which the lesson does run.
name: terraform

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

permissions:
  contents: read

concurrency:
  group: terraform-${{ github.ref }}
  cancel-in-progress: false

jobs:
  check:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
      - uses: hashicorp/setup-terraform@dfe3c3f87815947d99a8997f908cb6525fc44e9e # v4.0.1
        with:
          terraform_version: 1.16.4
          terraform_wrapper: false
      - uses: aquasecurity/setup-trivy@81e514348e19b6112ce2a7e3ecbafe19c1e1f567 # v0.3.1
        with:
          version: v0.75.0
      - run: ./ci.sh check
      - run: ./ci.sh scan

  plan:
    needs: check
    runs-on: ubuntu-24.04
    permissions:
      contents: read
      id-token: write
      pull-requests: write
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
      - uses: hashicorp/setup-terraform@dfe3c3f87815947d99a8997f908cb6525fc44e9e # v4.0.1
        with:
          terraform_version: 1.16.4
          terraform_wrapper: false
      - uses: aws-actions/configure-aws-credentials@e1253824e5c10ff9df46874f81ed3ec929e19cfd # v6.3.0
        with:
          role-to-assume: arn:aws:iam::123456789012:role/shop-plan
          aws-region: sa-east-1
      - run: ./ci.sh plan
      - if: github.event_name == 'pull_request'
        env:
          GH_TOKEN: ${{ github.token }}
          PR: ${{ github.event.pull_request.number }}
        run: |
          { echo '~~~'; cat plan.txt; echo '~~~'; } > comment.md
          gh pr comment "$PR" --body-file comment.md
      - if: github.event_name == 'push'
        uses: actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7.0.1
        with:
          name: tfplan
          path: tfplan
          retention-days: 3

  apply:
    if: github.event_name == 'push'
    needs: plan
    runs-on: ubuntu-24.04
    environment: production
    permissions:
      contents: read
      id-token: write
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
      - uses: hashicorp/setup-terraform@dfe3c3f87815947d99a8997f908cb6525fc44e9e # v4.0.1
        with:
          terraform_version: 1.16.4
          terraform_wrapper: false
      - uses: aws-actions/configure-aws-credentials@e1253824e5c10ff9df46874f81ed3ec929e19cfd # v6.3.0
        with:
          role-to-assume: arn:aws:iam::123456789012:role/shop-apply
          aws-region: sa-east-1
      - uses: actions/download-artifact@3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c # v8.0.1
        with:
          name: tfplan
      - run: ./ci.sh apply
```

Read it from the top. It runs on a pull request against `main` and on a push to `main`, which on a
protected branch means a merge. `permissions` at the top gives every job a token that can only read
the repository; the jobs that need more ask for it themselves. Then three jobs, joined by `needs`:
`check` runs on everything, `plan` only after `check` passed, `apply` only after `plan` and only on
a push. On a pull request the plan is posted as a comment and the run ends there. On `main` the
saved file is uploaded as an artifact and `apply` waits for the `production` environment, which is
where the approval lives; the section on applying the plan comes back to it.

**Every action is pinned to a commit, with the tag it came from beside it.** A tag such as `v7` is a
name the action's owner can move to other code at any time, and that code then runs with your
credentials. A commit cannot move. The six commits in this file are what those tags pointed to on
2 October 2026, read from each repository with `git ls-remote`. The comment is what makes the pin
readable to whoever later decides it is old. `terraform_version` pins Terraform itself to the
version this course uses, and `terraform_wrapper: false` turns off a wrapper the action installs
around the binary, which this pipeline does not need.

## The steps live in a script

The workflow decides when each stage runs and with which credentials. What a stage does is written
once, in a script the repository carries, `ci.sh`:

```sh
#!/bin/sh
# The pipeline's steps, written once. The workflow files decide when each
# stage runs and with which credentials; what a stage does is written here,
# so a laptop can run exactly what a runner runs.
set -eux
export TF_IN_AUTOMATION=1

case "$1" in
check)
  terraform fmt -check -recursive
  terraform init -input=false -backend=false
  terraform validate
  ;;
scan)
  trivy config --quiet --skip-check-update \
    --severity HIGH,CRITICAL --exit-code 1 .
  ;;
plan)
  terraform init -input=false
  terraform plan -input=false -lock-timeout=5m \
    -var-file=prod.tfvars -out=tfplan
  terraform show -no-color tfplan > plan.txt
  ;;
apply)
  terraform init -input=false
  terraform apply -input=false -lock-timeout=5m tfplan
  ;;
esac
```

That split is what lets the same steps run on a laptop, in GitHub and in GitLab without three
copies drifting apart, and it is what lets this lesson show what each step prints.

Before the first run, Ana makes the script executable, initialises `~/shop` so that the lock file
exists, and makes the first commit and pushes it. Save `.gitlab-ci.yml` from section 05 first, so
the commit holds every file, then in `~/shop`:

```sh
chmod +x ci.sh
terraform init -input=false
git add -A && git commit -qm "shop: network and pipeline" && git push -q origin main
```

Here is the pipeline for that commit, in a fresh clone that stands in for the runner, made from
your home directory:

```
ana@laptop:~$ git clone -q git/shop.git ci/run-1
ana@laptop:~/ci/run-1$ git log --oneline -1
7bb05b9 shop: network and pipeline
```

```
ana@laptop:~/ci/run-1$ ./ci.sh check
+ export TF_IN_AUTOMATION=1
+ terraform fmt -check -recursive
+ terraform init -input=false -backend=false
Initializing provider plugins...
- Reusing previous version of hashicorp/aws from the dependency lock file
- Installing hashicorp/aws v6.67.0...
- Installed hashicorp/aws v6.67.0 (unauthenticated)

Terraform has been successfully initialized!
+ terraform validate
Success! The configuration is valid.
```

`set -x` prints each command with a `+` before it runs, which is what makes a CI log readable a
week later. `init -backend=false` installed the provider from the lock file and never asked for
the state. The plan stage does use the backend, and its last lines are the summary a reviewer will
read:

```
ana@laptop:~/ci/run-1$ ./ci.sh plan
+ export TF_IN_AUTOMATION=1
+ terraform init -input=false
```

```
Plan: 3 to add, 0 to change, 0 to destroy.
+ terraform show -no-color tfplan
```

```
ana@laptop:~/ci/run-1$ ls
backend.tf
ci.sh
main.tf
plan.txt
prod.tfvars
tfplan
variables.tf
ana@laptop:~/ci/run-1$ tail -n 1 plan.txt
Plan: 3 to add, 0 to change, 0 to destroy.
```

## Two settings that exist for machines

**`TF_IN_AUTOMATION`** changes only words. Terraform leaves out advice addressed to a person at a
keyboard, such as which command to type next:

```
ana@laptop:~/ci/run-1$ TF_IN_AUTOMATION= terraform plan -input=false -var-file=prod.tfvars | tail -n 6
Plan: 3 to add, 0 to change, 0 to destroy.

─────────────────────────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't
guarantee to take exactly these actions if you run "terraform apply" now.
ana@laptop:~/ci/run-1$ TF_IN_AUTOMATION=1 terraform plan -input=false -var-file=prod.tfvars | tail -n 3
    }

Plan: 3 to add, 0 to change, 0 to destroy.
```

The same is why the saved plan above ends at its summary, with no line suggesting
`terraform apply "tfplan"`: in a pipeline the next command is the workflow's business, not the
reader's.

**`-input=false`** changes behaviour, and it matters more. Without it, a missing variable is a
question, and Terraform waits for the answer. Below, `sleep` stands in for a runner whose input
nobody ever closes, and `timeout` for the job's time limit:

```
ana@laptop:~/ci/run-1$ sleep 20 | timeout -s INT 5 terraform plan; echo "exit $?"
var.environment
  Which environment this state describes.

  Enter a value: 

Interrupt received.
Please wait for Terraform to exit or data loss may occur.
Gracefully shutting down...

╷
│ Error: No value for required variable
│ 
│   on variables.tf line 1:
│    1: variable "environment" {
│ 
│ The root module input variable "environment" is not set, and has no default
│ value. Use a -var or -var-file command line argument to provide a value for
│ this variable.
╵
exit 124
ana@laptop:~/ci/run-1$ terraform plan -input=false; echo "exit $?"
╷
│ Error: No value for required variable
│ 
│   on variables.tf line 1:
│    1: variable "environment" {
│ 
│ The root module input variable "environment" is not set, and has no default
│ value. Use a -var or -var-file command line argument to provide a value for
│ this variable.
╵
exit 1
```

The first run sat at `Enter a value:` until it was interrupted; on a runner it would have held the
job, and a runner, until the limit. The second failed in the same instant with the reason in plain
words. **In a pipeline, a question nobody can answer must be an error.** `ci.sh` passes
`-input=false` to every `init`, `plan` and `apply` for that reason.
