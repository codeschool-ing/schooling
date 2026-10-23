---
title: Renovate, run on your own machine
version: 1
---

**Renovate does the same job as Dependabot, and it runs anywhere.** It is an open-source program,
published on npm, that a hosted service runs for GitHub, GitLab, Bitbucket and others, and that you
can also run yourself. One of its platforms is `local`: it reads the repository in the current
directory, asks the package indexes what is newer, and **reports what it would propose without
writing anything**. That makes it the one dependency bot you can watch at work on your own machine,
and this section does.

### Node.js, for one program

Renovate is a Node.js program, and the version used here asks for Node 24. Node publishes its
releases with a checksum file, the same pattern lesson 1 used for uv. Download it into your home
directory and put it first on the path for this terminal:

```
ana@vm:~/linkbox$ curl -fsSLO https://nodejs.org/dist/v24.21.0/node-v24.21.0-linux-x64.tar.xz
ana@vm:~/linkbox$ curl -fsSL https://nodejs.org/dist/v24.21.0/SHASUMS256.txt | grep " node-v24.21.0-linux-x64.tar.xz$" | sha256sum --check
node-v24.21.0-linux-x64.tar.xz: OK
ana@vm:~/linkbox$ tar -xJf node-v24.21.0-linux-x64.tar.xz -C ~/.local && rm node-v24.21.0-linux-x64.tar.xz
ana@vm:~/linkbox$ export PATH=~/.local/node-v24.21.0-linux-x64/bin:$PATH
ana@vm:~/linkbox$ node --version
v24.21.0
```

`npx` comes with Node. It downloads a package and runs it, so `npx --yes renovate@44.164.10` runs
that exact version without installing anything globally. The version is pinned for the reason
lesson 15 pinned everything else: Renovate publishes several releases a day, and a lesson that ran
`renovate@latest` would run a different program every time it was read.

### The configuration

Renovate reads `renovate.json` at the root of the repository. linkbox's says the same things as the
Dependabot file, in Renovate's words. Save it as `renovate.json`:

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:recommended"],
  "timezone": "America/Sao_Paulo",
  "schedule": ["before 6am on monday"],
  "minimumReleaseAge": "14 days",
  "prConcurrentLimit": 3,
  "packageRules": [
    {
      "matchManagers": ["pip_requirements"],
      "matchUpdateTypes": ["minor", "patch"],
      "groupName": "python minor and patch"
    }
  ]
}
```

`config:recommended` is Renovate's preset of sensible defaults. **`minimumReleaseAge`** is
Renovate's name for the cooldown: a release younger than fourteen days is found and held back.
`schedule` and `prConcurrentLimit` match Dependabot's schedule and limit, and the package rule groups
the Python minor and patch updates into one pull request. zizmor has no audit for this file, so the
pipeline's `workflows` stage does not read it; the `$schema` line lets an editor check it as you
type. Commit it:

```
ana@vm:~/linkbox$ git add renovate.json
ana@vm:~/linkbox$ git commit -q -m "renovate: the same rules, for running it anywhere"
10:15AM INF 0 commits scanned.
10:15AM INF scanned ~413 bytes (413 bytes) in 220ms
10:15AM INF no leaks found
```

### What it finds on main

Run it against `main`, with a report written to a file:

```
ana@vm:~/linkbox$ npx --yes renovate@44.164.10 --platform=local --report-type=file --report-path=/tmp/report.json 2>&1 | grep -v "^npm "
 INFO: Renovate started
       "renovateVersion": "44.164.10"
 INFO: Repository started (repository=local)
       "renovateVersion": "44.164.10"
 INFO: Dependency extraction complete (repository=local, baseBranch=)
       "stats": {
         "managers": {
           "dockerfile": {"fileCount": 1, "depCount": 2},
           "github-actions": {"fileCount": 1, "depCount": 3},
           "pip_requirements": {"fileCount": 2, "depCount": 13}
         },
         "total": {"fileCount": 4, "depCount": 18}
       }
 WARN: GitHub token is required for some dependencies (repository=local)
       "githubDeps": ["actions/checkout", "astral-sh/setup-uv"]
(node:1115) MetadataLookupWarning: received unexpected error = All promises were rejected code = 403, ENOTFOUND
(Use `node --trace-warnings ...` to show where the warning was created)
 INFO: Repository finished (repository=local)
       "cloned": undefined,
       "durationMs": 9571,
       "result": undefined,
       "status": undefined,
       "enabled": undefined,
       "onboarded": undefined,
       "exitCode": undefined
 INFO: Renovate was run at log level "info". Set LOG_LEVEL=debug in environment variables to see extended debug logs.
ana@vm:~/linkbox$ jq -c .repositories.local.libYearsWithStatus.dependencyStatus /tmp/report.json
{"outdated":2,"total":18}
ana@vm:~/linkbox$ jq -c '.repositories.local.packageFiles[][] | .packageFile as $file | .deps[] | select(.updates | length > 0) | {$file, dep: .depName, to: (.updates[0].newVersion // .updates[0].newDigest), waiting: (.updates[0].pendingChecks // false)}' /tmp/report.json
{"file":"Dockerfile","dep":"python","to":"3.15","waiting":true}
{"file":".github/workflows/ci.yml","dep":"ubuntu","to":"26.04","waiting":true}
```

Renovate found more than the Python lock: four files and 18 dependencies, the 13 pins of the two
requirements files, the two base images in the `Dockerfile` and three entries in lesson 16's
workflow. **None of the 13 Python pins is outdated**, which is what lesson 15 should leave: the lock
was compiled with `--exclude-newer 2026-10-16`. The two it would update are elsewhere: the `python`
base image, from 3.13 to 3.15, and the `ubuntu` runner the workflow names, to 26.04. Both say
`waiting: true`, so `minimumReleaseAge` is holding them back, and both are the kind of change no
rule should merge alone: a new Python under every line of linkbox, and a new operating system under
every job.

Two lines of the log are about what it could not do. The `WARN` says two actions could not be looked
up without a GitHub token; on a hosted platform Renovate has one, and on your machine you would give
it one only for that. The `MetadataLookupWarning` comes from a library inside Renovate that looks for
a cloud provider's metadata service, finds none on a laptop, and changes nothing. Your run will
differ from this one in its numbers, because the indexes move every day; that is the point of running
a bot every week.

### A lock compiled a month earlier

To see Renovate propose something, the repository needs a lock that is behind. A branch can make
one honestly: compile the same `.in` files with an earlier date, as somebody would have on
20 September.

```
ana@vm:~/linkbox$ git switch -c stale-lock
Switched to a new branch 'stale-lock'
ana@vm:~/linkbox$ uv pip compile -q requirements.in --generate-hashes --exclude-newer 2026-09-20 -o requirements.txt
ana@vm:~/linkbox$ uv pip compile -q requirements-dev.in --generate-hashes --exclude-newer 2026-09-20 -o requirements-dev.txt
ana@vm:~/linkbox$ git diff --stat
 requirements-dev.txt |  14 +--
 requirements.txt     | 250 +++++++++++++++++++--------------------------------
 2 files changed, 101 insertions(+), 163 deletions(-)
ana@vm:~/linkbox$ git commit -q -am "the lock as it was compiled on 20 September"
10:17AM INF 0 commits scanned.
10:17AM INF scanned ~8350 bytes (8.35 KB) in 191ms
10:17AM INF no leaks found
```

Four packages resolve to older versions on that date, and every other pin stays the same. Now run
Renovate on the branch, and ask the report for every dependency that has an update:

```
ana@vm:~/linkbox$ npx --yes renovate@44.164.10 --platform=local --report-type=file --report-path=/tmp/report.json >/tmp/renovate.log 2>&1
ana@vm:~/linkbox$ jq -c '.repositories.local.packageFiles[][] | .packageFile as $file | .deps[] | select(.updates | length > 0) | {$file, dep: .depName, to: (.updates[0].newVersion // .updates[0].newDigest), waiting: (.updates[0].pendingChecks // false)}' /tmp/report.json
{"file":"Dockerfile","dep":"python","to":"3.15","waiting":true}
{"file":".github/workflows/ci.yml","dep":"ubuntu","to":"26.04","waiting":true}
{"file":"requirements-dev.txt","dep":"iniconfig","to":"2.3.1","waiting":false}
{"file":"requirements-dev.txt","dep":"pluggy","to":"1.7.0","waiting":true}
{"file":"requirements.txt","dep":"markupsafe","to":"3.0.4","waiting":false}
{"file":"requirements.txt","dep":"werkzeug","to":"3.1.9","waiting":false}
ana@vm:~/linkbox$ git status --short
```

Each line is a pull request Renovate would open on a real platform, with the version it would move
to. The first two are the ones `main` already had; the other four are the month-old lock. **`waiting: true` is the cooldown at work**: pluggy 1.7.0 was published on 15 October, eight days
before this recording, and `minimumReleaseAge` holds it back until it is fourteen days old. The
other three from the lock have been public longer and would be proposed now. The last command matters as much as the
report: `git status` prints nothing, because the `local` platform changes no file and opens nothing.

What Renovate does on a hosted platform with the same report is in its documentation and was not
run here. It opens a branch and a pull request per update or per group, and keeps a "dependency
dashboard" issue listing what it found and what it is holding back. It rebases its branches when the
base moves, and it merges its own pull requests when a rule allows it, the subject of the section
after next. Notice one thing in the report that matters before any of that: Renovate
reported the files it reads as `requirements.txt` and `requirements-dev.txt`. It proposes changes to
the lock, not to `requirements.in`. The next section shows why a change to a hashed lock is only
correct if whoever makes it compiles the lock again.
