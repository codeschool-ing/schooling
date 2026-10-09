---
title: Applying exactly the plan that was read
version: 2
---

The approval in this pipeline is a person reading a saved plan and saying yes to it. **What makes
that approval mean something is that the apply job runs that file and nothing else.** A job that
ran `terraform apply -auto-approve` on `main` would plan again at that moment and carry out the new
plan, which nobody read; the approval would be a review of one thing and permission for another.

In GitHub the waiting happens in the `production` environment: with required reviewers set on it,
the `apply` job pauses before its first step, and the run shows a button only those people can
press. In GitLab it is the manual `apply` job. Either way, the reviewer reads the plan job's log or
`plan.txt`, and then lets the next job start.

## The file travels; the checkout is fresh

Run 1's plan was saved earlier, in its own clone. While it waited for its approval, a pull request
adding an `Owner` tag to the VPC was merged. To merge the same change into your remote, in `~/shop`:

```sh
sed -i 's/{ Name = "shop", Environment = var.environment }/{ Name = "shop", Environment = var.environment, Owner = "ana" }/' main.tf
terraform fmt
git commit -qam "shop: Owner tag on the VPC" && git push -q origin main
```

Run 2, the pipeline for that commit, also planned before run 1 was approved, and the next section
opens with its plan. To see the same plan, type that section's first three commands now: the clone
from your home directory, the other two in `~/ci/run-2`. Then come back here.

Run 1's apply job starts in a new clone, receives `tfplan`, and applies it. Notice which commit this
clone holds:

```
ana@laptop:~$ git clone -q git/shop.git ci/run-1-apply
ana@laptop:~/ci/run-1-apply$ git log --oneline -1
53a4007 shop: Owner tag on the VPC
ana@laptop:~/ci/run-1-apply$ cp ../run-1/tfplan .
ana@laptop:~/ci/run-1-apply$ ./ci.sh apply
```

The `Owner` tag was merged while run 1 waited, so a clone of `main` now holds that later commit. The
apply goes ahead:

```
+ terraform apply -input=false -lock-timeout=5m tfplan
aws_vpc.shop: Creating...
aws_vpc.shop: Creation complete after 2s [id=vpc-d23fdf50099101ff0]
aws_subnet.a: Creating...
aws_security_group.web: Creating...
aws_subnet.a: Creation complete after 0s [id=subnet-c59b983a250cafb96]
aws_security_group.web: Creation complete after 0s [id=sg-4b1e1bc89d446a519]

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

And the VPC it created has no `Owner` tag, although the `main.tf` beside the plan file asks for
one:

```
ana@laptop:~/ci/run-1-apply$ aws ec2 describe-vpcs --filters Name=tag:Name,Values=shop --query "Vpcs[].Tags[].Key" --output text
Name	Environment
ana@laptop:~/ci/run-1-apply$ grep -c Owner main.tf
1
```

**A saved plan carries the configuration it was computed from**, as lesson 9 found inside the
file, and `apply` follows the plan, not the `.tf` files around it. Here that is exactly right: the
reviewer approved a plan without the tag, and that is what happened. The tag belongs to run 2, and
it goes through its own plan and its own approval.

The checkout is not irrelevant, though. `terraform init` in the apply job reads the backend block
and the dependency lock file from it, and Terraform refuses a saved plan whose provider selections
differ from the lock file it finds. That is why the GitHub workflow leaves `actions/checkout` at its
default, the commit that triggered the run: every job of one run then sees the same files. This
lesson's clone was taken from `main` as it was at that moment, which is the mistake a workflow makes
when it checks out a branch name instead of the run's own commit. It did no harm this time because only a
tag differed.

## When the plan cannot be applied any more

Two things retire a saved plan, and both are features:

| what happened | what Terraform or the CI service does | what to do |
| --- | --- | --- |
| the state changed since the plan was made | `Error: Saved plan is stale`, lesson 9 | plan again, read again |
| the artifact expired, after `retention-days` or `expire_in` | there is no file to download | run the plan job again |

Neither is a failure of the pipeline. **A plan is a statement about the world at one moment**, and
both rules stop it being applied after that moment has passed. What the pipeline must never do on
meeting either is fall back to applying without a plan file. The next section shows the first rule
firing in the pipeline itself, and why it fired.
