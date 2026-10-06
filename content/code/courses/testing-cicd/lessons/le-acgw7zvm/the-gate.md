---
title: The gate before production
version: 1
---

Between staging and production sits the **gate**: the point where somebody, or something, decides
that this artifact goes further. In continuous delivery the gate is usually a person approving a
release that the pipeline has already proved deployable. In continuous deployment it is a rule: every
check green, and the change goes on its own.

## What crosses the gate is the artifact

The decision is about **a specific artifact**, identified by its hash, and what reaches production
has to be that artifact and nothing else. `deploy.sh` checks the hash before unpacking anything.
Here a copy of the artifact has one byte added on its way to production:

```
ana@laptop:~/shipquote$ ops/deploy.sh production /tmp/shipquote-1.4.0.tar.gz; echo "exit status $?"
shipquote-1.4.0.tar.gz: FAILED
sha256sum: WARNING: 1 computed checksum did NOT match
exit status 1
```

`sha256sum` computed a hash that does not match the one the build wrote, said `FAILED`, and the
deploy stopped with exit status 1 before touching the environment. A byte changed by a broken
download, a disk error or somebody's edit is caught the same way. Then the real artifact goes
through:

```
ana@laptop:~/shipquote$ ops/deploy.sh production dist/shipquote-1.4.0.tar.gz
smoke: http://127.0.0.1:8300 is up and running 1.4.0
ana@laptop:~/shipquote$ for port in 8200 8300; do curl -s http://127.0.0.1:$port/version; echo; done
{"version": "1.4.0", "env": "staging"}
{"version": "1.4.0", "env": "production"}
```

Staging and production now run **the same release, 1.4.0**, and differ only in their environment.
Nothing was rebuilt for production; the bytes that passed staging are the bytes that run there.

## Where the gate lives on a hosted service

GitHub Actions models this with **environments**: a job that declares `environment: production` waits
until the environment's protection rules are satisfied, such as approval by named reviewers, a wait
timer, or deployment only from `main`. The environment can also hold its own secrets, available only
to jobs that passed its rules, which lesson 9 uses. GitLab has the same idea under the same name,
with protected environments and deployment approvals.

```yaml
  production:
    needs: staging
    runs-on: ubuntu-24.04
    environment: production
    steps:
      - run: ops/deploy.sh production dist/shipquote-1.4.0.tar.gz
```

That fragment is a sketch, not part of `shipquote`'s workflow: the lab has no GitHub repository and
no production for the job to reach.

## What a person at the gate is for

An approval that is always given is not a gate; it is a delay. A person at the gate is worth having
when they **know something the pipeline does not**: that a marketing campaign starts in an hour,
that the carrier is migrating its API tonight, that the support team is short-staffed. If every
reason to wait can be written as a check, write it as a check, and the gate can become a rule. That
is how teams move from delivery to deployment: one decision at a time, as each becomes automatable.
