---
title: Why the laptop stops applying
version: 1
---

The common belief is that a pipeline for Terraform is something a large team needs, and that for
two people `terraform apply` on a laptop is fine as long as the code is in git. Every lesson in this
course so far has applied from Ana's laptop, so it is worth saying what that arrangement hides
before replacing it.

Here is her laptop on an ordinary afternoon. She is trying out a different range for the subnet and
has not committed anything:

```
ana@laptop:~/shop$ git status --short
 M main.tf
ana@laptop:~/shop$ git diff --stat
 main.tf | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
ana@laptop:~/shop$ terraform plan -var-file=prod.tfvars | grep -E "# aws|forces replacement|Plan:"
  # aws_subnet.a must be replaced
      ~ cidr_block                                     = "10.20.1.0/24" -> "10.20.3.0/24" # forces replacement
Plan: 1 to add, 0 to change, 1 to destroy.
```

**Terraform plans the directory, not the commit.** It reads whatever `.tf` files are on disk and has
no idea what git thinks of them. Had Ana typed `terraform apply` here, the subnet would have been
destroyed and created again from a change that exists in no commit, on no branch, reviewed by
nobody. The next person to plan from `main` would see a plan to put the old range back, and would
have to work out why.

The same capture makes the second point. The diff is one line. The plan says one subnet is
destroyed and another created, with `# forces replacement` beside the line responsible, which lesson
6 explained. **The diff says what somebody meant; the plan says what will happen**, and a reviewer
who reads only the first is approving the second blind. On a laptop the plan scrolls past in one
terminal and is gone.

A laptop hides three more things:

| on a laptop | in a pipeline |
| --- | --- |
| whichever Terraform version is installed there | one version, written in the workflow |
| credentials that can change production, on every laptop that applies | write credentials in one place, for one job |
| no record of what was applied, from which commit, by whom | a log per run, tied to a commit and an approval |

So the arrangement this lesson builds is simple to state: **one place applies, and it applies only
what was merged and reviewed**. People still write the change and still decide whether it is wise;
the pipeline does the mechanical part the same way every time, and keeps the plan where a reviewer
can read it.

## How this lesson runs a pipeline with no CI service

The lab has no GitHub and no GitLab, and nothing here can reach them. So the workflow files in this
lesson are **illustrative**: written in full, checked to parse as YAML, and never run. What they
call is a shell script, `ci.sh`, and that script is run for real, each time in a fresh clone under
`~/ci/` standing in for a runner. A bare repository, `~/git/shop.git`, stands in for the remote,
and copying `tfplan` from one clone to the next stands in for the artifact a job uploads and the
next one downloads. The AWS is moto, as in every lesson, and the state lives in the S3 bucket
lesson 7 created.
