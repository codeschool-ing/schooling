---
title: The same script on the laptop and on the server
version: 1
---

A pipeline that only runs on a server is debugged by pushing: change a line, push, wait, read the
log, change another line. Every round costs a full run and a commit nobody wanted in the history.
linkbox avoids that by construction, because **the pipeline is a script in the repository**, and
the server does nothing but run it. Whatever the server runs, your laptop can run too, before the
push.

That is the theory. Run it in the project you built in lesson 1:

```
ana@vm:~/linkbox$ ci/pipeline.sh
test: FAILED in 0s, the end of test.log:
  error: Failed to create virtual environment
    Caused by: A virtual environment already exists at: .venv
  
  hint: Use the `--clear` flag or set `UV_VENV_CLEAR=1` to replace the existing virtual environment
```

It failed before any test ran. The test stage makes a fresh virtual environment called `.venv`,
and **your project already has one**, from lesson 1, so `uv` refuses to replace it. On the server
the same stage passes every time, because the hook clones the commit into an empty directory for
each run. **The same script is not the same run**: the laptop carries state the server never has,
such as an old environment, a database file, a build left over from yesterday, or a change not yet
committed.

### Running it the way the server does

The server's conditions are easy to copy: a fresh clone, then the clone's own pipeline. Do the same
in a scratch directory:

```
ana@vm:~/linkbox$ rm -rf /tmp/linkbox-run && git clone -q ~/linkbox /tmp/linkbox-run && /tmp/linkbox-run/ci/pipeline.sh
test: passed in 1s
build: passed in 0s
pipeline passed
```

That is the server's run, on your machine, in about the same time. The image is tagged `dev`
because nothing set `CI_COMMIT`, which only the hook does.

**A clean clone tests what is committed, and nothing else.** That is the point of it, and also its
limit: a change you have not committed yet is not in the clone. For those, run the one fast tool
that answers the question in front of you: `.venv/bin/python -m pytest -q` for the tests, and from
lesson 3 the static analysis on its own. Leave the full run for the commit you are about to push. The pipeline is the contract; the single tools are the quick look before you sign.

### A pipeline that takes a list

This lesson gives the pipeline a second list, for the slow checks that run once a day, so the
runner needs to be told which list to read. It reads `ci/stages` by default, which is what the
hook asks for, and any other file named as its first argument. Save it as `ci/pipeline.sh`:

```sh
#!/usr/bin/env bash
# The pipeline: every stage named in a list, in order. The list is ci/stages,
# what runs on every push, unless another is given, such as ci/nightly. A
# stage is the script ci/<name>.sh, run from the repository's root. Exit 0
# passes it; anything else breaks the build, and the run stops at that stage.
# A list that is not there breaks it too, rather than passing with no stages.
set -uo pipefail
cd "$(dirname "$0")/.."
LIST=${1:-ci/stages}
[ -f "$LIST" ] || { echo "no list of stages at $LIST"; exit 1; }
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
done <"$LIST"
echo "pipeline passed"
```

Git shows the lines that changed against lesson 1's version:

```
ana@vm:~/linkbox$ git diff ci/pipeline.sh | grep '^[-+]'
--- a/ci/pipeline.sh
+++ b/ci/pipeline.sh
-# The pipeline: every stage named in ci/stages, in that order. A stage is the
-# script ci/<name>.sh, run from the repository's root. Exit 0 passes it;
-# anything else breaks the build, and the run stops at that stage.
+# The pipeline: every stage named in a list, in order. The list is ci/stages,
+# what runs on every push, unless another is given, such as ci/nightly. A
+# stage is the script ci/<name>.sh, run from the repository's root. Exit 0
+# passes it; anything else breaks the build, and the run stops at that stage.
+# A list that is not there breaks it too, rather than passing with no stages.
+LIST=${1:-ci/stages}
+[ -f "$LIST" ] || { echo "no list of stages at $LIST"; exit 1; }
-done <ci/stages
+done <"$LIST"
```

### The line that stops a silent pass

One line of the change is there for a failure you would otherwise never see. **Without it, a list
that does not exist is a pipeline that passes.** The `while` loop reads its lines from the file;
when the file is missing, bash prints a complaint, the loop runs zero times, and the script carries
on to its last line. To see it, make a copy of the runner without that line and give it a list
name with a typo:

```
ana@vm:~/linkbox$ grep -v 'no list of stages' ci/pipeline.sh > ci/unguarded.sh
ana@vm:~/linkbox$ bash ci/unguarded.sh ci/stagse; echo "exit $?"
ci/unguarded.sh: line 22: ci/stagse: No such file or directory
pipeline passed
exit 0
ana@vm:~/linkbox$ rm ci/unguarded.sh
```

**"pipeline passed", and the exit status is 0.** Nothing ran. On a laptop somebody might notice the
complaint above it; in a scheduled job that nobody watches, a typo in the list's name would report
a pass every night for as long as the schedule exists. The runner you saved refuses instead:

```
ana@vm:~/linkbox$ ci/pipeline.sh ci/stagse; echo "exit $?"
no list of stages at ci/stagse
exit 1
```

A check that did not run is not a check that passed. Lesson 7 makes that a rule for every stage,
and this is the first place the course needs it.
