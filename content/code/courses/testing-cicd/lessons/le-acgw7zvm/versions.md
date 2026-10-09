---
title: The version is written once
version: 2
---

A running program should be able to say what it is. When something goes wrong in production, the
first question is **which code is running**, and the answer has to come from the program, not from
somebody's memory of the last deploy. `shipquote` answers on `/version`, and the answer comes from a
single place: the git tag.

This is the rule the repository that publishes this course follows, and its `CLAUDE.md` puts it in
one line: *the tag is the one place a version is written*. Not a file to keep in step with the tag,
not a constant in the code; the build reads the tag and stamps it into the artifact.

```
ana@laptop:~/shipquote$ tar -xzOf dist/shipquote-1.4.0.tar.gz shipquote-1.4.0/shipquote/VERSION; echo
1.4.0
ana@laptop:~/shipquote$ python3 -c 'from shipquote.version import VERSION; print(VERSION)'
dev
```

The artifact carries a file, `shipquote/VERSION`, holding `1.4.0`, and nothing else. In the working
copy that file does not exist, so `shipquote.version` falls back to `dev`. **A program that nobody
built says it is `dev`**, never a guess, which is exactly what you want to see in a log line from
someone's laptop.

## A build that is not a release

What happens to a commit with no tag? Here a change is committed on a throwaway branch and built.
The branch is `git switch -c try-a-change`, the change one empty line, `echo >> README.md`, and the
commit `git commit -qam "Try a change"`:

```
ana@laptop:~/shipquote$ git describe --tags
v1.4.0-1-g7c77050
ana@laptop:~/shipquote$ ops/build.sh
dist/shipquote-dev-7c77050.tar.gz
```

`git describe` says the commit is **one past `v1.4.0`**, with the hash `7c77050`. The build calls it
`dev-7c77050`: a name that cannot be mistaken for a release and that still says exactly which commit
it is. During an incident, "dev-7c77050" is an answer; "1.4.0, probably with Ana's fix" is not.
Throw the branch and its build away afterwards: `git switch main`, `git branch -D try-a-change` and
`rm dist/shipquote-dev-*`.

## Semantic versions

`1.4.0` follows **semantic versioning**: MAJOR.MINOR.PATCH. A patch release fixes something without
changing behaviour anybody relies on; a minor release adds something and breaks nothing; a major
release may break callers. The numbers are a promise to whoever depends on the program, which for a
service is mostly its own clients and for a library is everybody who imports it.

Two habits from this repository's release workflow are worth copying. The tag is checked before
anything is built: it must have the right shape, be **higher than every release before it**, and be
on `main`, because a release nobody merged cannot be reproduced from `main`. And after the build, the
workflow **asks the binary what version it is** and compares the answer with the tag, so a stamping
mistake fails the release instead of reaching users.
