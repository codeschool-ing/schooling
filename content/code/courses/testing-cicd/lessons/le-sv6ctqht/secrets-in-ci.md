---
title: Giving a secret to a pipeline job
version: 1
---

A CI service keeps secrets in its own store, encrypted, and hands them to jobs at run time. On
GitHub Actions they are **repository secrets**, **organisation secrets** or **environment secrets**,
and a workflow refers to one by name:

```yaml
  contract:
    runs-on: ubuntu-24.04
    environment: staging
    steps:
      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0
      - run: pip install -r requirements-dev.txt
      - run: python -m pytest -m contract -rs
        env:
          CARRIER_URL: https://sandbox.carrier.example
          CARRIER_TOKEN: ${{ secrets.CARRIER_SANDBOX_TOKEN }}
```

This is a sketch of the job that would run lesson 2's contract tests against a carrier's sandbox; it
is not in `shipquote`'s workflow, because the lab has no repository on GitHub and no carrier account.
Three choices in it are the point.

**The secret is handed to one step, through `env`.** Only the step that needs it receives it, and as
an environment variable rather than an argument, for section 04's reason. A secret placed in the
workflow-level `env` would be in every step of every job, including the ones running code nobody on
the team wrote.

**The job names an environment.** `environment: staging` means the secret comes from the staging
environment's store, and the job is subject to that environment's protection rules. A production
token lives only in the production environment, so a job that does not declare it cannot receive it,
whatever its YAML says. That is lesson 8 section 10's table, enforced.

**The test is the contract test, and it does not skip.** Lesson 2 warned that a contract test with
no `CARRIER_URL` is skipped for ever and reports success; this job is where the variable is finally
set, and `-rs` makes a skip visible in the log if it ever happens again.

## GitLab's equivalents

GitLab keeps **CI/CD variables** per project, group or instance. A variable can be **masked**, so its
value is hidden in job logs (section 06 shows what that does and does not cover), and **protected**,
so it is given only to pipelines on protected branches and tags. An unprotected variable reaches any
pipeline, including one for a branch somebody pushed five minutes ago, which is why production
credentials are always protected and usually scoped to a protected environment as well.
