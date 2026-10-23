---
title: A pipeline, and a CI server of your own
version: 1
---

A pipeline is a list of checks that runs on every change, in the same order, on a machine nobody
types on. Hosted services such as GitHub Actions and GitLab CI run one for you, and
`testing-cicd` lessons 5 and 6 used them. This course builds its own, small enough to read in full,
for two reasons. Every stage it adds runs on your machine, so a capture in a lesson is something
you can reproduce exactly. And a pipeline you wrote has no part you cannot see, which matters in a
course whose lesson 16 asks what a pipeline can be made to do by somebody who should not control
it.

**Two halves: the pipeline lives in the repository, and the server only runs it.** The pipeline is
`ci/pipeline.sh` and the stages it calls. The server is a bare repository with a hook, and all the
hook does is check out what was pushed and start that commit's own pipeline. Change a stage and the
change travels with the commit, reviewed like any other line of code.

### The pipeline

The runner reads the stages from a list, one per line, and stops at the first that fails. Save it
as `ci/pipeline.sh`:

```sh
#!/usr/bin/env bash
# The pipeline: every stage named in ci/stages, in that order. A stage is the
# script ci/<name>.sh, run from the repository's root. Exit 0 passes it;
# anything else breaks the build, and the run stops at that stage.
set -uo pipefail
cd "$(dirname "$0")/.."
LOGS=${CI_LOGS:-ci-logs}
mkdir -p "$LOGS"
while read -r stage; do
  case $stage in '' | '#'*) continue ;; esac
  start=$SECONDS
  if bash "ci/$stage.sh" >"$LOGS/$stage.log" 2>&1; then
    echo "$stage: passed in $((SECONDS - start))s"
  else
    echo "$stage: FAILED in $((SECONDS - start))s, the end of $stage.log:"
    tail -n 15 "$LOGS/$stage.log" | sed 's/^/  /'
    exit 1
  fi
done <ci/stages
echo "pipeline passed"
```

The list, as `ci/stages`:

```
test
build
```

The tests, in a virtual environment made fresh for every run, as `ci/test.sh`:

```sh
# The unit tests, in a fresh virtual environment with the pinned dependencies.
set -euo pipefail
uv venv -q .venv
uv pip install -q -r requirements.txt -r requirements-dev.txt
.venv/bin/python -m pytest -q
```

And the image, tagged with the commit it came from, as `ci/build.sh`:

```sh
# The image, tagged with the commit it was built from.
set -euo pipefail
docker build -q -t "linkbox:${CI_COMMIT:-dev}" .
```

The runner has to be executable, and the commit records that:

```
ana@vm:~/linkbox$ chmod +x ci/pipeline.sh
ana@vm:~/linkbox$ git add ci
ana@vm:~/linkbox$ git commit -q -m "a pipeline: the tests, then the image"
```

### The CI server

A bare repository is a repository with no working files, which is what a server holds. Git runs
its `post-receive` hook after every push, with one line on standard input per branch that moved:
the old commit, the new one and the branch's name. Make the repository:

```
ana@vm:~/linkbox$ mkdir ~/ci
ana@vm:~/linkbox$ git init --bare ~/ci/linkbox.git
Initialized empty Git repository in /home/ana/ci/linkbox.git/
```

Save the hook as `~/ci/linkbox.git/hooks/post-receive`:

```sh
#!/usr/bin/env bash
# The CI server: for every branch pushed here, a clean clone of the pushed
# commit, and that commit's own ci/pipeline.sh. What it prints reaches
# whoever pushed, each line prefixed with "remote:". Every run keeps its
# checkout and its logs in ~/ci/runs/N.
set -uo pipefail
repo=$(pwd)
unset GIT_DIR
while read -r old new ref; do
  [ "$new" = 0000000000000000000000000000000000000000 ] && continue
  mkdir -p ~/ci/runs
  n=$(( $(ls ~/ci/runs | wc -l) + 1 ))
  run=~/ci/runs/$n
  git clone -q "$repo" "$run/src"
  git -C "$run/src" checkout -q "$new"
  echo "run $n: ${ref#refs/heads/} at ${new:0:7}"
  if CI_COMMIT=${new:0:7} CI_BRANCH=${ref#refs/heads/} CI_LOGS=$run/logs \
      "$run/src/ci/pipeline.sh"; then
    echo "run $n: passed"
  else
    echo "run $n: failed, the logs are in ~/ci/runs/$n/logs"
  fi
done
```

Git runs a hook only if it is executable, and says so in a hint when it is not, which the last
section of this lesson shows. Make it executable, and give your repository the server as a remote called
`ci`:

```
ana@vm:~/linkbox$ chmod +x ~/ci/linkbox.git/hooks/post-receive
ana@vm:~/linkbox$ git remote add ci ~/ci/linkbox.git
```

### The first run

Push, and the run prints as it goes, each line prefixed with `remote:` because it comes from the
server:

```
ana@vm:~/linkbox$ git push ci main
remote: run 1: main at 85988f7        
remote: test: passed in 1s        
remote: build: passed in 26s        
remote: pipeline passed        
remote: run 1: passed        
To /home/ana/ci/linkbox.git
 * [new branch]      main -> main
```

Everything the run did stays in `~/ci/runs/1`: the checkout and one log per stage.

```
ana@vm:~/linkbox$ ls ~/ci/runs/1
logs
src
ana@vm:~/linkbox$ ls ~/ci/runs/1/logs
build.log
test.log
ana@vm:~/linkbox$ cat ~/ci/runs/1/logs/test.log
...                                                                      [100%]
3 passed in 0.36s
```

The image is in Docker, named for the commit:

```
ana@vm:~/linkbox$ docker images linkbox
IMAGE             ID             DISK USAGE   CONTENT SIZE   EXTRA
linkbox:85988f7   70c3e9d34939       1.64GB          422MB        
```

That is the whole CI. Every later lesson adds a stage to `ci/stages` and a script beside it, and
by lesson 19 the list has eleven entries.
