---
title: The workflow, line by line
version: 1
---

**A GitHub Actions workflow is a YAML file in `.github/workflows/` that says when to run, on what kind of
machine, and which commands.** GitHub reads every file in that folder on every push and pull request, and
runs the ones whose triggers match. This is the planner's, and it runs the four steps of this lesson's
first section. **It was not run for this course**: it needs the repository on GitHub. Everything it runs,
you ran in the previous three sections.

```schooling-example
{"language": "yaml", "file": ".github/workflows/ci.yml", "parts": [
 {"code": "# .github/workflows/ci.yml\nname: CI", "note": "The name GitHub shows beside a pull request's checks."},
 {"code": "\non:\n  pull_request:\n  push:\n    branches: [main]", "note": "When it runs: on every pull request, against the code the merge would produce, and on every push to `main`, so the branch itself is checked after each merge."},
 {"code": "\npermissions:\n  contents: read", "note": "What the workflow's own token may do. Reading the repository is all four steps need, and anything a workflow is not given, a compromised step cannot use."},
 {"code": "\nconcurrency:\n  group: ci-${{ github.ref }}\n  cancel-in-progress: true", "note": "Two pushes to the same branch in a minute: the first run is cancelled, since only the newest result matters."},
 {"code": "\njobs:\n  check:\n    runs-on: ubuntu-24.04\n    timeout-minutes: 10", "note": "One job, on a fresh Ubuntu 24.04 machine that GitHub starts for it and throws away afterwards. A version, not `ubuntu-latest`, so the machine changes when you decide. The timeout stops a hung step from burning an hour of minutes."},
 {"code": "    steps:\n      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1\n        with:\n          persist-credentials: false", "note": "Clone the repository: the clean copy. `persist-credentials: false` stops the token from being left in the clone's git configuration, where a later step could read it."},
 {"code": "      - uses: actions/setup-node@949feb2413d6458794dcd2491c4babbbce0c15c1 # v7.1.0\n        with:\n          node-version: 22.22.0\n          cache: npm", "note": "Node at the exact version the course uses, and npm's download cache kept between runs, keyed by the lockfile. The next section measures what that saves."},
 {"code": "      - run: npm ci\n      - run: npx tsc\n      - run: npm test\n      - run: npx vite build", "note": "The pipeline: install from the lockfile, types, tests, build. A step that exits with an error stops the job and turns it red."}
]}
```

## Why a commit and not a version

`uses: actions/checkout@v7` would work, and it would mean **whatever the `v7` tag points at on the day
the workflow runs**. A tag in somebody else's repository can be moved, by its owners or by whoever takes
over their account, and the code it points at then runs in your pipeline, with your token. Forty
characters of commit cannot be moved: they name one exact version of the action's code. The comment beside
each is for the person who has to decide whether it is old; a tool such as Dependabot updates both
together.

The two actions here were checked for the runtime they declare, because GitHub retires old Node runtimes
for actions on its own schedule: both say `node24` in their `action.yml`.

## What you see on a pull request

GitHub shows one row per job under the pull request, `CI / check`, with a yellow dot while it runs, then
a green tick or a red cross. A click opens the log, one fold per step, and a red step is opened for you at
the line that failed. **That log is the same text your terminal printed** in the last three sections: the
`npm ci` refusal, the test that expected 85 and received 130, the type error on `./format`. Nothing on
CI is new; it is your checks, run where everybody can see them.

Add the file to the planner, so the repository carries its own pipeline:

```
ana@dev:~/planner$ git add .github/workflows/ci.yml
ana@dev:~/planner$ git commit -qm "Run the checks on every pull request"
```
