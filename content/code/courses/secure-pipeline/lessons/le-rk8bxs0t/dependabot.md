---
title: Dependabot, configured in the repository
version: 1
---

**Dependabot is GitHub's dependency bot, and its whole configuration is one file in the repository,
`.github/dependabot.yml`.** It has two jobs that are easy to confuse. *Security updates* open a pull
request when GitHub's advisory database names a version your repository uses, and they are switched
on in the repository's settings. *Version updates* open pull requests for every newer release, on a
schedule, and they are what the file configures. This section is taught from GitHub's
documentation: Dependabot runs on GitHub's servers against a GitHub repository, and **it was not
run** for this course. What was run is the check every workflow file in linkbox already goes
through, because the configuration of a program that opens pull requests in your name deserves the
same review as a workflow.

### The file from the documentation

The shortest file the documentation shows asks for weekly version updates of the Python
dependencies, and nothing else:

```yaml
version: 2
updates:
  - package-ecosystem: pip
    directory: /
    schedule:
      interval: weekly
```

Write it to `.github/dependabot.yml` for a moment, and give it to zizmor, the checker lesson 16 put
in the pipeline:

@@CAPTURE dependabot-first@@

zizmor reads a Dependabot file as well as workflows, and it has an audit for exactly this file:
**`dependabot-cooldown`**. With no `cooldown` block, Dependabot proposes a release the moment it is
published, and the finding says the implicit default is under seven days. The exit status is not 0,
so in the pipeline this file would break the `workflows` stage. The reason for the audit is the
subject of lesson 12: several of the incidents placed there were releases that were malicious for
hours or days before anybody noticed and removed them, and a bot with no waiting period carries such
a release into a pull request within the hour.

### The file linkbox keeps

Save it as `.github/dependabot.yml`:

```yaml
# Version updates for linkbox: which dependencies GitHub's Dependabot keeps
# current, when it may open a pull request, and how long a release must have
# been public before it is proposed. Security updates do not wait for any of
# this; they come when an advisory does.
version: 2
updates:
  - package-ecosystem: pip
    directory: /
    schedule:
      interval: weekly
      day: monday
      time: "06:00"
      timezone: America/Sao_Paulo
    cooldown:
      default-days: 14
      semver-major-days: 30
    groups:
      python:
        update-types: [minor, patch]
    open-pull-requests-limit: 3
  - package-ecosystem: docker
    directory: /
    schedule:
      interval: weekly
      day: monday
    cooldown:
      default-days: 14
  - package-ecosystem: github-actions
    directory: /
    schedule:
      interval: weekly
      day: monday
    cooldown:
      default-days: 14
    groups:
      actions:
        patterns: ["*"]
```

Each block is one **ecosystem** in one directory. Three of them cover what linkbox pins: the Python
requirements, the two base images that lesson 15 named by digest in the `Dockerfile`, and the
actions that lesson 16 pinned by commit in the workflow. The documentation says Dependabot updates a
digest pin to the new digest and a commit pin to the new commit, keeping the version comment beside
it, which is the shape lesson 16 asked for.

The rest of each block decides how often a person is interrupted:

- `schedule` puts every version update on Monday morning, so the week's proposals arrive
  together rather than one an hour.
- `cooldown` waits fourteen days after a release before proposing it, and thirty for a new major
  version, the kind that is allowed to break things. The documentation says the cooldown applies to
  version updates only: a security update is proposed as soon as the advisory is known, which is
  the right trade, because then the risk is in waiting.
- `groups` puts every minor and patch update of the Python dependencies into one pull request,
  and every action update into another. A major version still gets a pull request of its own, since
  it is the one somebody has to read the changelog for.
- `open-pull-requests-limit` stops Dependabot opening a fourth pull request while three are
  still open. Proposals that do not fit wait for the next week.

zizmor has no finding now:

@@CAPTURE dependabot-pass@@

Commit it and push, and the pipeline runs zizmor over it on the CI server the same way:

@@CAPTURE dependabot-push@@

### One thing the documentation does not settle for linkbox

Dependabot's pip support reads requirements files, and its documentation lists files compiled by
`pip-compile` among them: it then edits the `.in` file and compiles the lock again, hashes included.
linkbox's lock was compiled by `uv pip compile`, which writes a header of its own. Whether
Dependabot recompiles that file or edits it like a plain list of pins is something this course
**could not check**, because checking it needs a repository on GitHub. Before relying on it,
open one Dependabot pull request on a test repository and look at the diff of `requirements.txt`:
every version it changes should come with new hashes. The fix-on-a-branch section of this lesson
shows what the pipeline does with a change that moves a version and keeps the old hashes.
