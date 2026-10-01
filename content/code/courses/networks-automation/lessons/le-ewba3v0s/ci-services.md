---
title: The same pipeline in a CI service
version: 1
---

Hosted CI services, GitHub Actions, GitLab CI, Jenkins and others, run the same two stages with more
around them: a web page per run, logs kept for months, approvals, schedules, and runners on
machines of your choosing. **The workflow below was not run in the lab**, which has no CI service;
it is the lesson's pipeline written for GitHub Actions, to show where each piece goes:

```yaml
name: network
on:
  pull_request:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - run: pip install -r requirements.txt
      - run: sh ci/test.sh

  deploy:
    if: github.ref == 'refs/heads/main'
    needs: test
    runs-on: [self-hosted, netops]
    environment: production
    steps:
      - uses: actions/checkout@v4
      - run: sh ci/deploy.sh
```

The `test` job is `pre-receive`: it runs on every pull request, on a machine with no access to the
network, and a failure blocks the merge when the branch is protected. The `deploy` job is
`post-receive`: it runs only on `main`, only after `test` passed, and on a **self-hosted runner**, a
machine of yours inside the management network, since a runner on the internet cannot reach the
routers and should not be able to. `environment: production` is where an approval step and the
deploy job's secrets are attached.

The one file it needs that the lab's project lacks is `requirements.txt`, the libraries and their
versions, which on `ctl` come from the lab's virtual environment. **The scripts in `ci/` did not
change.** That is the reason to keep them in the project rather than
in the CI service's configuration: the pipeline can be run by hand, tested in the lab, and moved to
another service by rewriting the twenty lines around it.
