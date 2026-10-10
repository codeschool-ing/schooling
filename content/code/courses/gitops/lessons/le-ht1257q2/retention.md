---
title: What to keep, and for how long
version: 1
---

**A registry that keeps everything grows for ever**, and one that deletes too eagerly breaks
rollbacks. Every image a CI builds, one per commit on some teams, is a few megabytes to a few
hundred, and most are never deployed. Retention is the policy that decides what goes, and it has one
rule that GitOps adds: **anything that a commit in the configuration repository references is still
a possible rollback**, and must not be deleted while that commit might be reverted to.

Policies usually combine three kinds of rule:

- **keep releases**: tags that look like versions, `1.1`, are kept, for a long time or for ever;
- **expire the rest**: tags from branches and builds, and untagged manifests, are deleted after a few
  days or weeks;
- **keep what runs**: anything currently deployed, or referenced by the last N commits of the
  configuration repository, is kept whatever its tag.

The cloud registries and Harbor, Artifactory and Nexus all express rules like these as a setting. The
reference registry this course runs has none: it deletes what it is asked to and decides nothing.
**The deletion is the easy half.** The hard half is the list of what must be kept, and in a GitOps
setup that list is in Git, readable by a script:

```
ana@laptop:~/fleet$ for overlay in apps/*/*/; do kubectl kustomize $overlay; done | grep 'image:' | sort -u
        image: localhost:5001/bulletin
        image: localhost:5001/bulletin:1.2
        image: localhost:5001/bulletin@sha256:0a8edf25732e8b60073fb97de9e9f93b1634730f19bce0b5725bc9526f818366
```

Every image reference that `main` of `fleet` uses, across every overlay, in one command; the line
with no tag is the base, which no environment runs as it is. One reference is missing, and it is the kind a script forgets: the preview runs `bulletin:1.1` from the chart's
values, which only `helm template` would show, because Kustomize sees a HelmRelease and nothing
inside it. Going further back through `git log` gives the references of every revision a revert
could return to.

What a retention policy removes most is a build that was pushed and never deployed. Here is one, a
test build of a version nobody released, deleted by the digest its tag points at:

```
ana@laptop:~/bulletin$ docker build --quiet --build-arg VERSION=1.3-test -t localhost:5001/bulletin:1.3-test . && docker push --quiet localhost:5001/bulletin:1.3-test
sha256:6aceab20a700e7dddd4a6a6f9280ad8fdb01a09e4d72db6305ded6c6f322d55c
localhost:5001/bulletin:1.3-test
ana@laptop:~/bulletin$ TEST=$(curl -sI -H "$INDEX" localhost:5001/v2/bulletin/manifests/1.3-test | grep -i docker-content-digest | cut -d" " -f2 | tr -d "\r")
ana@laptop:~/bulletin$ curl -s -o /dev/null -w "%{http_code}\n" -X DELETE localhost:5001/v2/bulletin/manifests/$TEST
202
ana@laptop:~/bulletin$ curl -s localhost:5001/v2/bulletin/tags/list
{"name":"bulletin","tags":["1.0","1.1","1.2","stable"]}
```

`202`, accepted, and the tag went with the manifest it named. No space is freed yet: the layers stay
on disk until `registry garbage-collect` runs while nothing is being pushed. And **the registry asked
nothing**. The same request with the digest production runs would have been accepted just as
quietly; production would carry on from the copy on its node, until the first pod that had to pull
it. That is why the list above is the input to any deletion, and never an afterthought.
