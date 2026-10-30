---
title: The subject, which is the whole of the security
version: 1
---

**The subject decides who may deploy, and Entra ID compares it as an exact string.** There are no
wildcards in a federated credential's subject: it matches character for character or it does not
match. GitHub builds the subject from the run, in one of a few shapes, and which shape it uses depends
on the workflow:

| the job | the subject GitHub puts in the token |
|---|---|
| names `environment: production` | `repo:example-shop/shop-api:environment:production` |
| no environment, pushed to `main` | `repo:example-shop/shop-api:ref:refs/heads/main` |
| no environment, a tag `v1.4.0` | `repo:example-shop/shop-api:ref:refs/tags/v1.4.0` |
| triggered by a pull request | `repo:example-shop/shop-api:pull_request` |

The table is GitHub's documented default, **not a capture**: the token only exists inside a run on
GitHub's runners. An organisation can customise the claims that go into the subject; the shop uses
the default.

## Choosing one

**Bind production to an environment, not to a branch.** A credential for
`ref:refs/heads/main` trusts every job of every workflow on `main`, including one somebody adds next
week to run a linter. A credential for `environment:production` trusts only jobs that name that
environment, and a GitHub environment can carry its own protections: required reviewers, a wait
timer, and a rule that only `main` may deploy to it. The two locks then hold each other: Entra ID
trusts only the environment, and GitHub lets only reviewed runs on `main` into it.

**Never trust `pull_request` with anything that can write.** A pull request's workflow runs code
from the pull request, which on a public repository is code from anybody. A credential with that
subject is a door for every fork. If pull requests need Azure at all, give them a separate identity
with a reader role on a separate resource group.

**One credential per subject, and per identity.** The shop has two: `shop-staging`, trusted for the
`staging` environment and given Contributor on `rg-shop-staging`; and `shop-production`, trusted only
for `production`, with a role scoped to `rg-shop`. A staging run that is compromised has nothing in
production to sign in as.

## When it does not match

A subject that matches nothing fails at the login step, with Entra ID's error `AADSTS700213`, which
names the subject it was sent and found no credential for. That error is the most useful line in the
log: compare the subject it quotes with the one in the credential, character by character. The usual
cause is a job that gained or lost `environment:`, which changes the subject's shape.
