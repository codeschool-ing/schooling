---
title: The workflow
version: 1
---

The tests run anywhere pytest does. On GitHub, a workflow runs them on every pull request that touches
something able to change a reply. The file below is shown and not run here, since this machine is not a
GitHub runner; the commands in its steps are the ones run in the previous sections:

```yaml
name: evaluation

on:
  pull_request:
    paths:
      - "assistant.py"
      - "releases.json"
      - "prices.json"
      - "requirements.txt"
      - "data/docs/**"
      - "data/eval-v2.jsonl"
      - "data/eval-v2.manifest.json"
      - "gate.json"
      - "tests/**"
      - ".github/workflows/evaluation.yml"

permissions:
  contents: read

jobs:
  gate:
    runs-on: ubuntu-24.04
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0
      - uses: actions/setup-python@5fda3b95a4ea91299a34e894583c3862153e4b97 # v7.0.0
        with:
          python-version: "3.11"
      - run: pip install -r requirements.txt
      - name: The set, which calls no model
        run: python -m pytest -q tests/test_set.py
      - name: The candidate against production
        env:
          OPENAI_API_KEY: ${{ secrets.EVALUATION_OPENAI_KEY }}
        run: |
          CANDIDATE=$(python -c 'import json; r = json.load(open("releases.json")); print(max(r, key=lambda k: r[k]["from"]))')
          CANDIDATE=$CANDIDATE python -m pytest -q tests/test_regression.py
```

Each choice in it is a lesson from earlier in the course:

- **The paths are everything that can change a reply**, not only the code: the documents the search
  reads, the prices the budget is measured in, the requirements (a library upgrade is a model change in
  disguise), the set and the gate. A filter that misses one lets that kind of change merge untested,
  silently; one that includes too much costs a few cents. When in doubt, the filter errs towards running.
- **The set's tests come first and need no secret**, so a pull request from a fork, which gets no
  secrets, still has its set checked.
- **The key is a secret, scoped to evaluation**, with its own spending limit at the provider. A pipeline
  that answers forty-two questions twice per pull request is a predictable bill, and a separate key
  makes it a visible one, as lesson 3 asked of every feature.
- **The candidate is the newest release in `releases.json`**, the one the pull request adds. Production
  is whatever is live now, decided in `conftest.py` by the same function the assistant uses.
- **The actions are pinned to commits**, with the tag beside each, as this repository's own workflows
  pin theirs.

## One thing a real model adds

extract-1 gives the same reply to the same question every time, so a broken case in this lab is broken
on every run. A real model, sampling its tokens, may not: a case can fail once and pass on the next run
with nothing changed. Asking for temperature 0 makes this rarer and does not remove it. The gate stays
the same, and the response to a failure is the same too: read the case. A case that fails on one run
of the candidate and passes on the next is evidence that the reply is unstable, which is a property of
the release worth knowing, not a reason to rerun until the gate is green.
