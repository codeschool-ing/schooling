---
title: The workflow
version: 2
---

The tests run anywhere pytest does. On GitHub, a workflow runs them on every pull request that touches
something able to change a reply. It needs the repository to say which libraries it installs, so
write them down in `~/obs`, at the versions this course installed:

```sh
cat > requirements.txt <<'REQ'
openai==3.24.0
numpy==2.4.6
opentelemetry-sdk==1.45.0
presidio-analyzer==2.2.364
en_core_web_lg @ https://github.com/explosion/spacy-models/releases/download/en_core_web_lg-3.8.0/en_core_web_lg-3.8.0-py3-none-any.whl
pytest==9.1.1
REQ
```

The workflow goes in `.github/workflows/evaluation.yml`. It is shown here and not run, since this
machine is not a GitHub runner; the commands in its steps are the ones run in the previous sections:

```yaml
name: evaluation

on:
  pull_request:
    paths:
      - "*.py"
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
    timeout-minutes: 90
    env:
      OPENAI_BASE_URL: http://127.0.0.1:11434/v1
      OPENAI_API_KEY: ollama
      PSEUDONYM_KEY: evaluation-${{ github.run_id }}
    steps:
      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0
      - uses: actions/setup-python@5fda3b95a4ea91299a34e894583c3862153e4b97 # v7.0.0
        with:
          python-version: "3.12"
      - run: pip install -r requirements.txt
      - name: The set, which calls no model
        run: python -m pytest -q tests/test_set.py
      - name: Ollama, and every model the releases name
        run: |
          curl -fsSL https://ollama.com/install.sh | OLLAMA_VERSION=0.40.0 sh
          timeout 60 sh -c 'until ollama list > /dev/null 2>&1; do sleep 1; done'
          ollama pull all-minilm
          for m in $(python -c 'import json; print(*{r["model"] for r in json.load(open("releases.json")).values()})'); do
            ollama pull "$m"
          done
      - name: The index, from the documents in this pull request
        run: python index.py
      - name: The candidate against production
        run: |
          CANDIDATE=$(python -c 'import json; r = json.load(open("releases.json")); print(max(r, key=lambda k: r[k]["from"]))')
          CANDIDATE=$CANDIDATE python -m pytest -q tests/test_regression.py
```

Each choice in it is a lesson from earlier in the course:

- **The paths are everything that can change a reply**, not only the assistant: every program, the
  documents the search reads, the prices the budget is measured in, the requirements (a library
  upgrade is a model change in disguise), the set and the gate. A filter that misses one lets that
  kind of change merge untested, silently; one that includes too much costs a few minutes. When in
  doubt, the filter errs towards running.
- **The set's tests come first and need no model**, so a pull request that breaks the set fails in
  seconds, before anything is downloaded.
- **The runner gets the same model you have**, at the same Ollama version, and no key. Every model
  `releases.json` names is pulled, because the candidate may use one production does not. A runner
  with no GPU answers more slowly than your machine, which is what the 90 minutes are for, and the
  budget for latency still compares like with like, because both releases answer on the same runner
  in the same run.
- **`PSEUDONYM_KEY` is new on every run, and never production's.** Lesson 2's assistant refuses to
  record a user id without one, and the only user here is `evalrun`, whose pseudonym nobody needs to
  match across runs. The key that keys real customers' ids stays where it is kept.
- **The index is built from the documents in the pull request**, so a change to a document is tested
  against what the assistant will search after it merges, not against the index from before.
- **The candidate is the newest release in `releases.json`**, the one the pull request adds. Production
  is whatever is live now, decided in `conftest.py` by the same function the assistant uses.
- **The actions are pinned to commits**, with the tag beside each, so that what runs is what was
  reviewed rather than whatever a tag points to today.

On the online path the step that installs Ollama goes, and the two variables become a key from the
repository's secrets, kept for evaluation alone and with its own spending limit at the provider. A
pipeline that answers 32 questions twice per pull request is a predictable bill, and a separate key
makes it a visible one, as lesson 3 asked of every feature. A pull request from a fork gets no secrets,
so there only the set's tests can run, and the workflow should say so rather than pass.

## What a model adds to a test

A test of ordinary code gives the same answer every time it runs on the same commit. This one need
not. Lesson 14 found e31 answered two ways by the same settings at temperature 0, and the latency
budget above passed on one run and failed on another. So a case can fail once and pass on the next run
with nothing changed.

The gate stays the same, and the response to a failure is the same too: **read the case**. A case
that fails on one run of the candidate and passes on the next is evidence that the reply is unstable,
which is a property of the release worth knowing. It is not a reason to rerun until the gate is green:
a gate that is rerun until it passes is a gate that passes.
