---
title: The rules a build obeys, and the script that runs the scan
version: 1
---

A scanner that reports and never decides is a scanner whose output nobody has to read. **The
decision is written down per rule, in a file the build obeys**: for each rule, whether a match
breaks the build, is reported, or is dropped. ZAP's baseline reads that file with `-c`, and the
format is one rule per line, three fields separated by tabs: the rule's id, the action, and the
rule's name in parentheses, which ZAP ignores and a person reads.

| action | what a match does | when it fits |
|---|---|---|
| `FAIL` | breaks the build (exit status 1) | a real defect with a fix in your own hands, which must not come back |
| `WARN` | reported, and the build goes on | a finding that needs a person's judgement, or one you cannot fix today |
| `IGNORE` | dropped from the output | a rule that cannot apply to this service at all |
| `INFO` | reported as information only | a rule kept for the record |

A rule the file does not list keeps its default, which is WARN. `zap-baseline.py -g FILE` writes a
starting file with every rule at WARN, which is a useful list to read once and a bad file to keep:
sixty lines nobody decided are sixty lines nobody will review.

### linkbox's rules

Three of the four findings are missing headers, each fixed by one line in linkbox's own code, and
once fixed, a regression would be a real defect. Those three FAIL. The fourth, 10031, is not
listed, so it stays a WARN, and the section on the fix explains why it is not ignored either.
Save the file as `ci/zap-rules.conf`:

```
# ZAP baseline rules for linkbox: a rule id, a tab, and what a match does.
# FAIL breaks the build, WARN reports it and IGNORE drops it. A rule that is
# not listed warns.
10020	FAIL	(Anti-clickjacking Header)
10021	FAIL	(X-Content-Type-Options Header Missing)
10038	FAIL	(Content Security Policy (CSP) Header Not Set)
```

The separators are tab characters, not spaces. ZAP splits each line on tabs, and a line typed with
spaces does not parse.

### The stage

The script builds the staging of the previous sections, runs the scan in it and takes everything
down whatever happens. Save it as `ci/dast.sh`:

```sh
# Dynamic analysis: the image this run built, started on a network of its
# own, and ZAP's baseline scan against it from a second container. The scan
# only looks: it reads what the application answers and sends it nothing
# meant to break it. A rule set to FAIL in ci/zap-rules.conf breaks the build.
set -euo pipefail
net=linkbox-staging-$$
docker network create "$net" >/dev/null
trap 'docker rm -f "$net-app" >/dev/null 2>&1; docker network rm "$net" >/dev/null' EXIT
docker run -d --rm --name "$net-app" --network "$net" "linkbox:${CI_COMMIT:-dev}" >/dev/null
sleep 2
docker run --rm --network "$net" -v "$PWD/ci:/zap/wrk:ro" zaproxy/zap-stable:2.17.0 \
  zap-baseline.py -t "http://$net-app:8000" -c zap-rules.conf -I -z -silent
```

What each part is for:

- **`net=linkbox-staging-$$`.** `$$` is the shell's process id, so every run names its own
  network and its own container, `linkbox-staging-<pid>-app`, and two runs at once do not meet.
- **The `trap … EXIT`.** It runs when the script ends, by success, by failure or by `set -e`
  stopping it halfway, and it removes the container and the network. Without it, a failed scan
  would leave a running service on the machine for the next run to trip over.
- **`linkbox:${CI_COMMIT:-dev}`.** The image this run built, tagged by `ci/build.sh` with the
  same variable, so the scan reads the commit being tested and no other.
- **`sleep 2`.** gunicorn needs a moment before it answers. Two seconds is a guess that holds on
  this machine; a loop asking until the service answers would be sturdier, and longer than the rest
  of the script.
- **`-v "$PWD/ci:/zap/wrk:ro"`.** ZAP looks for `-c` files in `/zap/wrk`. The project's `ci`
  directory is mounted there read-only, so the scanner can read the rules and change nothing.
- **`-I`.** A WARN no longer makes the exit status 2. Only a FAIL, or a scan that could not
  finish, breaks the build. Lesson 7 replaces this with a third outcome, a warning the pipeline
  reports without stopping.

### The first run breaks the build

The headers are not fixed yet, so the script should fail, and **a check is only trusted after you
have watched it fail for the reason it exists**. Run it on the image of lesson 3's code, which the
build of the staging section left as `linkbox:dev`:

```
ana@vm:~/linkbox$ bash ci/dast.sh > /tmp/dast.log; echo "exit status $?"
2026-10-23 04:47:02,540 Unable to copy yaml file to /zap/wrk/zap.yaml [Errno 30] Read-only file system: '/zap/wrk/zap.yaml'
exit status 1
ana@vm:~/linkbox$ grep -v ^PASS /tmp/dast.log
Using the Automation Framework
Total of 4 URLs
WARN-NEW: User Controllable HTML Element Attribute (Potential XSS) [10031] x 1 
	http://linkbox-staging-6166-app:8000/search?q=ZAP (200 OK)
FAIL-NEW: Missing Anti-clickjacking Header [10020] x 2 
	http://linkbox-staging-6166-app:8000 (200 OK)
	http://linkbox-staging-6166-app:8000/search?q=ZAP (200 OK)
FAIL-NEW: X-Content-Type-Options Header Missing [10021] x 2 
	http://linkbox-staging-6166-app:8000 (200 OK)
	http://linkbox-staging-6166-app:8000/search?q=ZAP (200 OK)
FAIL-NEW: Content Security Policy (CSP) Header Not Set [10038] x 2 
	http://linkbox-staging-6166-app:8000 (200 OK)
	http://linkbox-staging-6166-app:8000/search?q=ZAP (200 OK)
FAIL-NEW: 3	FAIL-INPROG: 0	WARN-NEW: 1	WARN-INPROG: 0	INFO: 0	IGNORE: 0	PASS: 57
```

Exit status 1, and the three rules the file set to FAIL are now `FAIL-NEW`. 10031 is still a
`WARN-NEW`, because nothing decided otherwise. 10038 matched two responses this time against three
in the previous section, on the same image: the counts move, the verdict does not. In the
pipeline the whole output lands in `ci-logs/dast.log`, the way lesson 1's runner keeps every
stage's log.

The line about `zap.yaml` is ZAP trying to save the plan it generated for the run into
`/zap/wrk`. The directory is mounted read-only on purpose, so the save fails, ZAP says so on its
error output, and the scan carries on. It appears on every run of this stage, and it is the
read-only mount doing its job.

This is the state a team is in on the day a new check arrives: it is red, and it is right. The fix
is the next section, and it comes with a test, because the scan alone would only tell you about a
regression the next time it runs.
