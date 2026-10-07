---
title: Catching a broken workflow before it runs
version: 1
---

A mistake in a workflow file is expensive to find the usual way: push, wait for a runner, read a
failure, fix, push again. Some mistakes do not even fail. A misspelt expression evaluates to an
empty string, and a step quietly runs with nothing where a value should be.

Here are two typos made on purpose: `matrix.pyton` for `matrix.python` in the suite job, and
`cache-dependancy-path` for `cache-dependency-path` in the fast job. actionlint is run again:

```
ana@laptop:~/shipquote$ actionlint; echo "exit status $?"
.github/workflows/ci.yml:43:31: property "pyton" is not defined in object type {python: number; tz: string} [expression]
   |
43 |           python-version: ${{ matrix.pyton }}
   |                               ^~~~~~~~~~~~
exit status 1
```

**One of the two was caught.** actionlint knows the shape of the matrix, an object with a `python`
and a `tz`, so `pyton` is a property that does not exist. On GitHub the expression would have
produced an empty string, and `setup-python` would have received an empty version, so the error
would have surfaced as a confusing message from the action, after a runner had been spent on it.

**The other was not.** A misspelt input of an action is something actionlint checks only for actions
it has data about, and it did not flag this one. On GitHub the run would go ahead, and the action
would ignore the unknown input with a warning in the log, so the cache would quietly be keyed on
something else. Every checker has edges, and the edge here is the same as in lesson 4: **a check
that found nothing has not proved there is nothing.**

## Where to run it

A workflow checker is cheap enough to run in the place every other check runs: as the first step of
the workflow itself, and before a commit on the author's machine. Treat its findings like a failing
test. A checker whose warnings are always ignored becomes a log line nobody reads, which is how an
expression that evaluates to nothing reaches `main`.

GitLab offers the same idea in a different form: every project has a **CI lint** page and an API
that validates `.gitlab-ci.yml` against the project's own configuration, which is the closest
equivalent. Section 10 runs the lab's GitLab file for real, which is a stronger check than either.
