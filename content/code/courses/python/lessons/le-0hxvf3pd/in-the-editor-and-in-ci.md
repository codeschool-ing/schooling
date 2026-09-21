---
title: On save, in the pipeline, and before the commit
version: 1
---

```json
// the editor
"editor.formatOnSave": true,
"editor.codeActionsOnSave": { "source.organizeImports.ruff": "explicit" }
```

**Format on save is where this actually works.** A formatter you have to remember to run is a
formatter half the repository has not been through, and then the diffs are about layout again.

## The pipeline

```yaml
- run: ruff format --check .
- run: ruff check .
```

`--check` rewrites nothing and exits non-zero. That is the whole point of it existing: CI reports
a disagreement and does not quietly commit a fix into somebody's branch.

Put the linter after the formatter's check, so a file that is merely unformatted fails on the
sentence that says so rather than on a list of `E` findings.

## The hook, and what it is for

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.16.8
    hooks:
      - id: ruff-check
        args: [--fix]
      - id: ruff-format
```

Pin `rev` to the version you actually have, and let `pre-commit autoupdate` move it — a hook
running a different `ruff` from CI is a commit that passes locally and fails in the pipeline. The
id was `ruff` for years and is now `ruff-check`; the old name still works as an alias, which is
why old configurations keep running and nobody notices the rename.

A pre-commit hook runs the tools before the commit is made, so the code that reaches the branch
is already formatted. It is worth having and it is **not a substitute for the CI check**: a hook
lives on each person's machine, can be skipped with `--no-verify`, and is not installed on the
machine of whoever joined last week.

**CI is what is true. The hook is what is convenient.**

## The order to adopt this in

1. The formatter on everything, in one commit, with `.git-blame-ignore-revs` set.
2. `--check` for the formatter in CI on the same day, or the repository drifts back within a week.
3. The linter with the default rules, which almost passes already.
4. One family at a time, each in its own pull request.

Doing it the other way round — the interesting rules first — produces a list of four thousand
findings and a team that turns the tool off.
