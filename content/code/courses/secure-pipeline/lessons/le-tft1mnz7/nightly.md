---
title: The nightly list, and a build from nothing
version: 1
---

Some checks are worth running and too slow to wait for. They go on a second list that runs once a
day, on `main`, when nobody is waiting. **Moving a check there is not lowering the bar: it still
runs every day, on the code that is actually on `main`**, and its result still reaches somebody.
What changes is that nobody's push waits for it.

### The list

The nightly list has the same format as `ci/stages`: one stage per line, comments allowed. Save it
as `ci/nightly`:

```
# The checks too slow to wait for on every push. They run once a day on
# main, after everything in ci/stages has passed.
rebuild
```

Its one stage builds the image with no cache. Save it as `ci/rebuild.sh`:

```sh
# The image built from nothing. Every push reuses the layers already built,
# so a change that arrives without a commit, in the base image or in a
# package, never reaches it; this build has no cache to reuse.
set -euo pipefail
docker build -q --no-cache -t "linkbox:nightly" .
```

### Why a build from nothing

Docker reuses a layer whenever the instruction that made it and the files it read are unchanged.
For linkbox's `Dockerfile` that means the `pip install` line runs once, the first time, and every
later push reuses its result as long as `requirements.txt` is the same file. That is what makes the
build stage fast. It is also a blind spot: **the cached layer is a record of what the internet
answered on the day it was built.** A package that requirements.txt does not pin, pulled in by one
that it does, keeps the version it had then. A build that would now fail, because a version was
withdrawn from the index, keeps succeeding from the cache until the day somebody needs a clean one.

The rebuild runs every step again. Two things it does not do on its own, and the course comes back
to both. It uses the base image already on the machine: picking up a newer `python:3.13` takes
`docker pull` first, or `--pull` on the build, and lesson 15 pins the base by digest so that moving
it is a decision rather than an accident. And it does not scan what it built: lesson 8's image scan
is what reads the result.

Run the nightly list on the laptop before committing it. Unlike the test stage, the rebuild does not
trip over the laptop's `.venv`, because `.dockerignore` keeps it out of the build:

```
ana@vm:~/linkbox$ ci/pipeline.sh ci/nightly
rebuild: passed in 11s
pipeline passed
ana@vm:~/linkbox$ docker images linkbox:nightly
IMAGE             ID             DISK USAGE   CONTENT SIZE   EXTRA
linkbox:nightly   1669ea85472b       1.64GB          422MB        
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"sp-l02-builds\" aria-label=\"Five timings from one recording, on one scale from 0 to 11 seconds: making the virtual environment, 0.028 seconds; installing the packages from uv's cache, 0.073; pytest, 1.062; the image build with Docker's cache, 0.495; the nightly rebuild with no cache, 11 seconds.\"><defs></defs><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">uv venv</text><text x=\"20\" y=\"45\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">environment</text><rect x=\"230\" y=\"24\" width=\"1.5\" height=\"22\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"0.5\"></rect><text x=\"239.5\" y=\"35\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.028 s</text><text x=\"20\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">uv pip install</text><text x=\"20\" y=\"85\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">from uv's cache</text><rect x=\"230\" y=\"64\" width=\"2.92\" height=\"22\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"0.5\"></rect><text x=\"240.92\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.073 s</text><text x=\"20\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pytest</text><text x=\"20\" y=\"125\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">three tests</text><rect x=\"230\" y=\"104\" width=\"42.480000000000004\" height=\"22\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"0.5\"></rect><text x=\"280.48\" y=\"115\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1.062 s</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">docker build</text><text x=\"20\" y=\"165\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">with the cache</text><rect x=\"230\" y=\"144\" width=\"19.8\" height=\"22\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"0.5\"></rect><text x=\"257.8\" y=\"155\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">0.495 s</text><text x=\"20\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">rebuild</text><text x=\"20\" y=\"205\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no cache, nightly</text><rect x=\"230\" y=\"184\" width=\"440\" height=\"22\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"0.5\"></rect><text x=\"678\" y=\"195\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">11 s</text><line x1=\"230\" y1=\"14\" x2=\"230\" y2=\"220\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"230\" y1=\"220\" x2=\"230\" y2=\"225\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"230\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><line x1=\"430\" y1=\"220\" x2=\"430\" y2=\"225\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"430\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><line x1=\"630\" y1=\"220\" x2=\"630\" y2=\"225\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"630\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><text x=\"450\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">seconds of waiting, one scale</text></svg>", "caption": "Everything the push waits for fits in under three seconds. The build from nothing alone takes eleven."}
```

The same `Dockerfile`, the same files, the same machine: **the build from nothing took 11 seconds,
and the cached one under one.** The same rebuild on the server, below, took 10, which is the second
of variation the measuring section warned about. Eleven seconds is nothing to wait for today, because linkbox
installs eight small packages. An image that compiles a dependency or installs a system package takes
minutes, and the gap grows with every line of the `Dockerfile`. That gap is the reason the rebuild is not on every push.

### Commit, and push

```
ana@vm:~/linkbox$ git add ci
ana@vm:~/linkbox$ git status --short
A  ci/nightly
M  ci/pipeline.sh
A  ci/rebuild.sh
ana@vm:~/linkbox$ git commit -q -m "the pipeline takes a list: every push, and the nightly run"
ana@vm:~/linkbox$ git push ci main
remote: run 1: main at 023b325        
remote: test: passed in 1s        
remote: build: passed in 0s        
remote: pipeline passed        
remote: run 1: passed        
To /home/ana/ci/linkbox.git
   3f932db..023b325  main -> main
```

The hook runs `ci/stages`, as before, and nothing in the push waits for the rebuild.

### Who starts the nightly run

A push starts the server's run; a schedule starts the nightly one. On this server the schedule
would be a line in the crontab of the user the CI runs as. It clones `main` from the server's
repository and runs both lists in order, so the nightly checks only run on a `main` whose push
checks passed. Here is the same thing run by hand, the way the scheduler would run it:

```
ana@vm:~/linkbox$ rm -rf /tmp/nightly && git clone -q ~/ci/linkbox.git /tmp/nightly && /tmp/nightly/ci/pipeline.sh && /tmp/nightly/ci/pipeline.sh ci/nightly
test: passed in 1s
build: passed in 1s
pipeline passed
rebuild: passed in 10s
pipeline passed
ana@vm:~/linkbox$ rm -rf /tmp/nightly
```

On a real server, the crontab of the user the CI runs as would hold two lines like these, the
second at 03:10 every night. The first matters as much: cron starts commands with a minimal `PATH`
that does not include `~/.local/bin`, where `uv` lives, and the test stage would fail on the first
night.

```
PATH=/home/ana/.local/bin:/usr/local/bin:/usr/bin:/bin
10 3 * * * (rm -rf /tmp/nightly && git clone -q ~/ci/linkbox.git /tmp/nightly && /tmp/nightly/ci/pipeline.sh && /tmp/nightly/ci/pipeline.sh ci/nightly) >>~/ci/nightly.log 2>&1
```

They were not installed on the recording machine, so that the lab stays quiet between lessons, and
no run of them is shown. Add them with `crontab -e`, with your own user's home in the `PATH`, if you
want the real thing.

Hosted CI has the same idea under another name. GitHub Actions runs a workflow on a schedule with
`on: schedule:` and a cron expression, against the latest commit of the default branch, and its
documentation warns that a scheduled run can be delayed when its runners are busy. GitLab calls
them pipeline schedules. Neither was run for this course.

### The result has to reach somebody

At 03:10 nobody is watching. **A nightly run that fails into a log nobody opens is lesson 1's
ignored scanner again**, only quieter. Whatever runs the schedule has to send a failure somewhere a
person will see it in the morning: an email to the team, a message in its channel, an issue
assigned to whoever owns the service. Lesson 7 decides which nightly findings break and which only
warn; this lesson only has to make sure they are read.
