---
title: Least privilege for the pipeline itself
version: 1
---

**Least privilege** is the rule that every credential can do exactly what its holder's job needs and
nothing more. Applied to secrets it limits the damage of a leak: a token that can only read prices
leaks prices. Applied to a pipeline it means every job gets the smallest set of permissions it can
work with.

GitHub Actions gives every run an automatic token, `GITHUB_TOKEN`, which can act on the repository
that started it. What it may do is set by `permissions:` in the workflow. This repository's CI
workflow sets it once, at the top, for every job:

```yaml
permissions:
  contents: read
```

Read the code, and nothing else. A test job that is compromised, by a malicious dependency say, can
read what anybody can already read and cannot push a commit, open a release or change a setting.
`shipquote`'s workflow from lesson 6 declares the same.

## Raising permissions per job, only where needed

The release workflow starts from the same `contents: read` and raises it in two jobs, each with a
comment saying why. The job that creates the release:

```yaml
    permissions:
      contents: write # creating the release
```

and the job that deploys:

```yaml
    permissions:
      contents: read
      # The OIDC token the exchange is built on. It is the only reason this job
      # has any permission beyond reading the code.
      id-token: write
```

`contents: write` is needed to create a release and only `Publish` has it. `id-token: write` is
needed to ask GitHub for the token section 09 is about, and the comment beside it says it is the only
permission the deploy job has beyond reading the code. **A permission granted to one job is not
granted to the workflow**, so a test job running next to the deploy cannot borrow either.

## The same idea outside GitHub

| credential | least-privilege version |
|---|---|
| a cloud account for deploys | a role that can update one service, not one that administers the project |
| a database user for the app | rights on the app's tables, not the owner of the database |
| a carrier token | quoting only, if the provider offers scopes; a separate token for shipments |
| a runner | a fresh machine per job, with no credentials of its own left behind |

Least privilege costs some setup and some friction: a job will fail one day because it lacks a
permission it really needs, and somebody will have to add it, with a comment. That failure is the
system working. The alternative, a token that can do everything, fails silently on the day it leaks.
