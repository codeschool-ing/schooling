---
title: Credentials without a key in the repository
version: 1
---

The obvious way to let a pipeline into AWS is the wrong one: create an IAM user, generate an access
key, and paste it into the repository's secrets as `AWS_ACCESS_KEY_ID` and
`AWS_SECRET_ACCESS_KEY`. It works on the first try. **The key then lives until somebody rotates it,
works from any computer in the world, and is readable by every workflow that can name the
secret.** One step that prints its environment into a log, or one dependency that sends it
somewhere, and the key is somebody else's for as long as nobody notices.

## Proving who you are, for each job

OpenID Connect federation removes the stored key altogether. The CI service already knows exactly
which repository, branch and environment a job belongs to, and it can say so in a token it signs.
AWS is told once to trust that signer, and each role says which tokens may become it:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A sequence between three parties: the job on the runner, GitHub's token issuer, and AWS STS. One: the job asks GitHub for a token. Two: GitHub signs one whose subject names the repository and the environment. Three: the job sends it to STS and asks to become the role shop-apply. Four: STS checks the signature against the registered provider and the audience and subject against the role's trust policy. Five: STS returns credentials that expire within the hour.\"><defs><marker id=\"oi-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"15\" y=\"20\" width=\"190\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the job, on the runner</text><path d=\"M110 56 L110 285\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"265\" y=\"20\" width=\"190\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">GitHub's token issuer</text><path d=\"M360 56 L360 285\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"515\" y=\"20\" width=\"190\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">AWS STS</text><path d=\"M610 56 L610 285\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M110 85 L358 85\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#oi-ah-phosphor)\"></path><text x=\"235.0\" y=\"75.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1  a token, please</text><path d=\"M360 125 L112 125\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#oi-ah-phosphor)\"></path><text x=\"235.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2  a signed token</text><text x=\"235.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--phosphor)\">sub: repo:example/shop:environment:production</text><path d=\"M110 170 L608 170\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#oi-ah-phosphor)\"></path><text x=\"360.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3  this token, for the role shop-apply</text><text x=\"600.0\" y=\"200.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">4  signature, aud and sub</text><text x=\"600.0\" y=\"216.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">checked against the trust policy</text><path d=\"M610 255 L112 255\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#oi-ah-phosphor)\"></path><text x=\"360.0\" y=\"245.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5  temporary credentials, one hour at most</text></svg>", "caption": "No key is stored anywhere: each job proves who it is with a token GitHub signs for that run, and leaves with credentials that expire within the hour."}
```

Nothing secret is stored anywhere. The token is minted for one job, the credentials it buys expire
within the hour, and a copy leaked from a log is worth little the next morning. In the GitHub
workflow, `id-token: write` is the permission that lets a job ask for the token, and
`configure-aws-credentials` does steps 1, 3 and 5. In GitLab, `id_tokens` puts the token in a
variable; `before_script` writes it to a file, and the AWS SDK inside the provider sees
`AWS_ROLE_ARN` and `AWS_WEB_IDENTITY_TOKEN_FILE` and does the exchange itself.

## Two roles, and what each may do

The AWS side is Terraform too, in a configuration of its own that an administrator applies once.
It cannot be applied by the pipeline it creates the roles for:

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

locals {
  repo   = "repo:example/shop"
  bucket = "arn:aws:s3:::shop-tfstate-123456789012"
}

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

# Who may become each role: a job of this repository, and for apply
# only a job running in the production environment.
data "aws_iam_policy_document" "trust" {
  for_each = {
    plan  = ["${local.repo}:pull_request", "${local.repo}:ref:refs/heads/main"]
    apply = ["${local.repo}:environment:production"]
  }

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = each.value
    }
  }
}

resource "aws_iam_role" "ci" {
  for_each             = data.aws_iam_policy_document.trust
  name                 = "shop-${each.key}"
  assume_role_policy   = each.value.json
  max_session_duration = 3600
}

# plan reads the network and the state, and writes only the lock file
resource "aws_iam_role_policy" "plan" {
  name = "plan"
  role = aws_iam_role.ci["plan"].name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["ec2:Describe*"], Resource = "*" },
      { Effect = "Allow", Action = ["s3:ListBucket"], Resource = local.bucket },
      { Effect = "Allow", Action = ["s3:GetObject"], Resource = "${local.bucket}/shop/*" },
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:DeleteObject"]
        Resource = "${local.bucket}/shop/terraform.tfstate.tflock"
      },
    ]
  })
}

# apply changes the network and writes the state
resource "aws_iam_role_policy" "apply" {
  name = "apply"
  role = aws_iam_role.ci["apply"].name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["ec2:*"], Resource = "*" },
      { Effect = "Allow", Action = ["s3:ListBucket"], Resource = local.bucket },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "${local.bucket}/shop/*"
      },
    ]
  })
}
```

```
ana@laptop:~/ci-roles$ terraform apply -auto-approve | tail -n 1
Apply complete! Resources: 5 added, 0 changed, 0 destroyed.
```

The important lines are the conditions on `sub`, the claim that says which job the token was
minted for. Here is the apply role's trust policy as AWS stores it:

```
ana@laptop:~/ci-roles$ aws iam get-role --role-name shop-apply --query Role.AssumeRolePolicyDocument
{
    "Statement": [
        {
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
                    "token.actions.githubusercontent.com:sub": "repo:example/shop:environment:production"
                }
            },
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
            }
        }
    ],
    "Version": "2012-10-17"
}
ana@laptop:~/ci-roles$ aws iam list-role-policies --role-name shop-plan --output text
POLICYNAMES	plan
```

**The apply role trusts only a job running in the `production` environment**, and a job only gets
into that environment once a reviewer approves it. So the approval and the right to write are the
same gate: an unapproved run cannot obtain credentials that change anything, whatever its YAML
says. The plan role trusts pull requests and pushes to `main`, and may only read: the network, the
state, and one write that surprises people, the `.tflock` object that lesson 7's `use_lockfile`
puts beside the state. A plan locks the state too, so a "read-only" plan role that cannot write
that one key cannot plan.

Read-only matters for a reason beyond tidiness. **A plan runs code from the pull request.**
Providers execute during a plan, and a data source such as `external` runs whatever program it
names, so whoever can open
a pull request can make `plan` do things with the plan role's credentials. That is why those
credentials should be able to read and nothing more, and why GitHub does not give the secrets of a
repository to a pull request coming from a fork.

On AWS itself, `ReadOnlyAccess` is the usual shortcut for the plan role. The lab's moto does not
load AWS's managed policies, so the reads are written out here, and they are narrower anyway:
`ec2:Describe*` and the state, which is all this configuration plans against.

Two limits of the lab, said plainly. Moto stores the trust policy and **does not evaluate it**: it
would hand credentials to any token at all, so this lesson can show the policy AWS keeps, not AWS
refusing a job from the wrong branch. And the provider shown trusts GitHub; for GitLab the same
configuration registers `https://gitlab.com` as the issuer and matches a `sub` such as
`project_path:example/shop:ref_type:branch:ref:main`.
