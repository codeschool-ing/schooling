---
title: Production, pinned by digest
version: 1
---

**A digest in the manifest makes the cluster run exactly the bytes that were tested**, whatever
happens to the tags afterwards. Kustomize's `images` field takes a digest in place of a tag. Here is
the `images` entry of `apps/bulletin/production/kustomization.yaml` after the change, with the
digest that `curl` returned for `1.1` earlier in this lesson:

```
ana@laptop:~/fleet$ git switch --quiet -c production-digest
ana@laptop:~/fleet$ git diff | grep '^[-+] '
-  newTag: "1.1"
+  digest: sha256:0a8edf25732e8b60073fb97de9e9f93b1634730f19bce0b5725bc9526f818366
ana@laptop:~/fleet$ git commit --quiet -am "production: bulletin 1.1, by digest"
ana@laptop:~/fleet$ kubectl -n production get deployment bulletin -o jsonpath='{.spec.template.spec.containers[0].image}'; echo
localhost:5001/bulletin@sha256:0a8edf25732e8b60073fb97de9e9f93b1634730f19bce0b5725bc9526f818366
ana@laptop:~/fleet$ kubectl -n production get pods -o jsonpath='{.items[0].status.containerStatuses[0].imageID}'; echo
localhost:5001/bulletin@sha256:0a8edf25732e8b60073fb97de9e9f93b1634730f19bce0b5725bc9526f818366
```

Kubernetes resolves nothing: the node pulls by digest, and the pod's spec names the digest. The
running container's `imageID` is the same digest, which is the confirmation that what runs is what
Git says, byte for byte.

**The price is readability.** `sha256:…` tells a reviewer nothing about which release it is, so the
pull request's title and body have to say, and a comment beside the digest helps. Some teams keep
both, `bulletin:1.1@sha256:…`, which Kubernetes accepts and resolves by the digest alone; the tag is
then a label for people and nothing else. A rule that works well: **tags in staging, where a
release is being tried, and digests in production, where it is being kept.**
