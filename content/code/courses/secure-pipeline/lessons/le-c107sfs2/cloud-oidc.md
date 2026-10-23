---
title: The same exchange on GitHub Actions and a cloud provider
version: 1
---

Everything in the previous two sections has a counterpart on a hosted CI service, and the
counterparts are where most real configurations live. **This section is taught from GitHub's and
AWS's documentation and was not run**: it needs a GitHub repository with Actions and a cloud
account, and the course gives you neither. What you built on your own machine is the same exchange
with every part visible, and the table at the end maps one onto the other.

### The workflow asks for a token

A GitHub Actions job gets an identity token only if its workflow grants the permission to request
one. The documented shape, for a job that deploys to AWS:

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write
    steps:
      - uses: aws-actions/configure-aws-credentials@e1253824e5c10ff9df46874f81ed3ec929e19cfd # v6.3.0
        with:
          role-to-assume: arn:aws:iam::111122223333:role/linkbox-deploy
          aws-region: sa-east-1
```

`id-token: write` reads like write access to something, and it is not: it allows the job to ask
GitHub's token service for a JWT about itself. Without it the request fails, which is why lesson 16's
`permissions: contents: read` at the top of a workflow already keeps every job that does not need a
token from getting one. The action requests the token, sends it to AWS, and puts the temporary
credentials AWS returns into the job's environment. The account number is AWS's documentation
example, and the action is pinned by commit as lesson 16 requires. The commit was checked the way
lesson 16 checks one:

@@CAPTURE pin@@

### The cloud provider decides which runs

On AWS the role's **trust policy** plays the part of Vault's role. GitHub's token service is
registered once in the account as an identity provider, and each role says which tokens from it may
become that role:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::111122223333:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:ana/linkbox:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

Read it against `linkbox-main.json`. The `Federated` principal is `bound_issuer` and the public key
together: whose signature to believe. The `aud` condition is `bound_audiences`. The `sub` condition
is `bound_claims`, written as one string because that is the claim AWS conditions most often use.
Google Cloud's workload identity federation puts the same check in an `attribute_condition`, and
Azure in the subject of a federated credential; the names change and the decision does not.

**The `sub` condition is the line that matters, and it is the one that gets left out.** GitHub's
issuer signs tokens for every repository on GitHub, so a role that checks only the audience trusts
every one of them: any workflow, in anybody's repository, that asks for a token with that audience.
That is the `linkbox-any` role from two sections ago, with the whole of GitHub where your CI server's
branches were.

### Subjects, and the mistakes made with them

GitHub's documentation lists the forms `sub` takes, and the form depends on what triggered the job:

| the job | its `sub` |
|---|---|
| a push to `main` | `repo:ana/linkbox:ref:refs/heads/main` |
| a tag | `repo:ana/linkbox:ref:refs/tags/v1.4.0` |
| a pull request | `repo:ana/linkbox:pull_request` |
| a job that names an environment | `repo:ana/linkbox:environment:production` |

Three mistakes come straight out of that table.

**A wildcard where an exact value belongs.** `StringLike` with `repo:ana/*` trusts every repository
of the owner, including the one somebody creates next year for an experiment. `repo:ana/linkbox:*`
trusts every branch and every pull request of linkbox, which is the broad role again.

**Trusting pull requests for anything that deploys.** Every pull request gets the same subject,
whoever opened it and whatever it changes, so a condition on `pull_request` cannot tell your
colleague's change from a stranger's. Lesson 16 showed what a workflow triggered by pull requests can
be made to run.

**Forgetting that an environment replaces the branch.** A job that names `environment: production`
gets the environment subject and no `ref` in it, so a condition on `refs/heads/main` stops matching
the day somebody adds the environment. Bind deploy roles to the environment, and use the
environment's own protection rules on GitHub to decide which branches may use it.

The token also carries `repository_id` and `repository_owner_id`, numbers that stay the same when a
repository is renamed. A condition on a name can be satisfied by whoever owns that name later; a
condition on the number cannot.

### What still has to be guarded

Federation removes the stored credential. It does not remove trust, it moves it to **the issuer's
signing key**. On your machine that is `~/ci/oidc/ci-oidc.key`, and a copy of it would mint tokens
for any branch. On GitHub it is a key GitHub holds and publishes the public half of at
`https://token.actions.githubusercontent.com/.well-known/jwks`, which is why a verifier is configured
with the issuer's address rather than a pasted key. Vault does the same with `oidc_discovery_url`
in place of `jwt_validation_pubkeys`: it fetches the keys, notices when they change, and follows a
rotation without anybody editing its configuration. A pasted key, as in this lesson, has to be
replaced by hand everywhere it was pasted.

### The two side by side

| on your machine | on GitHub Actions and AWS |
|---|---|
| `~/ci/oidc/ci-oidc.key` and `mint.py` | GitHub's token service and its signing key |
| `ci-oidc.pub` pasted into `auth/jwt/config` | the published key set, fetched by the cloud provider |
| the hook calling `mint.py` for each run | `permissions: id-token: write` and a request from the job |
| role `linkbox-main` with `bound_claims` | the role's trust policy with a `sub` condition |
| policy `linkbox-sign` | the role's permissions policy |
| a Vault token for 5 minutes | temporary credentials, an hour by default |
| `ci/vault-read.sh` | the `configure-aws-credentials` action |

When you are done, remove the Vault container. It took its secrets with it, as dev mode promised:

@@CAPTURE cleanup@@
