---
title: GitLab CI, and the plan as an artifact
version: 1
---

The same pipeline in GitLab is shorter, because GitLab says more of it with keywords. Like the
GitHub workflow, **this file was written for the lesson and never run**: there is no GitLab here
either.

```yaml
# Illustrative: written for lesson 15 and never run by it. Every job calls
# ci.sh, which the lesson does run.
stages: [check, plan, apply]

default:
  image:
    name: hashicorp/terraform:1.16.4
    entrypoint: [""]

.aws:
  id_tokens:
    AWS_WEB_IDENTITY_TOKEN:
      aud: sts.amazonaws.com
  before_script:
    - echo "$AWS_WEB_IDENTITY_TOKEN" > "$CI_BUILDS_DIR/web-identity-token"
    - export AWS_WEB_IDENTITY_TOKEN_FILE="$CI_BUILDS_DIR/web-identity-token"
    - export AWS_REGION=sa-east-1

check:
  stage: check
  script:
    - ./ci.sh check

scan:
  stage: check
  image:
    name: aquasec/trivy:0.75.0
    entrypoint: [""]
  script:
    - ./ci.sh scan

plan:
  stage: plan
  extends: .aws
  variables:
    AWS_ROLE_ARN: arn:aws:iam::123456789012:role/shop-plan
  script:
    - ./ci.sh plan
  artifacts:
    paths: [tfplan, plan.txt]
    expire_in: 3 days

apply:
  stage: apply
  extends: .aws
  variables:
    AWS_ROLE_ARN: arn:aws:iam::123456789012:role/shop-apply
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
      when: manual
  environment: production
  resource_group: production
  needs: [plan]
  script:
    - ./ci.sh apply
```

What the lab can say about the two files is that they parse, and that each has the jobs it was
meant to have:

```
ana@laptop:~/shop$ python3 -c 'import yaml; print(list(yaml.safe_load(open(".github/workflows/terraform.yml"))["jobs"]))'
['check', 'plan', 'apply']
ana@laptop:~/shop$ python3 -c 'import yaml; print([k for k, v in yaml.safe_load(open(".gitlab-ci.yml")).items() if "script" in v])'
['check', 'scan', 'plan', 'apply']
```

That is a long way from proving they work. A YAML parser cannot tell a keyword GitLab knows from
one it would ignore, and only a real run would show the token exchange or the artifact arriving.
Read both files as a precise description of the design, not as something tested.

## What the keywords do

`stages` gives the order; jobs in the same stage run in parallel, so `check` and `scan` run side by
side and `plan` waits for both. `default: image` runs every job in the `hashicorp/terraform` image
at the same version the lab uses. Its `entrypoint` is set to nothing because that image starts
`terraform` itself, and GitLab needs a shell to run `script` lines in. `scan` uses the Trivy image
instead, which is how a job gets a tool the default image lacks.

**`artifacts` is how the plan travels.** When `plan` finishes, GitLab keeps `tfplan` and
`plan.txt`, and a later job that `needs` it receives both files in its working directory before
its script starts.

The artifact is not just a plan. Lesson 9 opened a saved plan and found a copy of the state inside
it, so **anyone who may download this pipeline's artifacts may read whatever the state holds**, and
lesson 12 is about what that can include. That is also why `expire_in: 3 days` is a decision rather
than housekeeping: a plan that waited longer than that for approval is one somebody should make
again rather than apply, and a file you no longer keep is one nobody can download.

`apply` carries the rest. Its `rules` add it only to pipelines on the default branch, and
`when: manual` makes it a button: the pipeline stops after `plan` until somebody presses it, having
read `plan.txt` or the job's log. `environment: production` is what lets GitLab restrict who may
press it. `resource_group` and `id_tokens` belong to the last two subjects of this lesson, one
apply at a time and credentials, and are explained there.

## The same design in two dialects

| | GitHub Actions | GitLab CI |
| --- | --- | --- |
| order of jobs | `needs` | `stages`, and `needs` |
| the plan's file between jobs | `upload-artifact`, `download-artifact` | `artifacts: paths`, received through `needs` |
| how long it is kept | `retention-days` | `expire_in` |
| the approval | `environment` with required reviewers | `when: manual` on a protected environment |
| one apply at a time | `concurrency` | `resource_group` |
| credentials without keys | `id-token: write` and an action | `id_tokens` and two environment variables |

**What did not change is `ci.sh`.** Both files call the same four stages, so the steps, their flags
and their order are written once, and moving from one CI service to the other is a change to the
file that schedules them, not to what they do.
