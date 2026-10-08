---
title: How long a run may take
version: 1
---

A CI run is feedback, and feedback loses value with every minute it takes. A run that answers in
five minutes is read by the person who pushed, while the change is still in their head. A run that
answers in forty is read after lunch, by someone who has started something else, and often not
read at all. **The time a pipeline takes is part of its design**, not a property it happens to have.

The push in section 07 was run under `time`, and its last lines are the lab pipeline's whole
duration: `real 0m13.315s`, **13.3 seconds** from the push to the verdict, six cells and the
installs included. The JUnit reports of that run say where the time went inside the cells:

```
ana@laptop:~/shipquote$ for f in ~/ci/runs/5/*.xml; do grep -o "<testsuite [^>]*>" $f | grep -oE "(tests|time)=\"[0-9.]+\"" | tr "\n" " "; echo "$(basename $f .xml)"; done
tests="43" time="1.960" py3.11-America-Sao_Paulo
tests="43" time="1.390" py3.11-UTC
tests="43" time="1.964" py3.12-America-Sao_Paulo
tests="43" time="1.418" py3.12-UTC
tests="43" time="2.048" py3.13-America-Sao_Paulo
tests="43" time="1.426" py3.13-UTC
```

Each cell ran 43 tests, the 41 that passed and the 2 skipped, in about one and a half to two
seconds. Six cells, run one after another, add up to most of the 13 seconds; the rest is creating
three virtual environments from the cache. Notice also that **every São Paulo cell took about half
a second longer than its UTC neighbour**, in every Python. The lab does not explain it, and nothing
failed, but a matrix puts numbers like that side by side where somebody can notice.

## Where the time goes, and what to do about it

| cost | remedy |
|---|---|
| cells run one after another | run them in parallel, as hosted runners do: the run then takes as long as its slowest cell |
| installing dependencies | cache them under a key on the lock file (section 08) |
| slow tests run first | order jobs so the fast layer reports first (lesson 1 section 14) |
| everything runs for every change | skip what a change cannot affect, without skipping silently (section 04) |
| one slow suite | split it across several machines, and measure the slowest split |

A common target is **under ten minutes** for the checks that gate a merge. It is not a law, and the
right number depends on the team, but past ten minutes people stop waiting for the result and start
batching changes, which is the opposite of integrating continuously.

## This repository's numbers

The run of the repository's own workflow that this lesson's author looked at, on the commit that
merged the previous course, started at 15:34:36 UTC and finished at 15:40:47. That is a little over six
minutes for four jobs, among them a Go suite against a real PostgreSQL and a browser suite.
Lesson 6 reads that run job by job, from the service's own record.
