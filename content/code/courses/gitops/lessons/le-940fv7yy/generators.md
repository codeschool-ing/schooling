---
title: Generated ConfigMaps, and why the hash is the point
version: 1
---

**A ConfigMap that pods read at start has a well-known trap**: change the ConfigMap, and the pods
keep the old values until something restarts them. Nothing in Kubernetes connects the two, so the
change is applied, the cluster is in sync, and the application runs with the old configuration
until the next unrelated rollout.

`configMapGenerator` closes that gap. Kustomize builds the ConfigMap from the literals, names it
`bulletin-` plus a hash of its contents, and rewrites every reference to `bulletin` in the overlay
to the hashed name. **A different message is a different hash, a different name, a different pod
template**, and so a rollout, with nothing anybody has to remember.

```
ana@laptop:~/fleet$ git switch --quiet -c staging-message
ana@laptop:~/fleet$ git diff | grep '^[-+] '
-  - MESSAGE=Staging is updated by a webhook.
+  - MESSAGE=Staging is built by Kustomize.
ana@laptop:~/fleet$ kubectl -n staging get configmaps
NAME                  DATA   AGE
bulletin-t55m2kmd94   1      13s
kube-root-ca.crt      1      2m9s
ana@laptop:~/fleet$ git commit --quiet -am "staging: built by Kustomize"
ana@laptop:~/fleet$ kubectl -n staging get configmaps
NAME                  DATA   AGE
bulletin-bgc7c2mm85   1      5s
kube-root-ca.crt      1      2m19s
ana@laptop:~/fleet$ curl -s localhost:8080
bulletin 1.1
message: Staging is built by Kustomize.
pod: bulletin-57cd9f8cc5-mdcwt
token: none
```

The pull request changed one literal in `apps/bulletin/staging/kustomization.yaml`. Flux applied a
new ConfigMap with a new suffix, the Deployment pointing at it, and the pods rolled; the old
ConfigMap was pruned on the same pass, because no file describes it any more. The page shows the
new message from a new pod.

The same mechanism works for a `secretGenerator`, with the same caution as everywhere else in this
course: **its literals would be in Git in clear text**. Lessons 9 and 10 put secrets into the
cluster other ways.
