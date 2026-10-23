---
title: The smallest move that clears the list, and the stage that keeps it clear
version: 1
---

Every finding has a fixed version, so the fix is an upgrade. The question is how far. "Upgrade
everything to the latest" is the move people reach for, and on a real service it is a large
change: new major versions, removed features, a review nobody can do in an afternoon. **The minimal
move is each flagged package to the lowest version that fixes all its advisories, and then only
what those new versions require.** It is the smallest change that makes the audit pass, so it is
the easiest to review and the least likely to break something nobody tested.

Lesson 15 weighs the larger choices, updating, pinning and replacing, for the long run. This
section clears the list.

### The target versions

For each package, the highest fixed version in its rows is the one that clears them all:

| package | pinned | fixed versions in the audit | move to |
|---|---|---|---|
| flask | 3.0.0 | 3.1.3 | 3.1.3 |
| werkzeug | 3.0.1 | 3.0.3, 3.0.6, 3.1.4, 3.1.5, 3.1.6, 3.1.9 | 3.1.9 |
| jinja2 | 3.1.2 | 3.1.3, 3.1.4, 3.1.5, 3.1.6 | 3.1.6 |
| gunicorn | 21.2.0 | 22.0.0 | 22.0.0 |

Change those four lines, and before installing anything, read what the new Flask asks for. PyPI
publishes every release's requirements in the same JSON that carried its advisories:

@@CAPTURE move@@

**Two of the pins no longer fit.** Flask 3.1.3 asks for `itsdangerous` 2.2.0 or later, and the
file pins 2.1.2; it asks for `blinker` 1.9.0 or later, and the file pins 1.7.0. Install the file as
it stands and uv refuses it, naming the first contradiction it meets. That is the "then only what
the new versions require" half of the move, and it is why a file of pinned transitive versions
cannot be edited one line at a time without checking what each new version asks for. The
`importlib-metadata` line applies only to Python older than 3.10, which the marker after the `;`
says, so it asks nothing of linkbox's 3.13. MarkupSafe, Click and the new Werkzeug's own
requirement are already satisfied, so those lines stay as they are.

The file at the end of the move, as `requirements.txt`:

```
flask==3.1.3
werkzeug==3.1.9
jinja2==3.1.6
markupsafe==2.1.3
itsdangerous==2.2.0
click==8.1.7
blinker==1.9.0
gunicorn==22.0.0
```

### Proving nothing broke

The diff is the whole change, six lines. Then the same environment, the tests, and the audit again:

@@CAPTURE moved@@

Five tests pass on Flask 3.1 and Werkzeug 3.1, and the audit of the service's dependencies is
clean. **A move without the test run is a guess**, and on a project with no tests the minimal move
is the only defensible one, because it is the one with the least to go wrong. gunicorn stays on
22.0.0 for now; lesson 15 takes it to 26, a decision that needs its changelog read.

### The stage

The audit belongs in the pipeline, on every push: it takes seconds, and a known-vulnerable
dependency should stop before an image is built from it. Save the stage as `ci/sca.sh`:

```sh
# Composition analysis: every dependency the two requirements files pin,
# against the advisories PyPI publishes. A dependency with a known
# vulnerability breaks the build, and so does one pip-audit could not check.
set -euo pipefail
pip-audit --strict -r requirements.txt -r requirements-dev.txt
```

Two choices in it. **Both files are audited**, the service's and the tests', for the reason the
first section of this lesson gave. And **`--strict` fails the audit if pip-audit could not collect
a dependency**: without it, a package it could not resolve is skipped with a warning and the stage
passes, which turns "could not check" into "checked and found nothing".

The stage goes after static analysis and before the build, as `ci/stages`:

```
test
sast
sca
build
```

### The first run fails, on purpose

Commit the moved requirements and the stage, and push:

@@CAPTURE pipeline@@

The service's dependencies are clean, and the build still breaks: **pytest 8.4.2 has an advisory**,
fixed in 9.0.3. It was in the first lesson's pins all along; nobody had audited the second file
before. Read the advisory before deciding anything:

@@CAPTURE pytest-desc@@

The condition is another local user on the same machine. That is no concern inside linkbox's
image, which does not contain pytest. It is a concern on a CI machine that runs jobs for more than
one project or person, which is exactly where pytest does run, beside the pipeline's credentials.

The move is the same: the lowest fixed version. Save it as `requirements-dev.txt`:

```
pytest==9.0.3
```

pytest 9 is a major version, so the tests run before the commit, not after:

@@CAPTURE dev@@

Run 2 passes: tests, static analysis, composition analysis and the build. From here on every push
is audited against what PyPI knows that day, which means **a push that changes nothing can fail
tomorrow**, when an advisory is published for a version already pinned. That is the stage doing
its job, and it is also the first thing that makes teams switch a stage off. Lesson 7 decides what
the gate does with a finding that has no fix, or one nobody can fix today.
