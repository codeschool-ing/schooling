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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 244\" role=\"img\" aria-label=\"The same two tools at three moments: the editor formats on save, the hook formats what is being committed, and CI checks without rewriting and refuses. Only the last one is allowed to say no.\"> <defs><marker id=\"ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <rect x=\"20\" y=\"34\" width=\"224\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"132\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the editor, on save</text> <text x=\"132\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">formats and organises imports</text> <text x=\"132\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">you never think about it</text> <rect x=\"256\" y=\"34\" width=\"224\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"368\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">the hook, on commit</text> <text x=\"368\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the same, on what is staged</text> <text x=\"368\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">nothing unformatted is committed</text> <path d=\"M246 52 L252 52\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <rect x=\"492\" y=\"34\" width=\"224\" height=\"36\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.2\" stroke=\"var(--amber)\"></rect> <text x=\"604\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">CI, on push</text> <text x=\"604\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">--check: rewrites nothing, and exits non-zero</text> <text x=\"604\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">and this is the one that refuses</text> <path d=\"M482 52 L488 52\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-amber)\"></path> <text x=\"360\" y=\"180\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Put the linter AFTER the formatter check, so a file that is merely unformatted</text> <text x=\"360\" y=\"197\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">fails on the sentence that says so rather than on a list of findings.</text> </svg>", "caption": "Format on save is where this actually works. A formatter you have to remember to run is one half the repository has not been through."}
```

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
