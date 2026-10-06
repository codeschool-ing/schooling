---
title: The matrix and the artifacts, in YAML
version: 1
---

Lesson 5's hook ran six cells in two nested loops and wrote each cell's results to a directory.
`shipquote`'s workflow says the same in a few lines, and the service does the rest.

```yaml
    strategy:
      fail-fast: false
      matrix:
        python: ["3.11", "3.12", "3.13"]
        tz: ["America/Sao_Paulo", "UTC"]
```

GitHub multiplies the lists: **every combination becomes its own job**, on its own machine, running
in parallel, each with `matrix.python` and `matrix.tz` filled in. Six jobs, named after their values
on the run's page. When a combination should not run, or an extra one should, the matrix takes
`exclude` and `include` lists:

```yaml
      matrix:
        python: ["3.11", "3.12", "3.13"]
        tz: ["America/Sao_Paulo", "UTC"]
        exclude:
          - python: "3.12"
            tz: "UTC"
```

That would give five jobs. The sketch is not in `shipquote`; it shows how a team keeps a matrix to
the cells that earn their cost, as lesson 5 section 06 asked.

## Artifacts between jobs

Jobs do not share files: each runs on a different machine, and the machine is discarded at the end.
To pass something from one job to another, the first job **uploads** it as an artifact and the second
**downloads** it. In `shipquote` every matrix cell uploads its JUnit report and its `.coverage.*` file
as `results-0` to `results-5`, and the coverage job downloads them all:

```yaml
      - uses: actions/download-artifact@3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c # v8.0.1
        with:
          pattern: results-*
          merge-multiple: true
      - run: coverage combine && coverage report
```

`merge-multiple` puts the six artifacts' files into one directory, which is what `coverage combine`
expects. Two details from the upload step are easy to miss:

- **`include-hidden-files: true`**: `.coverage.*` files start with a dot, and the upload action
  leaves hidden files out unless told otherwise. Without it the coverage job would combine nothing
  and report nothing, with every job green.
- **`if: always()`** on the upload and on the coverage job: by default a step or job is skipped when
  something before it failed, and a failing run is exactly when the reports matter.

Artifacts have a retention period, set per repository or per upload, after which the service
deletes them. A report somebody may need months later, a release's test results for an audit, is
kept somewhere of the team's own rather than in a CI service's temporary storage.
