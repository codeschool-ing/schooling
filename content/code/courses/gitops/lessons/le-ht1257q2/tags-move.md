---
title: A tag is a name somebody can move
version: 1
---

**Nothing in an OCI registry stops a tag from pointing somewhere else tomorrow.** Pushing an image
with an existing tag replaces the pointer, and the registry does not keep the old one. The common
habit of tagging `latest`, or `stable`, makes that the normal way of working:

```
ana@laptop:~$ docker tag localhost:5001/bulletin:1.0 localhost:5001/bulletin:stable && docker push --quiet localhost:5001/bulletin:stable
localhost:5001/bulletin:stable
ana@laptop:~$ curl -sI -H "$INDEX" localhost:5001/v2/bulletin/manifests/stable | grep -i docker-content-digest
Docker-Content-Digest: sha256:be9af139f25f6af2b686d6822eda8d332495500580cb43d28a762bd0d57bb986
ana@laptop:~$ docker tag localhost:5001/bulletin:1.1 localhost:5001/bulletin:stable && docker push --quiet localhost:5001/bulletin:stable
localhost:5001/bulletin:stable
ana@laptop:~$ curl -sI -H "$INDEX" localhost:5001/v2/bulletin/manifests/stable | grep -i docker-content-digest
Docker-Content-Digest: sha256:0a8edf25732e8b60073fb97de9e9f93b1634730f19bce0b5725bc9526f818366
```

`stable` meant 1.0 at the first push and 1.1 at the second, and the digest it resolves to changed
with it. **Nothing about the name says which one you will get**, and a manifest in Git that says
`bulletin:stable` describes a different cluster depending on when a node happens to pull. Two pods
of one Deployment, started an hour apart, can run different code under the same reference.

Version tags like `1.1` are not immune. They are conventions, and the registry would accept a second
push of `1.1` just as it accepted the second `stable`. Three things stand against that, from the
weakest to the strongest:

- **a team rule**: nobody pushes a version tag twice. Necessary, and only as strong as the CI that
  enforces it;
- **tag immutability in the registry**: Harbor, the cloud registries, Artifactory and Nexus can
  refuse a push to a tag that exists. The reference registry of this course cannot;
- **a digest in Git**: the reference cannot be moved, by anybody, because it is the content's own
  hash. The next section pins production that way.

The `stable` tag stays where the experiment left it, on 1.1. Deleting things from a registry is the
subject of the section on retention, and it is not as harmless as it looks.
