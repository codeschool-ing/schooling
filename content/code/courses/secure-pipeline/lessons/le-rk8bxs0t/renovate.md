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

@@CAPTURE node@@

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

@@CAPTURE renovate-commit@@

### What it finds on main

Run it against `main`, with a report written to a file:

@@CAPTURE renovate-main@@

The log says it found two requirements files with 13 dependencies between them, and the report
says none is outdated. That is what lesson 15 should leave: the lock was compiled with
`--exclude-newer 2026-10-16`, and nothing newer than that date had been released when this was
recorded. Your run will differ, because the indexes move every day; that is the point of running a
bot every week.

### A lock compiled a month earlier

To see Renovate propose something, the repository needs a lock that is behind. A branch can make
one honestly: compile the same `.in` files with an earlier date, as somebody would have on
20 September.

@@CAPTURE stale@@

Four packages resolve to older versions on that date, and every other pin stays the same. Now run
Renovate on the branch, and ask the report for every dependency that has an update:

@@CAPTURE renovate-stale@@

Each line is a pull request Renovate would open on a real platform, with the version it would move
to. **`waiting: true` is the cooldown at work**: pluggy 1.7.0 was published on 15 October, eight days
before this recording, and `minimumReleaseAge` holds it back until it is fourteen days old. The
others have been public longer and would be proposed now. The last command matters as much as the
report: `git status` prints nothing, because the `local` platform changes no file and opens nothing.

What Renovate does on a hosted platform with the same report is in its documentation and was not
run here. It opens a branch and a pull request per update or per group, and keeps a "dependency
dashboard" issue listing what it found and what it is holding back. It rebases its branches when the
base moves, and it merges its own pull requests when a rule allows it, the subject of the section
after next. Notice one thing in the report that matters before any of that: Renovate
reported the files it reads as `requirements.txt` and `requirements-dev.txt`. It proposes changes to
the lock, not to `requirements.in`. The next section shows why a change to a hashed lock is only
correct if whoever makes it compiles the lock again.
