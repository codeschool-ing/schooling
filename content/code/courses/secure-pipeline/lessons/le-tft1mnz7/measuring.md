---
title: Measuring the pipeline
version: 1
---

A time budget is only useful if somebody knows how much of it is spent. **The pipeline already
measures itself**: every line it prints ends in the seconds that stage took, and every push
prints those lines back to whoever pushed. What it does not say is where the seconds go inside a stage, and that is
the number that tells you what to change when a stage gets slow.

### Inside the test stage

The test stage does three things: it makes a virtual environment, installs the pinned packages
into it and runs pytest. Time each one in the clean clone from the last section, starting from no
environment, the way every server run starts:

```
ana@vm:~/linkbox$ cd /tmp/linkbox-run && rm -rf .venv
ana@vm:/tmp/linkbox-run$ time uv venv -q .venv

real	0m0.028s
user	0m0.008s
sys	0m0.009s
ana@vm:/tmp/linkbox-run$ time uv pip install -q -r requirements.txt -r requirements-dev.txt

real	0m0.073s
user	0m0.018s
sys	0m0.054s
ana@vm:/tmp/linkbox-run$ time .venv/bin/python -m pytest -q
...                                                                      [100%]
3 passed in 0.43s

real	0m1.062s
user	0m0.845s
sys	0m0.202s
ana@vm:/tmp/linkbox-run$ time docker build -q -t linkbox:dev .
sha256:700b22e3ef4bc00d17c40627b168f793b0dc439b6dedb98bcc2dc5a4d60fe1e7

real	0m0.495s
user	0m0.110s
sys	0m0.142s
ana@vm:/tmp/linkbox-run$ cd ~/linkbox && rm -rf /tmp/linkbox-run
```

`time` prints three numbers, and `real` is the one a person waits for.

**Most of the test stage is the tests.** Making the environment took 0.028 seconds and installing
the pinned packages into it 0.073. pytest says the three tests ran in 0.43 seconds, and the `real`
line around it, 1.062, adds Python starting up and importing Flask and pytest itself. The install
is that quick only because `uv` keeps a cache of every package it has downloaded, in `~/.cache/uv`,
and links them in from there. On a hosted runner that starts from an empty machine, the same line
downloads every package again on each run. Saving the cache and restoring it between runs is what
the caching features of GitHub Actions and GitLab CI are for.

The cached build, 0.495 seconds, is the same kind of number: Docker found every layer already built
for these exact files and reused them. The nightly section of this lesson builds the same image
with no cache, and the difference between the two is the cost of every line in the `Dockerfile`
that the cache was hiding.

### What to watch

A single run says little. What matters is **the trend per stage**, because pipelines get slow one
second at a time and nobody decides it. Three habits keep the budget honest:

- **Look at the time of every stage, on every run, not only the total.** A total that grows by a
  minute is a stage that grew by a minute, and the stage is the thing somebody can fix.
- **Keep the numbers.** linkbox's server keeps each stage's log in `~/ci/runs/N` but not the timing
  lines, which go to the terminal of whoever pushed and are gone when it closes. Saving them is one
  more line in the hook, and it is what lets "when did the test stage start taking a minute?" have
  an answer. Hosted CI keeps a duration per job and per step for a period its documentation states.
- **Decide what happens at the limit before it is reached.** When a push takes longer than its
  budget, something moves to the nightly list, or is made faster, or is split so it reads only what
  changed. A team that has not decided this in advance decides it in the worst way, by marking a
  stage "allowed to fail".

### How exact the numbers are

The pipeline measures with bash's `SECONDS`, a whole number of seconds since the shell started.
The difference between two readings can be a second off in either direction, so "passed in 0s"
means "in less than about a second", and two runs of the same stage can differ by a second or two
with nothing changed. **That is precise enough for a budget measured in minutes**, and it is why
the timings in this course are quoted as they were printed, not to the millisecond. When a stage
needs closer study, `time` on its pieces, as above, is the instrument.

Each number also depends on the machine. Every timing in this course was recorded on one laptop,
and yours will differ. What should match is the shape: which stage dominates, and how far the
cached build is from the clean one.
