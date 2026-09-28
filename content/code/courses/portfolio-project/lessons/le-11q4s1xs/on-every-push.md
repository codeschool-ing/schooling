---
title: On every push
version: 1
---

Tests that run only when you remember are tests that stop running. The fix is to have the hosting site
run them on every push and every pull request, which on GitHub is a workflow file:

```yaml
name: tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"
      - run: python3 -m unittest -v
```

Saved as `.github/workflows/tests.yml`, it checks out the code, installs Python 3.12 and runs the same
command as above. **It was not run for this course**: the lab has no GitHub, and loanbook's history does
not include it. It is the file you would add in the first week, and GitLab's equivalent, `.gitlab-ci.yml`,
has the same three steps.

For a portfolio it earns its place three ways. **Every commit gets a green tick or a red cross** next to
it on the site, which is lesson 9's *no commit breaks the build* shown rather than claimed. **A pull
request cannot be merged by accident on red**, if you turn that protection on. And **a reviewer sees it
without running anything**: the tick is evidence in exactly lesson 1's sense.

Keep it that small. A workflow with ten jobs for a project with seven tests is lesson 8's theatre in
another file.
