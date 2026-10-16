---
title: Following one change back to its author
version: 1
---

**The test of an audit trail is a question asked backwards**: something is running in production;
who decided that, and why? Each record of this lesson answers one step of it, and each answer is the
key for the next.

Start from the cluster. Production runs an image:

```
ana@laptop:~/fleet$ IMAGE=$(kubectl -n production get deployment bulletin -o jsonpath='{.spec.template.spec.containers[0].image}'); echo $IMAGE
localhost:5001/bulletin@sha256:6f1995760d8af84d7fa903a2e0e479a1720ba5e21ed18a81019f318d8a0dbcb1
ana@laptop:~/fleet$ REV=$(docker buildx imagetools inspect $IMAGE --format '{{json .Provenance.SLSA}}' | jq -r '.buildDefinition.externalParameters.request.root.request.args["vcs:revision"]'); echo $REV
eeb36366262959f88c6fc5eecb28bdfc97c04060
ana@laptop:~/fleet$ git -C ~/bulletin log -1 --format='%h %an %s' $REV
eeb3636 Ana Lima Show the pod that answered
ana@laptop:~/fleet$ C=$(git log --format=%h -S ${IMAGE#*@} -- apps/bulletin/production | tail -n 1); git log -1 --format='%h %an %s' $C
de2e8c5 Ana Lima artefacts: production by digest, the published chart, image automation
ana@laptop:~/fleet$ git log --merges --ancestry-path --format='%h %s' $C..main | tail -n 1
9d2bf03 Merge pull request 'artefacts: production by digest, the published chart, image automation' (#9) from artefacts into main
```

Four answers in a row. The Deployment names a digest. The image's provenance names the commit of
`bulletin` it was built from, `eeb3636`, *Show the pod that answered*. In `fleet`, `git log -S`
finds the commit that put that digest into production's directory, and the first merge after it on
the way to `main` is the pull request that approved it: number 9, from lesson 7.

**Four hops, four systems, no guess at any of them**, and none needed anybody's memory. That is what
the course has been building towards since lesson 1: a deployment is not something a person did, it
is a commit somebody approved, and every system in between kept a record pointing at the next.

The hop that would break the chain is a change made outside it. A `kubectl set image` in production
leaves the cluster running something no commit names, and the trace above would end at the
deployment with nothing behind it. Flux undoes that change on its next pass, and the API server's
audit log is where the person who made it is found.
