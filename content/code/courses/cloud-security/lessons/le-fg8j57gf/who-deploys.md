---
title: Who holds the keys at the end of the road
version: 1
---

**The identity that applies is the most powerful thing in a deployment flow. It should be a role the pipeline assumes for minutes at a time: never a key stored in the pipeline's settings, and never
the same role for every stage.** Lesson 12 showed how a stored key outlives every attempt to remove
it. A pipeline holding the account's administrator key is that leak waiting for a reason.

## A token, not a key

Lesson 4 traded a token from Google Cloud for temporary AWS credentials, so that a job in another
cloud never held a key. A pipeline is the same kind of workload. GitHub Actions, for instance, signs an
identity token for every job, saying which repository, branch or environment the job runs for, and AWS
can trust that signature through an **OIDC provider**: an entry in IAM naming the issuer.

The clinic splits the work between **two roles**, because the stages need different powers:

- **`infra-plan`** reads the account, for the plan that every pull request runs. Any pull request in
  the repository may assume it.
- **`infra-apply`** writes. Only a job running for the protected `production` environment may assume
  it, and GitHub only starts such a job after a named reviewer approves.

Start moto empty. The trust policy of each role names the issuer and pins the token's claims. Save
the first as `trust-plan.json`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Federated": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com" },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:clinic/infra:pull_request"
        }
      }
    }
  ]
}
```

And the second as `trust-apply.json`, identical except for the claim that names who may assume it:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Federated": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com" },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:clinic/infra:environment:production"
        }
      }
    }
  ]
}
```

```
ana@laptop:~/aws$ aws iam create-open-id-connect-provider --url https://token.actions.githubusercontent.com --client-id-list sts.amazonaws.com --query OpenIDConnectProviderArn --output text
arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com
ana@laptop:~/aws$ aws iam create-role --role-name infra-plan --assume-role-policy-document file://trust-plan.json --query Role.Arn --output text
arn:aws:iam::123456789012:role/infra-plan
ana@laptop:~/aws$ aws iam attach-role-policy --role-name infra-plan --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess
ana@laptop:~/aws$ aws iam create-role --role-name infra-apply --assume-role-policy-document file://trust-apply.json --query Role.Arn --output text
arn:aws:iam::123456789012:role/infra-apply
ana@laptop:~/aws$ aws iam list-roles --query "Roles[?starts_with(RoleName, 'infra-')].[RoleName,AssumeRolePolicyDocument.Statement[0].Condition.StringEquals.\"token.actions.githubusercontent.com:sub\"]" --output text
infra-plan	repo:clinic/infra:pull_request
infra-apply	repo:clinic/infra:environment:production
```

**The `sub` condition carries the whole design.** Without it, any repository on GitHub could present a
token signed by the same issuer and assume the role, since GitHub signs every job's token with the same
keys. With it, `infra-plan` answers only pull requests in `clinic/infra`, and `infra-apply` only the
job GitHub runs after the `production` environment's reviewers approve. The permissions the apply role
needs are those of the resources it manages, and choosing them is lesson 6's subject; it is left
without a policy here.

**moto stores these conditions and judges none of them**, as lesson 4 showed: it would hand either
role to any token. What AWS does with the claims comes from its documentation for GitHub's provider.

## The workflow's side

On GitHub's side, a job asks for its token by declaring the `id-token: write` permission and gives the
role's name to AWS's own action, which performs the exchange. The apply job of such a workflow looks
like this; it was **not run**, because the lab has no GitHub runner and no AWS to exchange tokens with:

```yaml
apply:
  runs-on: ubuntu-24.04
  environment: production
  permissions:
    id-token: write
    contents: read
  steps:
    - uses: actions/checkout@v4
    - uses: aws-actions/configure-aws-credentials@v4
      with:
        role-to-assume: arn:aws:iam::123456789012:role/infra-apply
        aws-region: sa-east-1
    - run: terraform init -input=false && terraform apply -input=false plan.bin
```

Three lines carry the security. `environment: production` is what makes GitHub wait for the reviewers,
and what puts `environment:production` in the token's `sub`. `id-token: write` lets this job, and only
this job, ask for a token. And the actions are written here with a version tag for legibility; a real
workflow pins each one to the full commit hash, because a tag can be moved to point at different code.
How the saved `plan.bin` travels from the plan job to this one is the pipeline's business; what matters
is that the apply uses it.

## Taking the road away from people

Two roles are half of it. The other half is that **the people's own roles lose write access** to what
the pipeline manages: ana, caio and bia keep read access, and a break-glass role exists for the day the
pipeline itself is broken, used rarely, by name, and recorded every time. Until that is true, the gate
of the previous sections is advice, and lesson 1's one request is still one request away.
