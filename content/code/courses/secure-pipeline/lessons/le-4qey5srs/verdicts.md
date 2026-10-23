---
title: Break, warn, pass: three exit statuses
version: 1
---

Until now a stage had two answers: exit 0 and the run goes on, anything else and it stops. That is
a gate with no way to warn, and it forces every stage to choose between breaking on noise and
hiding a real finding behind a pass. Lesson 4's dynamic scan made the second choice: `-I` told ZAP
to exit 0 on warnings, so its warnings reached nobody. **A third answer is needed, and the
pipeline has to count it and show it**, or a warning is a pass with extra words.

### The pipeline, with a warning

The exit status is still the verdict: 0 passes, 3 passes with a warning, and anything else breaks
the build. A warning prints the end of the stage's log, like a failure, and the last line counts
them, so a run with warnings never looks like a clean one. The check lesson 2 added stays: a list
that is not there breaks the run rather than passing with no stages. Save it as `ci/pipeline.sh`:

```sh
#!/usr/bin/env bash
# The pipeline: every stage named in a list, in order. The list is ci/stages,
# what runs on every push, unless another is given, such as ci/nightly. A
# stage is the script ci/<name>.sh, run from the repository's root, and its
# exit status is its verdict: 0 passes, 3 passes with a warning that is
# counted and shown, and anything else breaks the build and stops the run.
# A list that is not there breaks it too, rather than passing with no stages.
set -uo pipefail
cd "$(dirname "$0")/.."
LIST=${1:-ci/stages}
[ -f "$LIST" ] || { echo "no list of stages at $LIST"; exit 1; }
LOGS=${CI_LOGS:-ci-logs}
mkdir -p "$LOGS"
warnings=0
while read -r stage; do
  case $stage in '' | '#'*) continue ;; esac
  start=$SECONDS
  bash "ci/$stage.sh" >"$LOGS/$stage.log" 2>&1
  status=$?
  took=$((SECONDS - start))
  if [ "$status" -eq 0 ]; then
    echo "$stage: passed in ${took}s"
  elif [ "$status" -eq 3 ]; then
    warnings=$((warnings + 1))
    echo "$stage: WARNING in ${took}s, the end of $stage.log:"
    tail -n 8 "$LOGS/$stage.log" | sed 's/^/  /'
  else
    echo "$stage: FAILED in ${took}s, the end of $stage.log:"
    tail -n 15 "$LOGS/$stage.log" | sed 's/^/  /'
    exit 1
  fi
done <"$LIST"
echo "pipeline passed with $warnings warning(s)"
```

### Why 3

A warning needs a number that no failure produces by accident, because the pipeline reads the
number and nothing else. 1 is what almost every program exits with when it fails, including a
Python program that crashes. 2 is taken twice over: Python exits 2 when it is called with an
option it does not know, and ZAP's baseline scan exits 2 when it has warnings. 127 is the shell
saying a command does not exist:

```
ana@vm:~/linkbox$ python3 -m json.tool --no-such-option 2>/dev/null; echo "exit $?"
exit 2
ana@vm:~/linkbox$ no-such-scanner 2>/dev/null; echo "exit $?"
exit 127
```

**Had a warning been 2, a stage whose program was called with a typo in a flag would have passed
with a warning**, and a run that checked nothing would have gone on. 3 is not free in the wider
world; gunicorn exited 3 in lesson 6 when its worker failed to boot. Within these stages it comes
only from a line that says `exit 3` on purpose or from the gate below, which is the property that
matters. Every status the pipeline does not recognise breaks the build, so a program that fails in
a way nobody expected fails closed.

### Static analysis: what breaks and what warns

Save it as `ci/sast.sh`:

```sh
# Static analysis. A finding of medium severity or worse breaks the build,
# and a low one is a warning.
set -uo pipefail
semgrep scan --metrics=off --quiet --error --config .semgrep.yml . || exit 1
bandit -q -r . -c bandit.yaml --severity-level medium || exit 1
bandit -q -r . -c bandit.yaml --severity-level low || exit 3
```

Semgrep runs only the two rules lesson 3 wrote for this project, each for a defect linkbox has
actually had, so a finding of either breaks the build. Bandit's built-in rules are broader, and
their severity is the line between the two verdicts: medium or high breaks, low warns. That is a
judgement about Bandit's rules, not a law. Its low findings are mostly the kind lesson 3 met in
B105, a string that looks like a password and needs a person to read it, and a person reading it
is what a warning asks for.

**Every command carries its own `|| exit`**, so the verdict for each one is written beside it.
`set -e` knows one kind of failure and would turn all of them into the same status, which is what
this lesson is undoing.

### Dynamic analysis: ZAP's own verdicts

ZAP's baseline scan already has three answers: 0 for nothing, 2 for warnings and 1 for a rule set
to FAIL, plus 3 when the scan itself could not finish. The new version stops hiding the warnings,
drops `-I`, and translates. Save it as `ci/dast.sh`:

```sh
# Dynamic analysis: the image this run built, started on a network of its
# own, and ZAP's baseline scan against it from a second container. The scan
# only looks: it reads what the application answers and sends it nothing
# meant to break it. ZAP's own exit status is the verdict: a rule set to FAIL
# in ci/zap-rules.conf breaks the build, a WARN is a warning, and a scan that
# could not finish breaks the build too.
set -uo pipefail
net=linkbox-staging-$$
docker network create "$net" >/dev/null
trap 'docker rm -f "$net-app" >/dev/null 2>&1; docker network rm "$net" >/dev/null' EXIT
docker run -d --rm --name "$net-app" --network "$net" \
  -e LINKBOX_TOKEN="$(head -c 18 /dev/urandom | base64)" "linkbox:${CI_COMMIT:-dev}" >/dev/null
sleep 2
docker run --rm --network "$net" -v "$PWD/ci:/zap/wrk:ro" zaproxy/zap-stable:2.17.0 \
  zap-baseline.py -t "http://$net-app:8000" -c zap-rules.conf -z -silent
case $? in
  0) exit 0 ;;
  2) exit 3 ;;
  *) exit 1 ;;
esac
```

The `case` maps 2 to the pipeline's 3, keeps 0, and sends **everything else to 1**: a FAIL rule,
a scan that crashed, a container that never started. `set -e` is gone from this script, because with
it, ZAP's 2 would have stopped the script before the `case`
could read it.

| stage | breaks the build (1) | warns (3) | passes (0) |
|---|---|---|---|
| `secrets` | any finding not recorded as dead | never | nothing found |
| `sast` | a Semgrep finding, a Bandit finding of medium or worse | a Bandit finding of low severity | nothing found |
| `sca` | an advisory with a fix and no exception | an advisory with no fix; an exception in its last week | nothing to report |
| `dast` | a FAIL rule, or a scan that could not finish | a WARN rule | nothing found |

The `sca` row is the one that needs a program to decide, and it is the next section.
