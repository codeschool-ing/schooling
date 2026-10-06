---
title: Jobs, steps and the exit status
version: 1
---

A CI run is made of **jobs**, and a job is made of **steps**. The two words mean the same thing in
almost every service:

- a **job** runs on one machine, from a clean start, and is the unit that can run in parallel with
  other jobs. The six cells of the lab's matrix would be six jobs on a hosted service;
- a **step** is one command or action inside a job. Steps run in order, share the job's files, and
  **the first step that fails stops the job**.

How does the CI know a step failed? Only one way: **the exit status of the command**. Zero is
success, anything else is failure. The CI does not read the output, look for the word "error" or
count red lines. A step that prints a hundred failures and exits 0 is a green step.

## The pipe that lies

That makes every step's exit status worth checking, and the commonest way to lose it is a pipe.
Lessons 1 and 4 both met it; here is the fix. The command runs pytest with a marker that selects
nothing, so pytest exits 5, and pipes the output through `tee` to keep a log:

```
ana@laptop:~/shipquote$ python -m pytest -q -m smoke | tee run.log; echo "exit status $?"

43 deselected in 0.21s
exit status 0
ana@laptop:~/shipquote$ set -o pipefail; python -m pytest -q -m smoke | tee run.log; echo "exit status $?"

43 deselected in 0.18s
exit status 5
```

The first line reports `exit status 0`. A pipeline's status is, by default, **the status of its last
command**, and `tee` succeeded. The second line sets `pipefail`, which makes a pipeline fail if any
command in it failed, and now the status is pytest's 5.

**Every shell step in a CI should run with `-e` and `-o pipefail`**: `-e` stops at the first command
that fails, `pipefail` stops a pipe from hiding one. The lab's hook starts with `set -uo pipefail`
for the same reason, and leaves out `-e` deliberately, because it wants to keep going and report
every cell.

## Check what your service does by default

GitHub Actions documents its default for `run` steps on Linux as `bash -e {0}` when no shell is
named, and `bash --noprofile --norc -eo pipefail {0}` when a step says `shell: bash`. So **a step
with no `shell:` line runs without `pipefail`**, and the first command above would pass there too.
GitLab CI runs a job's script lines through a shell with its own rules. The safe habit does not
depend on remembering any of it: either name the shell, or start multi-line steps with
`set -euo pipefail`.

## Dependencies between jobs

Jobs run in parallel unless one says it needs another. A typical graph: a fast lint job and the unit
tests side by side; integration tests only after both pass; a deploy only after everything. Lesson
6 writes those edges as `needs:` in GitHub Actions and as stages in GitLab CI. The principle is the
one from lesson 1 section 11: **fast checks first**, so a typo fails in thirty seconds rather than
after a ten-minute browser suite.
